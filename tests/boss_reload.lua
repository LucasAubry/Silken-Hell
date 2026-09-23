local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false;Replay.data=nil
 App.hardcore=false;App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;Secret.duel=nil
 LevelLayouts.disabled=true;Campaign.select(4);player.level=10;reset_level();App.state='playing';player.reset=false
 -- Simulate unavailable source reads after startup. Reload every boss type,
 -- then execute the failing death/reset path through Replay.update itself.
 local load=love.filesystem.load
 love.filesystem.load=function(path) error('Unexpected source reread: '..path) end
 local before={};for k,v in pairs(MobBehaviors) do before[k]=v end
 for _,kind in ipairs({'merle','wasp','hedgehog','octopus','storm','skeleton_fish','skeleton_head'}) do
  for _=1,3 do
   Bosses.load({{type=kind,x=400,y=300},{type=kind,x=650,y=300}},{},{})
   local a,b=Bosses.items[1].boss,Bosses.items[2].boss
   assert(a~=b,'Boss instances remain independent')
   local hp=b.hp;a.hp=-77;assert(b.hp==hp,'State is not shared')
  end
 end
 for k,v in pairs(before) do assert(MobBehaviors[k]==v,'Actor handlers restored') end
 App.sessionLayout={world=4,level=10,width=960,height=600,entities={{kind='spawn',x=70,y=500},{kind='boss',type='octopus',x=480,y=300},{kind='tear',x=800,y=100}}}
 LevelLayouts.disabled=false;reset_level()
 Replay.disabled=false;Replay.recording=true;Replay.playing=false;Replay.accumulator=0;Replay.frame=0
 Replay.rng=love.math.newRandomGenerator(123)
 Replay.data={inputs={},checks={},frames=0,layouts={['4:10']=App.sessionLayout}}
 local originalRandom=love.math.random
 for i=1,20 do
  Replay.update(Replay.step,function() reset_level();assert(#Bosses.items==1 and Bosses.items[1].boss.active) end)
  assert(love.math.random==originalRandom,'Replay restores RNG after reload')
 end
 Replay.recording=false;Replay.disabled=true;Replay.data=nil;love.filesystem.load=load
 print('PASS all boss constructors, independent duplicate instances, actor handlers, twenty replay level reloads with source loading disabled')
 love.event.quit(0)
end
return T
