local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 Input.move=function()return 0,0 end;Input.speedHeld=function()return false end
 Profile.completed={};Profile.levels={};Profile.transitionsSeen={}
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Profile.levels[w]=10 end
 App.preview=false;App.hardcore=false;App.practice=nil;App.singleLevel=false;App.sessionLayout=nil;Secret.duel=nil
 local C=require('run_start')
 App.start(1);C.arrival=nil;C.arrivalKind=nil;C.active=false
 timer=12;player.death=3;RunDetails.lastDeaths=3
 local data=Replay.data
 App.restartLevel();Replay.update(Replay.step,App.simulate)
 assert(player.death==4 and timer>12,'Level restart retains time and adds one death')
 assert(Replay.data==data and not App.practice and not App.singleLevel,'Same campaign and recording')
 assert(data.inputs[#data.inputs][5]==1,'Restart is recorded')
 assert(not require('retry_wait').active,'Timer continues after manual retry')
 -- Playback input follows the same path, without a UI request.
 Replay.enter();Replay.input={0,0,false,true};App.simulate(Replay.step);Replay.leave()
 assert(player.death==5 and timer>12,'Recorded restart also counts a death')
 App.restartWorld();assert(player.death==0 and timer==0 and player.level==1,'Biome restart clears counters')
 assert(C.active and not C.arrival and not C.scene(),'Biome restart waits for Space without an entrance')
 for _,world in ipairs({1,6,5,4,7,2,3}) do
  for _,seen in ipairs({false,true}) do
   Profile.transitionsSeen[tostring(world)]=seen
   App.practice=nil;App.singleLevel=false;App.start(world)
   timer=42;player.death=7;App.restartWorld()
   assert(not C.arrival and not C.scene() and not C.rememberTransition,'Neither full nor short entrance on biome retry')
   assert(timer==0 and player.death==0 and player.level==1 and C.active,'Fresh biome counters and Space gate')
   App.state='pause';App.restartCurrent()
   assert(not C.arrival and C.active,'Pause-menu retry also skips entrance')
  end
 end
 App.practice=3;App.singleLevel=true;App.start(5);App.restartWorld()
 assert(App.practice==1 and not C.arrival and C.active,'Training biome retry skips the portal too')
 App.practice=nil;App.singleLevel=false;Profile.transitionsSeen['2']=nil
 Secret.launch({kind='boss',name='Test',world=5})
 assert(C.active and not C.countdown and not C.arrival,'Sanctuary waits without countdown')
 for i=1,100 do assert(C.advance(.05)==0) end
 assert(timer==0 and C.press(Profile.keys.dash),'Space starts sanctuary')
 local order=require('campaign_order')
 local a,b={level=1},{level=3};local obj={hellOrder=1,levels={['2:1']=a,['2:3']=b}}
 order.migrate(obj);assert(obj.levels['2:1']==b and b.level==1 and obj.levels['2:3']==a and a.level==3)
 order.migrate(obj);assert(obj.levels['2:1']==b,'Migration only once')
 Secret.duel=nil;App.practice=nil;App.singleLevel=false
 App.start(2)
 local layout=LevelLayouts.current();local original=require('json').decode(love.filesystem.read('custom_levels.json'))
 assert(#layout.entities==#original.levels['2:3'].entities,'New Hell level 1 is former level 3')
 local scene=C.scene();scene.advance(scene.duration)
 local scale,x,y=App.viewport(love.graphics.getDimensions());local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
 local px,py=scene.position(scene.duration,love.graphics.getWidth(),love.graphics.getHeight(),sx,sy)
 assert(math.abs(px-sx)<.01 and math.abs(py-sy)<.01,'Transition lands on new spawn')
 print('PASS restart counters, replay input, sanctuary Space gate and Hell level order/arrival');love.event.quit()
end
return T
