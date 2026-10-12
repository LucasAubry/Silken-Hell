-- Renaissance: guardian encounter, reunion chase, credits, then combined results.
local E={active=false,clock=0}
local Motion=require 'reunion_motion'
local Walk=require 'brown_walk'
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
 E.active=(Campaign.world==3 or Campaign.world==8 and Campaign.biome==3) and not App.sessionLayout and not App.workshopMap and not App.preview
 E.pending=false;E.creditsStarted=false;E.clock=0;E.phase='approach';E.fade=0;E.family=false;E.completed=false;E.departTime=0
 E.partner={x=Arena.width-110,y=280,angle=0,walkPhase=0,walkMoving=false}
 if E.active then
  mobs={};Arena.interior={};while #Arena.walls>4 do table.remove(Arena.walls) end
  player.x=(player.level==1 or Campaign.world==8) and Arena.width*.5-15 or 75;player.y=(player.level==1 or Campaign.world==8) and 500 or 300
  objet.larme.taken=true;Campaign.carrier=nil;ghosts={};Renaissance.active=false;Aftermath.reset()
 end
 require('final_spider').reset(E.active and (player.level==1 or Campaign.world==8))
end
function E.locked() return E.active and (require('final_spider').snare>0 or E.phase~='approach') end
function E.complete()
 if E.completed then return end
 E.completed=true;E.phase='complete'
 if not Replay.playing then
  if App.singleLevel then Replay.finish()
  else
   Online.checkpoint(2,timer,player.death)
   if App.hardcore then Hardcore.complete(3) else Profile.complete(3,timer,player.death) end
  end
 end
 local V=require('victory_screen');V.enter();local result=V.run
 E.startCredits(function() V.run=result;App.state='victory';E.active=false end)
end
function E.update(dt)
 if not E.active then return end
 E.clock=E.clock+dt
 if (player.level==1 or Campaign.world==8) then require('final_spider').update(dt);return end
 if E.completed then return end
 if E.phase=='depart' then
  E.departTime=E.departTime+dt
  E.partner.y=E.partner.y-Motion.speed*dt;E.partner.angle=math.pi;E.partner.facing='up'
  Walk.advance(E.partner,Motion.speed*dt,dt)
  if E.partner.y< -70 then E.complete() end
  return
 end
 local p=E.partner;local dx,dy=p.x-player.x-15,p.y-player.y-12;local d=math.sqrt(dx*dx+dy*dy)
 if d<43 then E.complete();return end
 if E.clock>=30 then
  Achievements.award('heartbreak');E.phase='depart';return
 end
 Walk.advance(p,Motion.advance(p,player.x+15,player.y+12,Arena.width,Arena.height,dt),dt)
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
 if (player.level==1 or Campaign.world==8) then require('final_spider').draw();return end
 love.graphics.setColor(1,1,1);require('final_art').spider('partner',E.partner.x,E.partner.y,62,E.partner.angle,E.partner)
end
function E.openReunion()
 if Campaign.world==8 then
  if not Replay.playing then Online.checkpoint(player.level,timer,player.death);Hardcore.complete(8) end
  E.active=false;require('victory_screen').enter();return
 end
 if Secret.duel then App.state='customVictory';if not Replay.playing then Replay.finish() end;return end
 if not Replay.playing and not App.singleLevel then
  Online.checkpoint(1,timer,player.death);if not App.hardcore then Profile.levelReached(3,2) end
 end
 App.practice=nil;player.level=2;reset_level();App.state='playing'
end
function E.drawHud()
 local F=require('final_spider')
 Hardcore.draw()
 UI.outlined(UI.time(Scoring.total(timer,player.death)),40,20,'medium',{1,.95,.85},200)
 UI.deathCounter()
 UI.text((Campaign.world==8 and 'Boss ' or 'Niveau ')..player.level,520,18,'small',{1,.94,.86},160,'center')
 if F.active then require('boss_hud').draw(F) end
 if not Replay.playing then
  UI.button('i',1008,13,36,36,Bestiary.openLevel,false,true)
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
 if E.partner then
  local x=E.partner.x*ratio
  E.partner.x=math.max(Motion.margin,math.min(Arena.width-Motion.margin,x))
  if E.partner.x~=x then E.partner.heading=nil end
 end
 if E.active then require('final_spider').resize(ratio) end
end
local creditSpacing,creditSpeed=90,90
function E.startCredits(onComplete)
 E.creditTime=0;E.creditEscapes=0;E.creditComplete=onComplete;E.creditFinished=false
 App.state='credits';UI.buttons={}
end
function E.creditDuration() return (790+#E.credits*creditSpacing+50)/creditSpeed end
function E.finishCredits()
 if E.creditFinished then return end
 E.creditFinished=true
 local callback=E.creditComplete;E.creditComplete=nil
 if callback then callback() else App.state='victory' end
end
function E.creditKey(key,isrepeat)
 if key~='escape' or isrepeat then return end
 E.creditEscapes=(E.creditEscapes or 0)+1
 if E.creditEscapes>=3 then E.finishCredits() end
end
function E.updateCredits(dt)
 E.creditTime=E.creditTime+dt
 if E.creditTime>=E.creditDuration() then E.finishCredits() end
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
 g.setColor(.65,.69,.73,.85);g.setFont(UI.fonts.small)
 g.pop()
end
return E
