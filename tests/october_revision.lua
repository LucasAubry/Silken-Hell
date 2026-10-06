local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end;LevelLayouts.disabled=true
 Profile.character=1;Profile.language='fr';Graphics.showFPS=false
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 local g=love.graphics;local function start(w,n)
  App.sessionLayout=nil;Secret.duel=nil;App.singleLevel=true;App.practice=n or 10;App.start(w);player.reset=false
 end
 local skinCanvas=g.newCanvas(128,128)
 for skin=1,5 do for _,dir in ipairs({'down','up','left','right'}) do
  g.push('all');g.setCanvas(skinCanvas);g.origin();g.clear(0,0,0,0);g.setColor(1,1,1)
  Characters.portrait(skin,64,64,100,dir);g.pop()
  local image=skinCanvas:newImageData();local _,_,_,alpha=image:getPixel(64,45)
  assert(alpha>.999,'Opaque body for skin '..skin..' '..dir);image:release()
 end end
 skinCanvas:release()
 start(2)
 local W=Wasp;W.hitGrace=100;W.roundActive=true
 for _,b in ipairs(W.bees)do b.phase='cooldown' end
 local b=W.bees[1];b.x=65;b.y=200;b.attack=1;player.x=500;player.y=200;W.positionAttack(b)
 player.y=310;W.updateBees(.01);assert(b.ty==322,'Repositioning follows the current player')
 b.x=b.tx;b.y=b.ty;b.phase='aim';b.time=.20
 player.y=360;W.updateBees(.05);assert(b.ty==372 and math.abs(b.y-372)<.01,'Wall aim still follows the player: '..b.y..' / '..b.ty)
 for i=1,4 do W.updateBees(.04) end
 assert(b.phase=='charge','Wall pause is slightly shorter')
 local vx,vy=b.vx,b.vy;player.y=200;W.updateBees(.01)
 assert(b.vx==vx and b.vy==vy,'Dash direction locks on launch')
 b.x=Arena.width-46;b.y=300;b.vx=1;b.vy=0;b.phase='charge';b.dashesLeft=2
 W.updateBees(.01);assert(b.phase=='aim' and b.time==.18)
 player.y=360;W.updateBees(.03);assert(b.ty==372 and b.y>300,'Rebounds recalibrate along the wall')
 start(3,1);local F=require('final_spider');F.engaged=true;F.phase='lay';F.phaseTime=0;F.jumpCooldown=10
 F.clock=3.2;F.x=Arena.width*.6;F.y=250;player.x=65;player.y=490
 for i=1,3 do F.update(.04) end
 assert(F.walkMoving and F.walkPhase>0 and F.surge>1.2 and #F.afterimages>0,'Queen has a walking rig and brief speed bursts with a trail')
 local walk=require('brown_walk');local old=walk.draw;local used=false
 walk.draw=function(img,dir,x,y,width,actor,bounds) if actor==F then used=true end;return old(img,dir,x,y,width,actor,bounds) end
 F.draw();walk.draw=old;assert(used,'Queen uses the same animation renderer as the player')
 F.phase='recover';F.phaseTime=0;F.clock=4.1;F.webs={};F.babies={};F.eggs={};F.update(.2)
 assert(#F.afterimages==0 and not F.walkMoving,'Trail expires when the queen stops')
 start(4);Octopus.splash()
 local canvas=g.newCanvas(480,300);g.push('all');g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);Octopus.drawInk(480,300);g.pop()
 local data=canvas:newImageData();local transparent,covered=0,0
 for y=0,299 do for x=0,479 do local _,_,_,a=data:getPixel(x,y);if a<.05 then transparent=transparent+1 end;if a>.3 then covered=covered+1 end end end
 assert(transparent/(480*300)>.3 and covered/(480*300)>.08,'Ink leaves substantial open windows while still obscuring patches')
 for _,p in ipairs({{.33,.35},{.68,.63}}) do local _,_,_,a=data:getPixel(math.floor(p[1]*480),math.floor(p[2]*300));assert(a==0,'Overlapping blots cannot fill the clear windows') end
 data:release();canvas:release()
 local servants=require('servant_art');servants.current={type='mole',bossServant=true}
 for _,dir in ipairs({'down','up','left','right'}) do assert(servants.image('mole_'..dir)==Art.images['mole_'..dir]) end;servants.current=nil
 local particles=require('tear_fx');local draw=particles.draw;local count=0
 particles.draw=function(...)count=count+1;return draw(...)end
 for _,w in ipairs(Worlds.order) do
  start(w,1);Ending.active=false;Renaissance.active=false;Campaign.carrier=nil;objet.larme.taken=false;objet.larme.abyssHeld=nil;Aftermath.cleared=false
  local x,y=objet.larme.x,objet.larme.y;Campaign.drawTear();assert(objet.larme.x==x and objet.larme.y==y,'Breath never moves the collision box')
 end
 particles.draw=draw;assert(count==7,'Every world draws tear motes')
 local sx,sy=particles.breath(.5);assert(sx~=1 and sy~=1)
 start(1,10);local x,y=Story.wallSpot();player.x=x-15;player.y=549
 assert(Story.atWall(x,y));player.x=x+20;assert(not Story.atWall(x,y),'Message requires precise horizontal alignment')
 player.x=x-15;player.y=490;assert(not Story.atWall(x,y),'Standing too far from the wall cannot reveal the message')
 local random=love.math.getRandomState();Realms.drawWind(960,600);particles.draw(300,300,{1,1,1},2)
 assert(random==love.math.getRandomState(),'Visuals do not consume gameplay randomness')
 print('PASS live wasp aiming, shorter wall pauses, fixed airborne dash, queen shared walking/bursts/trail expiry, ink clear windows, normal moles, all tear particles/breath, precise wall discovery, RNG isolation')
 local tick=0;local originalDraw=love.draw
 local function capture(name)
  g.captureScreenshot(function(d)local f=assert(io.open('/tmp/silken-october-'..name..'.png','wb'));f:write(d:encode('png'):getString());f:close()end)
 end
 local frames={'rain','rain-boss','earth-tear','ink','wall-far','wall-near','queen','moles'}
 love.update=function()
  tick=tick+1;UI.clock=4
  if tick==1 then start(6,7);Realms.clock=3;Realms.wind={x=95,y=-12};Realms.rain={{x=300,y=320,age=.6},{x=550,y=180,age=.95},{x=650,y=400,age=.4}}
  elseif tick==2 then start(6);Realms.clock=3;Storm.rain={{x=300,y=320,age=.6},{x=550,y=180,age=.95}}
  elseif tick==3 then start(5,2);Campaign.carrier=nil;objet.larme.taken=false;objet.larme_dropped=true;objet.larme.x=400;objet.larme.y=300
  elseif tick==4 then start(4);Octopus.splash()
  elseif tick==5 then start(1,10);mobs={};player.x=150;player.y=300
  elseif tick==6 then local x=Story.wallSpot();player.x=x-15;player.y=549;Story.nearSince=3.5
  elseif tick==7 then
   start(3,1);F.engaged=true;F.phase='lay';F.phaseTime=0;F.jumpCooldown=10;F.clock=3.2;F.x=600;F.y=280;player.x=70;player.y=490
   for i=1,5 do F.update(.025) end
  elseif tick==8 then start(5);for i,m in ipairs(mobs) do m.age=3;m.x=200+i*80;m.y=380 end
  elseif tick>8 then love.event.quit() end
 end
 love.draw=function()if frames[tick] then originalDraw();capture(frames[tick])end end
end
return T
