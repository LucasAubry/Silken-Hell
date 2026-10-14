local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=false
 local json=require 'json'
 local data={version=1,build=string.rep('a',64),world=1,seed=123,width=960,height=600,skin=1,startLevel=7,single=true,hardcore=false,completed=true,frames=12,deaths=2,time=.2,layouts={},inputs={{12,0,0,0}},checks={{12,7,32000,30000,2,true}}}
 local before=App.state;local stats=json.encode(Profile.stats)
 assert(Replay.play(data) and Replay.recovery,'Unknown builds start automatic restoration')
 Replay.key('escape');assert(not Replay.playing and not Replay.recovery,'Restoration can be cancelled')
 for _,version in ipairs({2,999}) do
  data.version=version;assert(Replay.validate(data));assert(not Replay.play(data))
  assert(not Replay.playing and Replay.status:find('Format'),'Unknown data formats cannot be interpreted')
 end
 data.version=1;data.build=Replay.build();assert(Replay.play(data))
 -- Regression for the actual crash log: starting at level 7 leaves holes in starts.
 Campaign.starts[1]={[1]=1,[7]=2};Replay.levelStates={}
 Replay.beforeLevelReset();assert(Replay.levelStates[7].starts[1][7],'Sparse level starts are copied without JSON')
 local random,mathRandom=love.math.random,math.random
 Replay.update(Replay.step,function() error('Injected replay failure') end)
 assert(not Replay.playing and App.state~='playing' and Replay.status:find('interrompue'),'Playback errors return to the menu')
 assert(love.math.random==random and math.random==mathRandom and not Replay.entered,'Failure restores both RNG functions')
 assert(love.filesystem.read('replay-error.log'):find('Injected replay failure'),'Diagnostic retains the original error')
 assert(json.encode(Profile.stats)==stats,'Spectator failure does not alter progress')
 assert(Replay.play(data));for _=1,12 do Replay.update(Replay.step,function()end) end
 assert(not Replay.playing and Replay.status:find('différente'),'Current-build corruption is detected')
 data.inputs={{1,0,0,0}};assert(not Replay.validate(data));data.inputs={{12,0,0,0}}
 data.session=true;assert(not Replay.validate(data),'Missing session map rejected')
 print('PASS replay safety: historical restoration and cancellation, unknown format rejected, sparse level starts, protected playback errors, diagnostic, RNG restoration, progress isolation and malformed recording rejection')
 love.event.quit()
end
return T
