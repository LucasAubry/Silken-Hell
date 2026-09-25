local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=false
 local json=require 'json'
 local stats=json.encode(Profile.stats);local scores=#Profile.scores
 local data={version=1,build='old-build',world=1,seed=123,width=960,height=600,skin=1,startLevel=1,single=false,hardcore=false,completed=true,frames=12,deaths=2,time=.2,layouts={},inputs={{12,0,0,0}},checks={{4,2,30000,30000,1,false},{8,2,32000,30000,2,false},{12,2,32000,30000,2,true}}}
 for _,version in ipairs({1,2,999}) do
  data.version=version;assert(Replay.validate(data));assert(Replay.play(data) and Replay.compatibility)
  for i=1,12 do
   Replay.update(Replay.step,function()
    if Replay.frame==1 then App.state='victory' end
   end)
   if i==4 then assert(player.level==2 and player.x==300 and App.state=='playing','Old route restored after early victory') end
   if i==8 then assert(player.x==320 and player.death==2,'Recorded checkpoint restored') end
  end
  assert(not Replay.playing and not Replay.compatibility and Replay.status=='Lecture terminée.','Cross-version playback finishes')
 end
 assert(json.encode(Profile.stats)==stats and #Profile.scores==scores,'Spectating leaves progress unchanged')
 data.version=1;data.build=Replay.build();assert(Replay.play(data) and not Replay.compatibility)
 for _=1,4 do Replay.update(Replay.step,function() end) end
 assert(not Replay.playing and Replay.status:find('différente'),'Current-build corruption is still detected')
 data.build='legacy';data.inputs={{1,0,0,0}};assert(not Replay.validate(data),'Version tolerance does not accept incomplete inputs')
 data.inputs={{12,0,0,0}};data.checks[1][3]='invalid';assert(not Replay.validate(data),'Malformed checkpoints remain rejected')
 print('PASS replay compatibility: old and future version labels, different build, checkpoint recovery, early victory, completion, spectator isolation, strict current build, malformed data rejection')
 love.event.quit(0)
end
return T
