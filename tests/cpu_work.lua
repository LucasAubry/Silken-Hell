-- Count avoidable work without timing thresholds or rendering changes.
local T={}
local function copy(source)
 local result={};for key,value in pairs(source) do result[key]=value end;return result
end
local function restore(target,saved)
 for key in pairs(target) do target[key]=nil end
 for key,value in pairs(saved) do target[key]=value end
end
function T.run()
 local N=require('achievement_notice')
 local saved={profile=copy(Profile),app=copy(App),replay=copy(Replay),notice=copy(N),
  hardcore=Hardcore.completed,player=player,move=Input.move,slow=Input.slow,
  audio=Audio.play,unlocked=Achievements.unlocked,random=love.math.random,mathRandom=math.random}
 local ok,err=xpcall(function()
  Profile.achievements={};Profile.completed={};Profile.storyTexts={}
  Profile.skinGrants={};Profile.topRecords={};Profile.scores={}
  for i=1,1000 do Profile.scores[i]={world=1,deaths=1,hardcore=false} end
  Hardcore.completed={};Replay.playing=false;App.state='menu';App.preview=false;App.sessionLayout=nil
  Audio.play=function()end
  local unlockCalls=0
  Achievements.unlocked=function(a)unlockCalls=unlockCalls+1;return saved.unlocked(a)end
  N.init();unlockCalls=0
  for _=1,240 do N.update(.001) end
  assert(unlockCalls==#Achievements.list,'240 unchanged updates need only one fallback scan')
  assert(not N.active and #N.queue==0,'Existing achievements remain silent')
  local function clearNotice()N.active=nil;N.queue={}end
  local function expect(id)
   local before=unlockCalls
   N.update(.001)
   assert(unlockCalls==before+#Achievements.list,'Progress mutation must rescan immediately: '..id)
   assert(N.active and N.active.entry.id==id and #N.queue==0,'One immediate notice for '..id)
   before=unlockCalls;N.update(.001)
   assert(unlockCalls==before and #N.queue==0,'Unchanged progress must not repeat '..id)
   clearNotice()
  end
  Profile.achievements.gillou=true;expect('gillou')
  Profile.achievements.gillou=nil;N.update(.001)
  assert(not N.active and not N.seen.gillou,'Direct removals update the baseline')
  Profile.achievements={maxance=true};expect('maxance')
  Profile.completed[2]=true;expect('world2')
  Profile.storyTexts['1']=true;expect('story_first')
  Profile.topRecords[1]={world=6};expect('top1')
  Hardcore.completed['5']=true;expect('hardcore')
  Profile.skinGrants.heartbreak=true
  local beforeGrant=unlockCalls;N.update(.001)
  assert(unlockCalls==beforeGrant+#Achievements.list,'A direct grant mutation invalidates the dependency snapshot')
  assert(not N.active and #N.queue==0 and require('skin_effects').unlocked('heartbreak'),
   'An effect grant does not award its separate achievement')
  Profile.achievements.heartbreak=true;expect('heartbreak')
  Profile.scores[#Profile.scores+1]={world=6,deaths=1};expect('world6')
  Profile.scores={{world=5,deaths=1}};expect('world5')
  Profile.scores[1].world=4
  assert(Achievements.unlocked({id='world4',world=4}),'The public unlock API stays immediate for deep edits')
  N.update(.001);assert(not N.active,'Deep history edits use the bounded fallback')
  N.update(.2)
  assert(N.active and N.active.entry.id=='world4','Deep score edits are observed within 0.2 seconds')
  clearNotice();Profile.scores[1].world=7;N.invalidate();expect('world7')
  for _,mode in ipairs({'replay','preview','layout'}) do
   Replay.playing=mode=='replay';App.preview=mode=='preview';App.sessionLayout=mode=='layout' and {} or nil
   Profile.achievements.gillou=true
   local before=unlockCalls;N.update(.3)
   assert(unlockCalls==before and not N.active and #N.queue==0,'Excluded context stays silent: '..mode)
   Profile.achievements.gillou=nil;Replay.playing=false;App.preview=false;App.sessionLayout=nil;N.update(.001)
   assert(not N.active and #N.queue==0,'Temporary progress must not leak from '..mode)
  end

  local R=Replay
  local checkpoint=saved.replay.checkpoint
  local checkpointCalls,checkpointFrames=0,{}
  R.checkpoint=function()
   checkpointCalls=checkpointCalls+1;checkpointFrames[#checkpointFrames+1]=R.frame
   return checkpoint()
  end
  -- Isolate serialization from the real fixed-step recorder under test.
  R.saveFinished=function()R.recording=false;R.pendingFinish=nil end
  R.endPlayback=function()R.playing=false;R.status='Lecture terminée.'end
  R.stop=function(message)R.playing=false;R.status=message end
  R.afterFrame=function()return false end
  Input.move=function()if R.input then return R.input[1],R.input[2]end;return 1,0 end
  Input.slow=function()return false end
  local function reset(playback,data)
   player={level=1,x=0,y=0,death=0};App.state='playing'
   R.disabled=false;R.ghost=nil;R.job=nil;R.compatibility=false;R.paused=false;R.speed=1
   R.playing=playback;R.recording=not playback;R.pendingFinish=nil;R.pendingScore=nil
   R.accumulator=0;R.frame=0;R.eventIndex=1;R.eventLeft=0;R.checkIndex=1;R.input=nil;R.status=''
   R.rng=love.math.newRandomGenerator(12345)
   R.data=data or {inputs={},checks={},frames=0}
   checkpointCalls=0;checkpointFrames={}
  end
  local function tick(dt)
   local x,y=Input.move()
   player.x=player.x+x*dt*60;player.y=player.y+y*dt*60+love.math.random(1,5)*.01
   if R.frame==600 then App.state='customVictory';if not R.playing then R.finish()end end
  end
  reset(false)
  for _=1,600 do R.update(1/60,tick) end
  assert(checkpointCalls==3 and table.concat(checkpointFrames,',')=='240,480,600',
   'Recording must build only the three retained checkpoints')
  local data=R.data
  assert(#data.inputs==1 and data.inputs[1][1]==600,'Input compression remains unchanged')
  for i,frame in ipairs({240,480,600}) do
   local c=data.checks[i]
   assert(c[1]==frame and c[2]==1 and c[3]==frame*100 and c[5]==0 and c[6]==(frame==600),
    'Stored checkpoint fields remain unchanged')
  end
  assert(love.math.random==saved.random and math.random==saved.mathRandom,'Recording restores RNG functions')
  reset(true,data)
  local iterations=0
  while R.playing and iterations<600 do R.update(1/37,tick);iterations=iterations+1 end
  assert(R.status=='Lecture terminée.' and R.frame==600,'Playback remains deterministic at another update rate')
  assert(checkpointCalls==3 and table.concat(checkpointFrames,',')=='240,480,600',
   'Playback compares only recorded checkpoints')
  assert(love.math.random==saved.random and math.random==saved.mathRandom,'Playback restores RNG functions')
  local json=require('json');local tampered=json.decode(json.encode(data));tampered.inputs[1][2]=0
  reset(true,tampered);iterations=0
  while R.playing and iterations<600 do R.update(1/37,tick);iterations=iterations+1 end
  assert(R.status:find('différente') and R.frame==240 and checkpointCalls==1,
   'Tampered input still fails at the first stored checkpoint')
 end,debug.traceback)
 restore(Profile,saved.profile);restore(App,saved.app);restore(Replay,saved.replay);restore(N,saved.notice)
 Hardcore.completed=saved.hardcore;player=saved.player;Input.move=saved.move;Input.slow=saved.slow
 Audio.play=saved.audio;Achievements.unlocked=saved.unlocked
 love.math.random=saved.random;math.random=saved.mathRandom
 assert(ok,err)
 print('PASS CPU work: bounded achievement scans, immediate progress notices, deep-edit fallback, retained replay checkpoints and deterministic playback')
end
return T
