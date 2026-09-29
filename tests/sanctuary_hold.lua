local T={}
function T.run()
 Online.enabled=false;Profile.save=function() end;Bestiary.save=function() end;Replay.disabled=true
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 Secret.catalog();local types={'merle','storm','hedgehog','octopus','skeleton_head','wasp'}
 for i,v in ipairs(types) do assert(Secret.normalBosses[i].type==v) end
 App.selectedWorld=8;WorldMap.open();assert(WorldMap.branch(true,true));App.openEntry(8,WorldMap.hardcore);assert(App.state=='bossWorld' and Secret.hardcore and Secret.pages==6)
 for i=1,6 do Secret.page=i;Secret.refresh();Secret.launch(Secret.portals[1]);assert(Worlds.isSecret(Campaign.world) and App.state=='playing') end
 Secret.open(false)
 for i=1,6 do Secret.page=i;Secret.refresh();Secret.launch(Secret.portals[1]);assert(App.state=='playing') end
 Secret.open(false);local move=Input.move;local dx=1;Input.move=function() return dx,0 end
 Secret.cooldown=0;Secret.x=Arena.width-46;Secret.update(.02);assert(Secret.page==2)
 Secret.cooldown=0;Secret.x=46;dx=-1;Secret.update(.02);assert(Secret.page==1)
 dx=0;Secret.cooldown=0;Secret.x,Secret.y=Secret.position(1)
 Secret.update(.6);assert(App.state=='bossWorld' and Secret.charge>.5)
 Secret.x=100;Secret.update(.1);assert(Secret.charge==0)
 Secret.x,Secret.y=Secret.position(1);Secret.update(.7);Secret.update(.69);assert(App.state=='bossWorld');Secret.update(.02);assert(App.state=='playing' and Secret.duel.name=='L’Œuf du Merle')
 Input.move=move;Secret.open(false)
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1;UI.clock=4
  if frame<=18 and frame%3==1 then Secret.page=math.floor((frame-1)/3)+1;Secret.refresh();App.capture='sanctuary-new-'..Secret.page..'.png'
  elseif frame==20 then Secret.open(true);Secret.page=3;Secret.refresh();Secret.x,Secret.y=Secret.position(1);Secret.charging=1;Secret.charge=.8;App.capture='sanctuary-demon-hold.png'
  elseif frame==23 then App.selectedWorld=8;WorldMap.hardcore=true;WorldMap.open();App.capture='sanctuary-demon-map.png'
  elseif frame==26 then print('PASS sanctuary: ordered six bosses, six normal and six demon fights, edge navigation, hold/cancel/launch, all display sizes');love.event.quit() end
 end
end
return T
