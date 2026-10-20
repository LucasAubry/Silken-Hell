local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end
 Replay.disabled=true;Replay.playing=false;App.singleLevel=true;App.practice=1;App.sessionLayout=nil;Secret.duel=nil
 Campaign.select(3);player.level=1;reset_level();mobs={};Renaissance.reset()
 assert(Renaissance.active and #mobs==1 and mobs[1].type=='white_spider','Only the friendly follower remains in the legacy encounter')
 for i=1,200 do Renaissance.update(.05) end
 assert(#mobs==1,'No removed vegetation respawns')
 for _,name in ipairs({'bush','mini_bush','walking_tree','soil'}) do
  assert(not love.filesystem.getInfo('assets/monstres/renaissance/vegetation/'..name..'.png'),'Removed vegetation asset '..name)
  assert(not Art.images['rebirth_'..name],'Removed vegetation is not preloaded')
 end
 local e=Renaissance.eggs[1];player.x=e.x;player.y=e.y;Renaissance.collect();assert(Renaissance.remaining==1)
 e=Renaissance.eggs[2];player.x=e.x;player.y=e.y;assert(Renaissance.collect() and Renaissance.remaining==0)
 Renaissance.reset();assert(Renaissance.remaining==2)
 Campaign.select(1);Renaissance.reset();assert(not Renaissance.active)
 print('PASS Renaissance: removed vegetation code and assets, no respawns, retained follower and eggs')
 love.event.quit()
end
return T
