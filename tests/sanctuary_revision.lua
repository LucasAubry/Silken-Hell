local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false;Replay.input=nil
 Profile.save=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end;Profile.name='QA';Profile.language='fr'
 App.sessionLayout=nil;App.singleLevel=false;App.preview=false;App.practice=nil;App.hardcore=false;Secret.duel=nil;LevelLayouts.disabled=true
 local C=require('run_start');local L=require('boss_liberation');local F=require('final_spider');local cycle=require('mobs.bosses.abyss.pattern_cycle')
 local function level(w,n)
  Replay.recording=false;Replay.input=nil;LevelLayouts.disabled=true;App.state='playing';App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;Secret.duel=nil;Campaign.select(w);player.level=n or (w==3 and 1 or 10);reset_level();player.reset=false;player.falling=false;C.active=false;C.goAge=nil
 end
 Profile.storyTexts={}
 for _,world in ipairs(Worlds.order)do
  level(world);assert(not Story.wallAvailable(),'Wall hidden during boss fight: '..world)
  local boss=({[1]=Raven,[2]=Wasp,[3]=F,[4]=Octopus,[5]=Hedgehog,[6]=Storm,[7]=Abyss})[world]
  L.start(boss,'test',function()boss.defeated=true;objet.larme.taken=false end)
  assert(not Story.wallAvailable(),'Wall hidden during death animation')
  L.update(2);Aftermath.update(0);assert(Story.wallAvailable(),'Every defeated boss reveals its inscription: '..world)
  local x,y,side=Story.wallSpot();player.x=side=='left' and 22 or side=='right' and Arena.width-60 or x-15
  player.y=side=='top' and 22 or side=='bottom' and 549 or y-12
  for _=1,4 do UI.clock=UI.clock+.1;Story.updateWall(.1)end
  assert(Profile.storyTexts[tostring(Campaign.biome)],'Post-boss reading awards discovery')
  Secret.duel={kind='boss'};assert(Story.wallAvailable(),'Sanctuary duel also reveals the message');Secret.duel=nil
 end
 assert(Story.progress()==7)
 level(9,1);Raven.defeated=true;objet.larme.taken=false;assert(Story.wallAvailable(),'Standalone hardcore boss has an inscription')
 level(8,5);Abyss.defeated=true;objet.larme.taken=false
 assert(Story.wallAvailable() and Story.localizedWorld(8)==Story.worlds[7],'Boss rush uses the current boss biome inscription')
 level(2);player.x=Arena.width*.7;player.y=188
 Wasp.roundActive=true;Wasp.hitGrace=100;Wasp.bees[2].hp=0;Wasp.bees[3].hp=0
 local bee=Wasp.bees[1];bee.x=65;bee.y=200;bee.tx=65;bee.ty=200;bee.phase='position';bee.attack=1;bee.vx=1;bee.vy=0;bee.dashesLeft=2
 Wasp.updateBees(.01);assert(bee.phase=='aim' and bee.time==.20,'Original short wall pause')
 local bx,by=bee.x,bee.y;player.y=420;Wasp.updateBees(.01)
 assert(bee.x==bx and bee.y==by,'Wasp cannot slide on the wall')
 Wasp.updateBees(.2);assert(bee.phase=='charge')
 bee.x=Arena.width-55;bee.y=200;bee.dashesLeft=2;Wasp.updateBees(.02)
 assert(bee.phase=='aim' and bee.time==.18,'Original rebound timing')
 level(3,1);F.reset(true);assert(F.hp==13 and F.maxHp==13)
 F.x=150;F.y=300;F.phase='charge';F.chargeX=650;F.chargeY=300;F.contactGrace=10;player.x=900;player.y=450
 local egg={x=200,y=300,hits=0,seed=1};F.eggs={egg};F.updateCharge(.03)
 assert(egg.hits==1 and #F.eggs==1 and F.hp==13,'A charge cracks an egg once')
 F.updateCharge(.03);assert(egg.hits==1,'Remaining in egg contact does not add cracks')
 F.x=150;F.chargeEggs={};F.updateCharge(.04)
 assert(#F.eggs==0 and F.hp==12,'A second dash breaks the cracked egg')
 level(7);local seen={};player.x=Arena.width*.75;player.y=280
 local health=Abyss.hp
 for _=1,2600 do
  player.x=Arena.width*.5;player.y=Abyss.swimY==445 and 80 or 480;player.charges=1
  Abyss.bombs={};player.abyssGrace=10;cycle.update(Abyss,.02);seen[Abyss.phase]=true
  assert(Abyss.hp==health,'No automatic damage or healing')
 end
 for _,phase in ipairs({'openingSpit','traverse','exitSwim','returnHead','bones','suction','spit'})do assert(seen[phase],'Restored fight phase: '..phase)end
 assert(Abyss.head.w==180 and Abyss.head.h==219,'Head fits the body proportions')
 level(7);cycle.enter(Abyss,'bones');player.abyssGrace=10;cycle.update(Abyss,.5);assert(#Abyss.plankton==0,'No light charges in boss fight')
 local mx,my=cycle.mouth(Abyss);player.x=mx-15;player.y=my-12;player.dashing=false
 local hp=Abyss.hp;player.abyssGrace=10;cycle.contact(Abyss);assert(Abyss.hp==hp,'Charge without a dash does not hurt')
 player.dashing=true;cycle.contact(Abyss);assert(Abyss.hp==hp,'Dash preserves stored energy');cycle.enter(Abyss,'suction');mx,my=cycle.mouth(Abyss);player.x=mx-15;player.y=my-12;player.reset=false;cycle.suction(Abyss,.1);assert(Abyss.hp==hp and player.charges==0,'Charged suction allows survival without boss damage')
 cycle.suction(Abyss,.1);assert(Abyss.hp==hp,'Absorption cannot spend the same charges twice')
 local move,slow=Input.move,Input.slow
 level(7);cycle.enter(Abyss,'suction');player.charges=4;mx,my=cycle.mouth(Abyss);player.x=mx-15;player.y=my-12
 cycle.suction(Abyss,.1);assert(Abyss.hp==18 and player.charges==0,'Swallowing spends charges to survive')
 level(7);cycle.enter(Abyss,'traverse');Abyss.swimHead.x=Arena.width*.5;Abyss.buildBones()
 player.x=Abyss.bones[1].x-15;player.y=Abyss.bones[1].y-12;player.dashing=true;player.charges=4;player.abyssGrace=0
 hp=Abyss.hp;cycle.contact(Abyss);assert(Abyss.hp==hp,'Body cannot be damaged even with energy')
 level(1,2)
 Secret.open(false);local hall=Secret.hallWidth;assert(#Secret.portals==7 and hall>Arena.width,'Seven thrones share a scrolling hall')
 local dx,dy=0,0;Input.move=function()return dx,dy end;Input.slow=function()return true end
 Secret.cooldown=0;Secret.update(.02);local y=Secret.y
 dy=1;for _=1,30 do Secret.update(.05)end;assert(Secret.y==y and not Secret.pending,'Vertical movement is disabled')
 dy=0;dx=1;for _=1,120 do Secret.update(.05)end;assert(Secret.x>1000 and Secret.cameraX>0 and Secret.y==y,'Horizontal walk scrolls the gallery')
 Secret.x=Secret.position(4);dx=0;dy=0;Secret.update(.02);dy=-1;Secret.update(.02)
 assert(Secret.pending==Secret.portals[4] and App.state=='bossWorld','Up in front of a throne opens confirmation')
 Secret.key('escape');Secret.update(.05);assert(not Secret.pending,'Holding up after cancel does not reopen dialog')
 dy=0;Secret.update(.02);dy=-1;Secret.cooldown=0;Secret.update(.02);Secret.confirm();assert(not Secret.pending and App.state=='bossWorld','No cancels without entering battle')
 dy=0;Secret.update(.02);dy=-1;Secret.cooldown=0;Secret.update(.02);Secret.key('left');Secret.key('return')
 assert(App.state=='playing' and Campaign.world==Secret.portals[4].world and C.countdown==3,'Yes loads chosen boss with countdown')
 Input.move,Input.slow=move,slow
 local before=timer;local bx,by=player.x,player.y;local oldFrame=Replay.frame
 C.press(Profile.keys.dash);assert(C.countdown==3,'Speed input cannot skip countdown')
 for _=1,120 do love.update(1/60)end
 assert(C.active and timer==before and player.x==bx and player.y==by and Replay.frame==oldFrame,'World and replay stay frozen during 3–2–1')
 local remaining=C.countdown;App.state='pause';love.update(.2);assert(C.countdown==remaining,'Pause freezes countdown');App.state='playing'
 for _=1,62 do love.update(1/60)end
 assert(not C.active and timer>before,'Combat starts automatically after 1')
 Secret.returnToSanctuary();assert(App.state=='bossWorld' and math.abs(Secret.x-Secret.position(4))<1,'Return restores the selected throne')
 local oldPad,oldBindings=Input.pad,Profile.padBindings
 local pad={buttons={}}
 function pad:isGamepad()return true end
 function pad:isConnected()return true end
 function pad:isGamepadDown(button)return self.buttons[button] or false end
 function pad:getGamepadAxis()return 0 end
 Input.pad=pad;Profile.padBindings=require('pad_controls').load()
 Secret.ask(1);Input.press(pad,'b');assert(not Secret.pending and App.state=='bossWorld','Gamepad B cancels confirmation')
 Secret.ask(1);pad.buttons.dpleft=true;Secret.update(.02);pad.buttons={};Input.press(pad,'a')
 assert(App.state=='playing' and C.countdown==3,'Gamepad direction and A confirm the selected boss')
 Input.pad=oldPad;Profile.padBindings=oldBindings;Input.active=false
 Secret.returnToSanctuary();Secret.ask(2);UI.buttons={};Secret.draw();UI.click(440,440)
 assert(App.state=='playing' and Campaign.world==6 and C.countdown==3,'Mouse Yes launches exactly the named boss')
 level(7);cycle.enter(Abyss,'bones');Abyss.resize(.8);Abyss.resize(1.25);love.draw()
 Bosses.load({{type='skeleton_head',x=200,y=300}},{},{})
 local instance=Bosses.items[1].boss;cycle.enter(instance,'bones');instance.resize(.8);instance.resize(1.25);instance.drawLights()
 assert(instance.phase=='bones' and instance.hp==18,'Authored boss instances render and resize the same new attacks')
 print('PASS all boss inscriptions after death, sanctuary/hardcore/rush messages, stationary wasp wall pauses, 13-HP queen and cracked eggs, restored Abyss cycle and proportional charged damage, seven-throne horizontal gallery, confirmation/cancel and frozen 3–2–1 countdown')
 local frame=0
 love.update=function()
  frame=frame+1;UI.clock=UI.clock+.016;require('achievement_notice').active=nil;require('achievement_notice').queue={};require('discovery_notice').active=nil;require('discovery_notice').queue={}
  if frame==1 then Secret.open(false);Secret.facing='right';App.capture='sanctuary-thrones-first.png'
  elseif frame==3 then Secret.x=Secret.position(4);Secret.cameraX=Secret.x-Arena.width*.5;App.capture='sanctuary-thrones-middle.png'
  elseif frame==5 then Secret.ask(4);App.capture='sanctuary-thrones-confirm.png'
  elseif frame==7 then Secret.confirmYes=true;Secret.confirm();App.capture='sanctuary-countdown.png'
  elseif frame==9 then level(7);player.x=Arena.width*.65;player.y=470;cycle.enter(Abyss,'bones');player.abyssGrace=10;cycle.update(Abyss,.6);App.capture='abyss-blue-mist.png'
  elseif frame==11 then cycle.enter(Abyss,'bones');player.charges=3;App.capture='abyss-charged-mouth.png'
  elseif frame==13 then Secret.open(false);Secret.x=Secret.position(7);Secret.cameraX=math.max(0,Secret.hallWidth-Arena.width);App.capture='sanctuary-thrones-last.png'
  elseif frame==15 then print('PASS sanctuary and Abyss visual captures');love.event.quit()end
 end
end
return T
