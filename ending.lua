-- Campaign ending: quiet reunion and a dedicated, legible credits roll.
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
 {'Merci d’avoir joué',''},
}
E.aiNotice='Certaines images ont été générées par intelligence artificielle.'
function E.reset()
 E.active=Campaign.world==3 and not App.singleLevel
 E.pending=E.active and player.level==1;E.creditsStarted=false
 E.clock=0;E.phase='approach';E.fade=0;E.family=false;E.completed=false
 E.partner={x=Arena.width*.66,y=300}
 E.children={{white=true,spots=true,sex='girl',dx=-68,dy=64},{white=true,spots=true,sex='girl',dx=3,dy=78},{white=false,spots=true,sex='boy',dx=68,dy=60}}
 if E.active then
  mobs={};Arena.interior={};while #Arena.walls>4 do table.remove(Arena.walls) end
  player.x=Arena.width*.28;player.y=300;objet.larme.taken=true
  Campaign.carrier=nil;ghosts={}
 end
end
function E.locked() return E.active and (E.pending or E.phase~='approach') end
function E.update(dt)
 if not E.active or E.pending then return end
 E.clock=E.clock+dt
 if E.phase=='approach' then
  if (player.x+15-E.partner.x)^2+(player.y+12-E.partner.y)^2<78^2 then E.phase='fadeOut';E.phaseTime=0 end
 elseif E.phase=='fadeOut' then
  E.phaseTime=E.phaseTime+dt;E.fade=math.min(1,E.phaseTime/1.25)
  if E.fade==1 then
   E.phase='black';E.phaseTime=0;E.family=true
   player.x=Arena.width/2-60;player.y=280;E.partner.x=Arena.width/2+45;E.partner.y=292
   ghosts={}
  end
 elseif E.phase=='black' then
  E.phaseTime=E.phaseTime+dt
  if E.phaseTime>=.9 then E.phase='fadeIn';E.phaseTime=0 end
 elseif E.phase=='fadeIn' then
  E.phaseTime=E.phaseTime+dt;E.fade=math.max(0,1-E.phaseTime/1.8)
  if E.fade==0 then E.phase='family';E.phaseTime=0 end
 elseif E.phase=='family' then
  E.phaseTime=E.phaseTime+dt
 end
end
-- Recolor the existing brown spider, preserving the exact silhouette and eyes.
function E.spider(x,y,size,white,spots,variant)
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
 g.draw(image,x,y,0,scale,scale,image:getWidth()/2,image:getHeight()/2)
 g.pop()
end
function E.drawFamily()
 if not E.active or E.pending then return end
 E.spider(E.partner.x,E.partner.y,62,true,false)
 if E.family then
  for i,c in ipairs(E.children) do
   E.spider(Arena.width/2+c.dx+math.sin(E.clock*1.3+i)*3,292+c.dy+math.sin(E.clock*1.6+i)*2,34,c.white,c.spots,i-2)
  end
 end
end
function E.openReunion()
 App.practice=nil;player.level=2;reset_level();App.state='playing'
end
function E.drawHud()
 if E.pending then
  UI.panel(325,215,550,280)
  UI.text('Le dernier combat',350,240,'heading',{1,.94,.8},500,'center')
  UI.text('Le boss final arrivera prochainement.',350,303,'body',{.8,.84,.87},500,'center')
  UI.button('Voir les retrouvailles',385,365,430,46,E.openReunion)
  UI.button('Retour au menu',385,423,430,38,function() App.state='menu' end)
 elseif E.phase=='family' and E.phaseTime>2 then
  UI.text('Ensemble, enfin.',350,110,'heading',{1,.96,.85},500,'center')
  UI.button('Retour au menu',460,670,280,38,function() App.state='menu' end)
 end
end
function E.checkHellVictory()
 if E.creditsStarted or App.singleLevel or Campaign.world~=2 or player.level~=Worlds.levelCount(2) or not Aftermath.cleared then return false end
 E.creditsStarted=true
 if not Replay.playing then
  if App.hardcore then Hardcore.complete(2)
  else Online.checkpoint(player.level,timer,player.death);Profile.complete(2,timer,player.death) end
 end
 E.startCredits(function()
  App.hardcore=false;App.practice=nil;App.sessionLayout=nil;App.singleLevel=false
  App.start(3)
 end)
 return true
end
function E.drawPlayer()
 E.spider(player.x+15,player.y+8,62,false,false)
end
function E.drawOverlay(w,h)
 if not E.active then return end
 local g=love.graphics;g.push('all');g.setShader();g.setColor(0,0,0,E.fade);g.rectangle('fill',0,0,w,h);g.pop()
end
function E.resize(ratio)
 if E.partner then E.partner.x=E.partner.x*ratio end
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
