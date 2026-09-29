-- Renaissance: guardian encounter, reunion chase, credits, then combined results.
local E={active=false,clock=0}
E.credits={
 {'SILKEN HELL','Un jeu de Lucas Aubry'},
 {'Développement','Aubry Lucas'},
 {'Musique','Aubry Lucas'},
 {'Son','Aubry Lucas'},
 {'Idées','Aubry Lucas\nAmir'},
 {'Bêta-tests','Gilloux\nMaxance\nAmir\nNils'},
 {'Conception du jeu et des niveaux','Aubry Lucas'},
 {'Direction artistique et graphismes','Aubry Lucas'},
 {'Écriture, animations et réalisation','Aubry Lucas'},
 {'Merci d’avoir joué','Ça me touche profondément.'},
}
E.aiNotice='Certaines images ont été générées par intelligence artificielle.'
function E.reset()
 E.active=Campaign.world==3 and not App.sessionLayout and not App.workshopMap and not App.preview
 E.pending=false;E.creditsStarted=false;E.clock=0;E.phase='approach';E.fade=0;E.family=false;E.completed=false
 E.partner={x=Arena.width-110,y=280,angle=0}
 if E.active then
  mobs={};Arena.interior={};while #Arena.walls>4 do table.remove(Arena.walls) end
  player.x=player.level==1 and Arena.width*.5-15 or 75;player.y=player.level==1 and 500 or 300
  objet.larme.taken=true;Campaign.carrier=nil;ghosts={};Renaissance.active=false;Aftermath.reset()
 end
 require('final_spider').reset(E.active and player.level==1)
end
function E.locked() return E.active and (require('final_spider').snare>0 or E.phase~='approach') end
function E.complete()
 if E.completed then return end
 E.completed=true;E.phase='complete'
 if not Replay.playing then
  if App.singleLevel then Replay.finish()
  else
   if not App.hardcore then Online.checkpoint(2,timer,player.death) end
   if App.hardcore then Hardcore.complete(3) else Profile.complete(3,timer,player.death) end
  end
 end
 local V=require('victory_screen');V.enter();local result=V.run
 E.startCredits(function() V.run=result;App.state='victory';E.active=false end)
end
function E.update(dt)
 if not E.active then return end
 E.clock=E.clock+dt
 if player.level==1 then require('final_spider').update(dt);return end
 if E.completed then return end
 local p=E.partner;local dx,dy=p.x-player.x-15,p.y-player.y-12;local d=math.sqrt(dx*dx+dy*dy)
 if d<43 then E.complete();return end
 -- Fast at first, progressively slower so a patient chase always catches up.
 local speed=math.max(45,440-E.clock*18)
 local vx,vy=dx/math.max(1,d),dy/math.max(1,d)
 if p.x<85 and vx<0 or p.x>Arena.width-85 and vx>0 then vx=0;vy=p.y>300 and -1 or 1 end
 if p.y<105 and vy<0 or p.y>510 and vy>0 then vy=0;vx=p.x>Arena.width*.5 and -1 or 1 end
 local len=math.max(1,math.sqrt(vx*vx+vy*vy))
 p.x=math.max(65,math.min(Arena.width-65,p.x+vx/len*speed*dt));p.y=math.max(85,math.min(530,p.y+vy/len*speed*dt))
 p.angle=math.atan2(vy,vx)-math.pi/2
end
-- Recolor the existing brown spider, preserving the exact silhouette and eyes.
function E.spider(x,y,size,white,spots,variant,angle)
 local g=love.graphics;g.push('all')
 E.familyShader=E.familyShader or g.newShader([[
 extern bool whiteBody;extern bool spotted;extern float variant;
 vec4 effect(vec4 color,Image image,vec2 uv,vec2 px) {
  vec4 p=Texel(image,uv);float v=max(p.r,max(p.g,p.b));
  float body=smoothstep(.055,.20,v);
  vec3 ivory=vec3(.91,.91,.87)*(.58+.65*v);
  float a=length((uv-vec2(.38+variant*.025,.39))/vec2(.095,.075));
  float b=length((uv-vec2(.60,.58-variant*.02))/vec2(.11,.075));
  float c=length((uv-vec2(.45,.70))/vec2(.07,.085));
  float patch=1.0-smoothstep(.82,1.0,min(a,min(b,c)));
  vec3 brown=p.rgb;
  vec3 base=whiteBody ? mix(brown,ivory,body) : brown;
  vec3 other=whiteBody ? brown : mix(brown,ivory,body);
  if(spotted) base=mix(base,other,patch*body);
  return vec4(base,p.a)*color;
 }]])
 g.setShader(E.familyShader);E.familyShader:send('whiteBody',white);E.familyShader:send('spotted',spots);E.familyShader:send('variant',variant or 0)
 local image=player.img_down;local scale=size/image:getWidth();g.setColor(1,1,1)
 g.draw(image,x,y,angle or 0,scale,scale,image:getWidth()/2,image:getHeight()/2)
 g.pop()
end
function E.drawFamily()
 if not E.active then return end
 if player.level==1 then require('final_spider').draw();return end
 love.graphics.setColor(1,1,1);require('final_art').spider('partner',E.partner.x,E.partner.y,62,E.partner.angle)
end
function E.openReunion()
 if Secret.duel then App.state='customVictory';if not Replay.playing then Replay.finish() end;return end
 if not Replay.playing and not App.hardcore and not App.singleLevel then Online.checkpoint(1,timer,player.death);Profile.levelReached(3,2) end
 App.practice=nil;player.level=2;reset_level();App.state='playing'
end
function E.drawHud()
 local F=require('final_spider')
 UI.outlined(UI.time(Scoring.total(timer,player.death)),40,20,'medium',{1,.95,.85},200)
 UI.text('Niveau '..player.level,520,18,'small',{1,.94,.86},160,'center')
 if F.active then
  require('boss_hud').draw(F)
  if F.defeated then UI.text('Le combat est terminé. Rejoins la porte de soie.',250,123,'body',{.85,1,.91},700,'center') end
 else UI.text('Rejoins l’araignée blanche.',300,66,'body',{1,.97,.9},600,'center') end
 if not Replay.playing then
  UI.iconButton(1090,31,'pause',function() App.state='pause' end)
  UI.iconButton(1150,31,'restart',App.restartCurrent)
 end
end
function E.checkHellVictory()
 -- Hell uses the ordinary victory screen. Final credits belong to Renaissance.
 return false
end
function E.drawPlayer()
 love.graphics.setColor(1,1,1);draw_player(direction)
end
function E.drawOverlay(w,h)
 if not E.active then return end
 local g=love.graphics;g.push('all');g.setShader();g.setColor(0,0,0,E.fade);g.rectangle('fill',0,0,w,h);g.pop()
end
function E.resize(ratio)
 if E.partner then E.partner.x=E.partner.x*ratio end
 if E.active then require('final_spider').resize(ratio) end
end
local creditSpacing,creditSpeed=90,90
function E.startCredits(onComplete)
 E.creditTime=0;E.creditComplete=onComplete
 App.state='credits';UI.buttons={}
end
function E.creditDuration() return (790+#E.credits*creditSpacing+50)/creditSpeed end
function E.updateCredits(dt)
 E.creditTime=E.creditTime+dt
 if E.creditTime>=E.creditDuration() then
  local callback=E.creditComplete;E.creditComplete=nil
  if callback then callback() else App.state='victory' end
 end
end
function E.drawCredits(w,h)
 local g=love.graphics;g.push('all');g.setShader();g.clear(.008,.009,.015,1)
 local scale=math.min(w/1200,h/750);g.translate((w-1200*scale)/2,(h-750*scale)/2);g.scale(scale)
 local scroll=E.creditTime*creditSpeed
 for i,row in ipairs(E.credits) do
  local y=790+(i-1)*creditSpacing-scroll
  if y> -180 and y<800 then
   g.setFont(UI.fonts.small);g.setColor(.62,.68,.76);g.printf(row[1],100,y,1000,'center')
   g.setFont(UI.fonts.body);g.setColor(.95,.94,.89);g.printf((row[2]:gsub('\n',' · ')),100,y+26,1000,'center')
  end
 end
 local y=790+#E.credits*creditSpacing-scroll
 g.setFont(UI.fonts.small);g.setColor(.53,.56,.62);g.printf(E.aiNotice,130,y,940,'center')
 g.pop()
end
return E
