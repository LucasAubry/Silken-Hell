local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 local F=require('final_spider');local A=require('final_art')
 Secret.open(false)
 for i=1,7 do
  Secret.page=i;Secret.refresh();Secret.launch(Secret.portals[1]);assert(Secret.inArena())
  shader_effect_timer=.3;shake_timer=.3;cameraShakeX=9;ghosts={{}};reset_level()
  assert(shader_effect_timer==0 and shake_timer==0 and cameraShakeX==0 and #ghosts==0,'No death effects after respawn')
  UI.buttons={};UI.gameHud();local returns={}
  for _,b in ipairs(UI.buttons)do if b.run==Secret.returnToSanctuary or b.run==App.leaveCustom then returns[b.run]=true end end
  assert(returns[Secret.returnToSanctuary] and returns[App.leaveCustom],'Both HUD exits on boss '..i)
  love.keypressed('escape');assert(App.state=='pause');UI.draw();local found=0
  for _,b in ipairs(UI.buttons)do if b.run==Secret.returnToSanctuary or b.run==App.leaveCustom then found=found+1 end end
  assert(found==2,'Both pause exits');Secret.returnToSanctuary();assert(App.state=='bossWorld' and Secret.page==i)
 end
 Secret.open(true);Secret.launch(Secret.portals[1]);assert(Secret.inArena());Secret.returnToSanctuary();assert(Secret.hardcore)
 Secret.open(false);Secret.category='mobs';Secret.refresh();Secret.launch(Secret.portals[1]);assert(Secret.inArena() and #mobs==1);App.leaveCustom();assert(App.state=='menu' and not Secret.duel)
 Secret.open(false);Secret.page=7;Secret.refresh();Secret.launch(Secret.portals[1])
 for _,n in ipairs({1,2,1,3})do F.webs={};F.shoot();assert(#F.webs==n);for _,w in ipairs(F.webs)do assert(math.abs(math.sqrt(w.vx*w.vx+w.vy*w.vy)-460)<.01)end end
 F.webs={};F.phase='webs';F.snare=0;F.webGrace=0;F.wallWeb(player.x+15,player.y+12);F.updateWebs(0)
 assert(F.snare>0 and F.snareSource=='floor' and Ending.locked())
 local draw=A.draw;local overlays=0;A.draw=function(name,...) if name=='web_wall' then overlays=overlays+1 end;return draw(name,...)end;F.draw();A.draw=draw;assert(overlays==#F.stuck,'Floor snare only draws its existing web')
 F.stuck={};F.phase='webs';F.webs={{x=player.x+15,y=player.y+12,vx=0,vy=0}};F.updateWebs(.01);assert(F.snareSource=='shot')
 for _,color in ipairs({'red','white','black'})do for _,dir in ipairs({'left','up'})do assert(love.filesystem.getInfo(require('asset_paths').resolve('assets/sprites/final/'..dir..'_'..color..'.png')))end end
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=2
  if tick==1 then reset_level();F.angle=math.pi/2;F.shoot();F.shoot();App.capture='sanctuary-rework-queen.png'
  elseif tick==4 then App.state='pause';App.capture='sanctuary-rework-pause.png'
  elseif tick==7 then Secret.open(false);Secret.page=5;Secret.refresh();Secret.launch(Secret.portals[1]);App.capture='sanctuary-rework-abyss.png'
  elseif tick==10 then
   love.draw=function()
    local g=love.graphics;g.clear(.04,.05,.07);local w,h=g.getDimensions();g.push();g.scale(w/1200,h/720)
    for row,name in ipairs({'queen','baby_white','baby_black','partner'})do for col,angle in ipairs({math.pi/2,math.pi,-math.pi/2})do
     local x=col*300;local y=75+(row-1)*140;g.setColor(1,1,1);A.spider(name,x,y,110,angle);if name=='queen'then A.clutch(x,y,110,24,angle)end
    end end
    for i=1,3 do g.setColor(1,1,1);A.draw('web_wall',i*300,640,140)end
    g.pop();if tick==10 then g.captureScreenshot('sanctuary-rework-assets.png')end
   end
  elseif tick==13 then print('PASS 7 boss return flows, demon and creature arena, cleared respawn effects, 1/2/3 volleys, existing-web snare, directional assets');love.event.quit()end
 end
end
return T
