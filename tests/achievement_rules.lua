local T={}
function T.run()
 local profile={};for key,value in pairs(Profile) do profile[key]=value end
 local files={};local read,write=love.filesystem.read,love.filesystem.write
 local app,replay,secret,completed=App,Replay,Secret,Hardcore.completed
 love.filesystem.read=function(name)return files[name]end
 love.filesystem.write=function(name,data)files[name]=data;return true end
 App={};Replay={playing=false};Secret={};Hardcore.completed={}
 local ok,err=xpcall(function()
  local json=require('json');local effects=require('skin_effects')
  local entries={};local trophyCount,worldCount=0,0
  assert(#Achievements.list==15,'Exactly fifteen achievements remain')
  for _,entry in ipairs(Achievements.list) do
   assert(not entries[entry.id],'Unique achievement ID');entries[entry.id]=entry
   assert(not entry.id:match('^flawless%d+$') and not entry.id:match('^top1_') and entry.id~='bossflawless1','Retired achievements stay out of the gallery')
   if entry.world then worldCount=worldCount+1;assert(entry.rewardSkin==Worlds.rank(entry.world)+5)end
   if entry.trophy then trophyCount=trophyCount+1;assert(not entry.rewardEffect)
   else assert(entry.rewardSkin or entry.rewardEffect,'Each achievement displays its reward or an authored trophy')end
  end
  assert(worldCount==7 and trophyCount==3)
  assert(entries.gillou.name=='3 piques d’un coup' and entries.gillou.rewardSkin==13)
  assert(entries.maxance.name=='C’est dur ?' and entries.maxance.rewardSkin==14)
  assert(entries.heartbreak.name=='Une triste fin' and entries.heartbreak.rewardEffect=='heartbreak')
  assert(entries.hardcore.rewardEffect=='hardcore' and entries.top1.rewardEffect=='gold')
  assert(not entries.story_first and entries.worlds_all.trophy=='story_first' and entries.story_all.trophy=='story_all' and entries.flawless_all.trophy=='flawless_all')
  assert(entries.flawless_all.rewardSkin==23,'The flawless trophy also awards the Cocon skin')
  assert(#Characters.keys==26 and Characters.names[14]=='Maxance' and Characters.names[23]=='Cocon')
  assert(Characters.baseCount==18 and #Characters.baseIndices==18)
  for position,index in ipairs(Characters.baseIndices)do
   assert(index==(position>=15 and position+8 or position),'The selection excludes legacy variants without renumbering them')
  end

  local flags={};Profile.achievements=flags;Profile.scores={};Profile.completed={};Profile.skinGrants={};Profile.topRecords={}
  assert(not Characters.unlocked(23),'Cocon starts locked')
  Profile.skinGrants['23']=true;assert(not Characters.unlocked(23),'Cocon requires the achievement itself');Profile.skinGrants={}
  for i=#Worlds.order,2,-1 do
   Achievements.check({world=Worlds.order[i],deaths=0,hardcore=i%2==0},flags)
   assert(not Achievements.unlocked(entries.flawless_all),'Every one of the seven worlds is required')
   assert(not Characters.unlocked(23),'Partial flawless progress cannot unlock the skin')
  end
  Achievements.check({world=Worlds.order[1],deaths=1},flags)
  assert(not Achievements.unlocked(entries.flawless_all),'A run with one death does not complete the challenge')
  Achievements.check({world=Worlds.order[1],deaths=0},flags)
  assert(flags.flawless_all and Achievements.unlocked(entries.flawless_all),'Separate flawless runs combine regardless of order or mode')
  assert(Characters.unlocked(23) and Characters.select(23) and Characters.selected()==23)
  for index=24,26 do Characters.cycle(1);assert(Characters.menuIndex()==index and Profile.character==index) end
  Characters.cycle(1);assert(Characters.menuIndex()==1 and Profile.character==1)
  for index=26,23,-1 do Characters.cycle(-1);assert(Characters.menuIndex()==index and Profile.character==index) end
  Characters.cycle(-1);assert(Characters.menuIndex()==14 and Profile.character==23,'Browsing a locked skin never equips it')
  Characters.cycle(1);assert(Characters.menuIndex()==23,'Cycle proceeds directly from Maxance to Cocon')
  assert(not flags.bossflawless1,'Completing Paradise no longer awards Coquille parfaite')
  Achievements.finishLevel();assert(not flags.bossflawless1)
  local excluded={};Achievements.check({world=8,deaths=0},excluded);Achievements.check({world=9,deaths=0},excluded)
  assert(not next(excluded),'Sanctuary and former secret bosses do not count as whole flawless worlds')
  flags={};Achievements.check({world=1,deaths=94},flags);assert(not flags.maxance)
  Achievements.check({world=1,deaths=95},flags);assert(flags.maxance and not flags.gillou)

  -- Neither replays nor practice/preview modes can create new progress.
  Profile.achievements={};Profile.scores={}
  for _,key in ipairs({'preview','sessionLayout','workshopMap','practice','singleLevel'})do
   App[key]=true;assert(not Achievements.canEarn());assert(not Achievements.award('gillou'))
   Profile.complete(1,100,0,true);assert(#Profile.scores==0);App[key]=nil
  end
  Replay.playing=true;assert(not Achievements.canEarn());Replay.playing=false
  Secret.duel=true;assert(not Achievements.canEarn());Secret.duel=nil
  assert(Achievements.canEarn())

  -- A pre-existing profile with per-world flags gains the one combined trophy.
  local legacy={'statsVersion=1','progressVersion=2','bossflawless1=1','achievementGillou=2','achievementMaxance=2','heartbreak=1'}
  for _,world in ipairs(Worlds.order)do legacy[#legacy+1]='flawless'..world..'=1'end
  files={['profile.txt']=table.concat(legacy,'\n')};Profile.load()
  assert(Profile.achievements.flawless_all and Achievements.unlocked(entries.flawless_all))
  assert(Characters.unlocked(23),'Historical per-world progress unlocks Cocon')
  assert(Profile.achievements.gillou and Profile.achievements.maxance and Profile.achievements.heartbreak)
  assert(Profile.achievements.bossflawless1,'Existing boss-stat evidence survives migration')
  Profile.save();Profile.load();assert(Profile.achievements.flawless_all and Profile.achievements.flawless3)

  -- Old normal and hardcore score files also reconstruct complete progress.
  local normal,hard={},{}
  for i,world in ipairs(Worlds.order)do
   if i%2==0 then hard[#hard+1]={world=world,name='QA',country='FR',time=100,deaths=0,skin=1}
   else normal[#normal+1]=string.format('%d\tQA\tFR\t100.000\t0\t1\t',world)end
  end
  files={['profile.txt']='statsVersion=1\nprogressVersion=2',['scores.tsv']=table.concat(normal,'\n'),['hardcore-scores.json']=json.encode(hard)}
  Hardcore.completed={};Profile.load()
  assert(Achievements.unlocked(entries.flawless_all) and Profile.achievements.hardcore)
  assert(Characters.unlocked(23),'Historical score progress unlocks Cocon')
  assert(Achievements.unlocked(entries.hardcore) and effects.unlocked('hardcore'),'Hardcore score history recovers the halo even without hardcore.json')
  assert(not Achievements.unlocked(entries.world6),'A hardcore record does not change normal-world progression')
  Profile.save();Profile.load();assert(Profile.achievements.flawless_all and effects.unlocked('hardcore'))
  Profile.achievements={flawless_all=true};Profile.scores={};Profile.completed={};Hardcore.completed={}
  assert(Characters.unlocked(23),'An existing explicit unlock is enough, including temporary all-unlocked profiles')

  files={['profile.txt']='statsVersion=1\nprogressVersion=2\ntop1_6=1\ntop1_5=0'};Profile.load()
  assert(Profile.achievements.top1 and Achievements.unlocked(entries.top1) and effects.unlocked('gold'),'Legacy first-place flags become a single achievement and effect')
  Profile.save();Profile.load();assert(Profile.achievements.top1)
  Profile.achievements={};Profile.scores={};Profile.completed={};Profile.topRecords={};Hardcore.completed={}
  assert(not Achievements.unlocked(entries.top1) and not Achievements.unlocked(entries.hardcore))
  Profile.topRecords={{world=6,hardcore=true}};assert(Achievements.unlocked(entries.top1) and effects.unlocked('gold'))
  Profile.topRecords={{world=1,hardcore=false}};assert(Achievements.unlocked(entries.top1))
  Hardcore.completed['5']=true;assert(Achievements.unlocked(entries.hardcore) and effects.unlocked('hardcore'))
  Hardcore.completed={};Profile.completed[9]=true;assert(Achievements.unlocked(entries.hardcore),'Legacy hardcore boss completions retain the halo')

  Profile.storyTexts={};assert(not Achievements.unlocked(entries.story_all))
  Profile.storyTexts['1']=true;assert(not Achievements.unlocked(entries.story_all))
  Profile.completed={};Profile.scores={};Profile.achievements={story_first=true};Hardcore.completed={}
  assert(not Achievements.unlocked(entries.worlds_all),'The retired first-word flag cannot grant the all-worlds trophy')
  for i,world in ipairs(Worlds.order) do
   Profile.completed[world]=true
   assert(Achievements.unlocked(entries.worlds_all)==(i==#Worlds.order),'Every world is required')
  end
  Profile.save();Profile.load();assert(Achievements.unlocked(entries.worlds_all),'Existing completed-world progress persists')
  for _,world in ipairs(Worlds.order)do Profile.storyTexts[tostring(world)]=true end
  assert(Achievements.unlocked(entries.story_all))
 end,debug.traceback)
 love.filesystem.read,love.filesystem.write=read,write
 App,Replay,Secret,Hardcore.completed=app,replay,secret,completed
 for key in pairs(Profile)do Profile[key]=nil end
 for key,value in pairs(profile)do Profile[key]=value end
 assert(ok,err)
 print('PASS fifteen achievements, combined flawless runs, reward rules, excluded practice and replay, legacy profile/score migration and persistence')
end

-- This rule test also runs without a window: lua tests/achievement_rules.lua.
if ...==nil then
 package.path='src/?.lua;'..package.path
 love={filesystem={read=function(path)local f=io.open(path,'rb');if not f then return end;local data=f:read('*a');f:close();return data end,write=function()error('Tests must not write real save files')end}}
 Worlds=require('worlds');Achievements=require('achievements');Profile=require('profile')
 Characters=require('characters');Hardcore=require('hardcore');RunDetails=require('run_details')
 App={};Replay={playing=false};Secret={}
 T.run()
end
return T
