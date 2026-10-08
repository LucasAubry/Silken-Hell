local T={}
function T.run()
 io.stdout:setvbuf('no')
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.singleLevel=true;App.practice=2;App.start(1);player.reset=false;player.abyssGrace=0
 local chase,follow=move_mob_towards_player,move_when_player_moves
 for _,kind in ipairs({'ange','snake'}) do
  mobs={};spawn_piege(300,300)
  if kind=='ange' then spawn_ange(100,100,1) else spawn_snake(100,100,1) end
  local m=mobs[2];m.has_larme=true;objet.larme_dropped=false;player.x=285;player.y=288;player.reset=false
  local deaths=player.death
  local function ontoTrap(actor) actor.x=300;actor.y=300 end
  move_mob_towards_player=ontoTrap;move_when_player_moves=ontoTrap
  MobBehaviors[kind].update(m,.016)
  assert(m.is_frozen and mobs[1].active and player.reset and player.death==deaths+1,'Same-frame capture remains lethal: '..kind)
  assert(objet.larme_dropped,'Captured carrier still drops tear')
  MobBehaviors[kind].update(m,.016);assert(player.death==deaths+1,'Contact counts one death per reset')
  player.x=50;player.y=50;player.reset=false
  for i=1,10 do update_freezes(.1);MobBehaviors[kind].update(m,.1) end
  assert(not player.reset and m.x==300 and m.y==300 and m.speed==0,'Trap immobilizes without remote damage')
  player.x=285;player.y=288;player.abyssGrace=1
  MobBehaviors[kind].update(m,.016);assert(not player.reset,'Existing grace still protects player')
  player.abyssGrace=0
  MobBehaviors[kind].update(m,.016)
  assert(player.reset and player.death==deaths+2 and isTouching(player,m),'Walking into frozen body kills: '..kind)
  player.reset=false;update_freezes(1.1)
  assert(not m.is_frozen and m.speed==1,'Movement restored on release')
  MobBehaviors[kind].update(m,.016);assert(player.reset and player.death==deaths+3,'Thawed contact remains lethal')
 end
 move_mob_towards_player=chase;move_when_player_moves=follow
 mobs={};spawn_piege(300,300);local m={type='fish',x=100,y=100,age=0,phase=0,vx=1,vy=0,speed=100,hitBox_width=30,hitBox_height=30,hitBox_offset_x=-15,hitBox_offset_y=-15};mobs[2]=m
 local move=Arena.move;Arena.move=function(actor)actor.x=300;actor.y=300;return false,false end
 local behavior=require('mobs.shared.realm_behavior')(Realms,function()return 1,0,100,true,false end)
 player.reset=false;local deaths=player.death
 behavior.update(m,.016);Arena.move=move
 assert(m.is_frozen and player.reset and player.death==deaths+1,'Realm capture during movement remains lethal')
 player.reset=false;behavior.update(m,.016)
 assert(player.reset and player.death==deaths+2,'Realm frozen early return retains contact damage')
 -- Spawned larvae use a separate update list and must follow the same rule.
 mobs={};spawn_piege(300,300);Realms.larvae={{type='larva',x=300,y=300,age=0,life=16,speed=72,hitBox_width=16,hitBox_height=16,hitBox_offset_x=-8,hitBox_offset_y=-8}}
 Realms.eggs={};Realms.bolts={};player.reset=false;deaths=player.death
 Realms.updateProjectiles(.016)
 assert(Realms.larvae[1].is_frozen and player.reset and player.death==deaths+1,'Spawned larvae remain lethal while trapped')
 print('PASS traps: capture and frozen contact kill, tear release, immobilization, grace, one death per reset, thaw and spawned larvae')
 love.event.quit()
end
return T
