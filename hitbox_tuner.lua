-- Session-only collision tuning. All defaults preserve the original collision math.
local T={open=true,visible=true,paused=false,values={},selected='player',shapes={}}
local defaults={sx=1,sy=1,dx=0,dy=0}
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
function T.config(key)
 if Replay and Replay.playing then return defaults end
 return T.values[key] or defaults
end
function T.rect(key,x,y,w,h)
 local c=T.config(key);local ww,hh=w*c.sx,h*c.sy
 return x+(w-ww)/2+c.dx,y+(h-hh)/2+c.dy,ww,hh
end
function T.bounds(e,x,y)
 return T.rect(e==player and 'player' or e.type or 'enemy',(x or e.x)+(e.hitBox_offset_x or 0),(y or e.y)+(e.hitBox_offset_y or 0)+require('mobs.shared.floating').offset(e),e.hitBox_width,e.hitBox_height)
end
function T.playerRect()return T.bounds(player)end
function T.center()
 local x,y,w,h=T.playerRect();return x+w/2,y+h/2
end
function T.touchRect(key,x,y,w,h)
 local px,py,pw,ph=T.playerRect();local xx,yy,ww,hh=T.rect(key,x,y,w,h)
 return checkCollision(px,py,pw,ph,xx,yy,ww,hh)
end
function T.projectile(x,y,w,h)
 local px,py,pw,ph=T.playerRect();return checkCollision(x,y,w,h,px,py,pw,ph)
end
function T.ellipse(key,x,y,r)
 local c=T.config(key);return x+c.dx,y+c.dy,r*c.sx,r*c.sy
end
-- These circles are centre-distance contact zones, already including the original player margin.
function T.touchCircle(key,x,y,r)
 local cx,cy,rx,ry=T.ellipse(key,x,y,r);local px,py=T.center();local p=T.config('player')
 rx=math.max(1,rx+15*(p.sx-1));ry=math.max(1,ry+12*(p.sy-1))
 return ((px-cx)/rx)^2+((py-cy)/ry)^2<1
end
function T.sweptCircle(key,x,y,xx,yy,r)
 local c=T.config(key);local p=T.config('player');local px,py=T.center()
 local rx,ry=math.max(1,r*c.sx+15*(p.sx-1)),math.max(1,r*c.sy+12*(p.sy-1))
 x=(x+c.dx-px)/rx;y=(y+c.dy-py)/ry;xx=(xx+c.dx-px)/rx;yy=(yy+c.dy-py)/ry
 local dx,dy=xx-x,yy-y;local n=dx*dx+dy*dy;local t=n>0 and clamp(-(x*dx+y*dy)/n,0,1)or 0
 return (x+dx*t)^2+(y+dy*t)^2<=1
end
function T.circleRect(key,x,y,r)
 local cx,cy,rx,ry=T.ellipse(key,x,y,r);local px,py,pw,ph=T.playerRect()
 return ((clamp(cx,px,px+pw)-cx)/rx)^2+((clamp(cy,py,py+ph)-cy)/ry)^2<1
end
function T.inverse(key,x,y,cx,cy)
 local c=T.config(key);return cx+(x-cx-c.dx)/c.sx,cy+(y-cy-c.dy)/c.sy
end
function T.bone(b)
 local c=T.config('skeleton_fish');return b.x+c.dx,b.y+c.dy,b.w*c.sx,b.h*c.sy
end
function T.samples()
 local x,y,w,h=T.playerRect();return x+math.min(2,w/4),x+w-math.min(2,w/4),y+math.min(2,h/4),y+h-math.min(2,h/4)
end
function T.featherTouches(x,y,r)
 return T.touchCircle('player_feathers',x,y,r)
end
function T.markRun()
 if not App or not player or Replay.playing then return end
 App.hitboxTest=true;Online.current=nil;Replay.recording=false
end
function T.set(key,field,value)
 local c=T.values[key]
 if not c then c={sx=1,sy=1,dx=0,dy=0};T.values[key]=c end
 c[field]=value;T.markRun()
end
function T.reset(all)
 if all then T.values={} else T.values[T.selected]=nil end
end
function T.onStart()
 T.drag=nil
 App.hitboxTest=not Replay.playing and next(T.values)~=nil
 if App.hitboxTest then T.markRun() end
end
local function name(key)
 if key=='player' then return 'Joueur' elseif key=='player_feathers' then return 'Joueur · plumes du ciel'
 elseif key=='raven_chick' then return 'Oiseaux du nid' elseif key=='wasp_minion' then return 'Petites guêpes du boss'
 elseif key=='octopus_arms' then return 'Pieuvre · tentacules'
 elseif key=='queen' then return 'Gardienne de la Soie' elseif key=='queen_baby' then return 'Petites araignées' end
 for _,e in ipairs(Bestiary.entries) do if e.id==key then return e.name end end
 return key
end
function T.collect()
 local list={};T.shapes=list
 local function rect(key,x,y,w,h)local xx,yy,ww,hh=T.rect(key,x,y,w,h);list[#list+1]={key=key,shape='rect',x=xx,y=yy,w=ww,h=hh}end
 local function circle(key,x,y,r)local xx,yy,rx,ry=T.ellipse(key,x,y,r);if key~='octopus' then local p=T.config('player');rx=math.max(1,rx+15*(p.sx-1));ry=math.max(1,ry+12*(p.sy-1))end;list[#list+1]={key=key,shape='ellipse',x=xx,y=yy,w=rx,h=ry}end
 local function mob(m)
  if m.dead or m.abyssHeld or m.tunnelTravel then return end
  if m.type=='crab' then circle('crab',m.x,m.y,27)
  elseif m.type=='light_jelly' then rect('light_jelly',m.x-22,m.y-22,44,44)
  elseif m.hitBox_width and m.hitBox_height then
   local x,y,w,h=T.bounds(m)
   list[#list+1]={key=m.type or 'enemy',shape='rect',x=x,y=y,w=w,h=h}
  end
  if m.electric then circle('electric_gull',m.x,m.y,30) end
 end
 for _,m in ipairs(mobs or {})do mob(m)end
 for _,m in ipairs(Realms.larvae or {})do mob(m)end
 local sky=false
 local function boss(kind,b)
  if not b or not b.active or b.defeated then return end
  if kind=='storm' then
   sky=true;if not b.hidden then circle('storm',b.x,b.y,34)end
  elseif kind=='merle' then
   if not b.broken then circle('merle',b.x,b.y,58)end
   for _,m in ipairs(b.chicks)do circle('raven_chick',m.x,m.y,25)end
  elseif kind=='hedgehog' then rect('hedgehog',b.x-30,b.y-30,60,60)
  elseif kind=='wasp' then
   for _,m in ipairs(b.bees)do if m.hp>0 then rect('wasp',m.x-26,m.y-((m.phase=='fatigued')and 32 or 42),52,64)end end
   for _,m in ipairs(b.minions)do circle('wasp_minion',m.x,m.y,20)end
  elseif kind=='octopus' then
   circle('octopus',b.x,b.y,65)
   list[#list+1]={key='octopus_arms',shape='arms',boss=b}
   for _,m in ipairs(b.crabs)do if not m.dead then circle('crab',m.x,m.y,27)end end
  elseif kind=='skeleton_fish' then
   for _,bone in ipairs(b.bones or {})do list[#list+1]={key='skeleton_fish',shape='mask',bone=bone}end
  end
 end
 boss('skeleton_fish',Abyss);boss('storm',Storm);boss('merle',Raven);boss('wasp',Wasp);boss('hedgehog',Hedgehog);boss('octopus',Octopus)
 for _,item in ipairs(Bosses.items or {})do boss(item.kind,item.boss)end
 local q=require('final_spider')
 if q.active and not q.defeated then
  circle('queen',q.x,q.y,27)
  for _,m in ipairs(q.babies or {})do if not m.dead and not m.webbed then circle('queen_baby',m.x,m.y,25)end end
 end
 if sky then
  local x,y=T.center();local c=T.config('player_feathers');local p=T.config('player')
  list[#list+1]={key='player_feathers',shape='ellipse',x=x-c.dx,y=y-c.dy,w=math.max(1,17*c.sx+15*(p.sx-1)),h=math.max(1,17*c.sy+12*(p.sy-1))}
 end
 local keys={'player'};local found={player=true}
 for _,s in ipairs(list)do if not found[s.key]then keys[#keys+1]=s.key;found[s.key]=true end end
 table.sort(keys,function(a,b)if a==b then return false elseif a=='player'then return true elseif b=='player'then return false end;return name(a)<name(b)end)
 T.keys=keys;if not found[T.selected]then T.selected='player'end
 return list
end
local maskImages={}
local function drawMask(b)
 local a=Art.images[b.key];if not a or not a.mask then return end
 local image=maskImages[b.key]
 if not image then
  local data=love.image.newImageData(192,192)
  local function filled(x,y)return x>=0 and y>=0 and x<192 and y<192 and a.mask[y*192+x]end
  for y=0,191 do for x=0,191 do
   if filled(x,y) and (not filled(x-1,y) or not filled(x+1,y) or not filled(x,y-1) or not filled(x,y+1))then data:setPixel(x,y,1,1,1,1)end
  end end
  image=love.graphics.newImage(data);image:setFilter('nearest','nearest');data:release();maskImages[b.key]=image
 end
 local x,y,w,h=T.bone(b);love.graphics.draw(image,x,y,b.angle or 0,(b.flip and -1 or 1)*w/192,h/192,96,96)
end
local function drawArms(b)
 local g=love.graphics;local c=T.config('octopus_arms')
 g.push();g.translate(b.x+c.dx,b.y+c.dy);g.scale(c.sx,c.sy);g.rotate(b.angle)
 for arm=1,8 do if b.arms[arm]>0 then
  local points=b.armCurve(arm)
  for i=1,#points-1,2 do
   local a,z=points[i],points[math.min(#points,i+2)];local dx,dy=z.x-a.x,z.y-a.y;local d=math.max(.001,math.sqrt(dx*dx+dy*dy));local nx,ny=-dy/d,dx/d
   g.line(a.x+nx*a.width,a.y+ny*a.width,z.x+nx*z.width,z.y+ny*z.width)
   g.line(a.x-nx*a.width,a.y-ny*a.width,z.x-nx*z.width,z.y-ny*z.width)
   g.circle('line',a.x,a.y,a.width)
  end
 end end
 g.pop()
end
function T.drawWorld()
 if not T.visible then return end
 local g=love.graphics;g.push('all');g.setShader();g.setLineStyle('rough')
 T.collect()
 for _,s in ipairs(T.shapes)do
  local selected=s.key==T.selected
  local function shape()
   if s.shape=='rect'then g.rectangle('line',s.x,s.y,s.w,s.h)elseif s.shape=='mask'then drawMask(s.bone)elseif s.shape=='arms'then drawArms(s.boss)else g.ellipse('line',s.x,s.y,s.w,s.h)end
  end
  if s.shape=='rect' or s.shape=='ellipse'then g.setColor(0,0,0,.85);g.setLineWidth(3);shape()end
  g.setLineWidth(1);g.setColor(s.key=='player_feathers' and 1 or (selected and .2 or 1),selected and 1 or .22,s.key=='player_feathers' and .1 or (selected and 1 or .55),.95);shape()
 end
 if not Abyss.playerHidden() and not player.abyssHeld and not player.tunnelTravel then
  local x,y,w,h=T.playerRect()
  g.setLineWidth(3);g.setColor(0,0,0,.8);g.rectangle('line',x,y,w,h)
  g.setLineWidth(1);g.setColor(1,1,1,.95);g.rectangle('line',x,y,w,h)
 end
 g.pop()
end
function T.layout()
 local w,h=love.graphics.getDimensions();local s=math.min(1,w/900,h/680)
 return w-320*s-14*s,86*s,s
end
local fields={{'sx','Largeur',.2,2.5},{'sy','Hauteur',.2,2.5},{'dx','Décalage X',-90,90},{'dy','Décalage Y',-90,90}}
function T.drawPanel()
 if App.state~='playing' or Replay.playing then return end
 local g=love.graphics;g.push('all');g.origin();g.setShader()
 local x,y,s=T.layout();g.translate(x,y);g.scale(s);g.setFont(UI.fonts.tiny)
 g.setColor(.025,.035,.045,.96);g.rectangle('fill',0,0,320,T.open and 364 or 34,8,8)
 g.setColor(.8,.83,.76);g.setLineWidth(1);g.rectangle('line',0,0,320,T.open and 364 or 34,8,8)
 g.print('HITBOX · TEST',12,9);g.printf(T.open and 'F3 · masquer' or 'F3 · ouvrir',158,9,150,'right')
 if T.open then
  T.collect();local c=T.config(T.selected)
  g.setColor(1,1,1);g.print('<',14,47);g.print('>',294,47);g.printf(name(T.selected),33,47,252,'center')
  g.setColor(.65,.7,.73);g.printf('Réglage de tous les ennemis de ce type',12,70,296,'center')
  for i,f in ipairs(fields)do
   local yy=98+(i-1)*46;local v=c[f[1]];local text=i<=2 and math.floor(v*100+.5)..' %' or string.format('%+d px',v)
   g.setColor(.9,.9,.84);g.print(f[2],14,yy);g.printf(text,180,yy,123,'right')
   g.setColor(.2,.27,.3);g.rectangle('fill',18,yy+24,284,4)
   local knob=18+(v-f[3])/(f[4]-f[3])*284
   g.setColor(.93,.76,.38);g.rectangle('fill',knob-4,yy+18,8,16,2,2)
  end
  g.setColor(.18,.24,.26);g.rectangle('fill',12,292,142,27,4,4);g.rectangle('fill',166,292,142,27,4,4)
  g.setColor(1,1,1);g.printf('Réinitialiser ce type',12,299,142,'center');g.printf('Tout réinitialiser',166,299,142,'center')
  g.setColor(T.paused and .93 or .65,.8,.65);g.print(T.paused and '[x] Pause du test' or '[ ] Pause du test',14,331)
  g.setColor(.7,.72,.73);g.printf(App.hitboxTest and 'Non classé' or 'Session locale',183,331,120,'right')
 end
 g.pop()
end
function T.mousepressed(x,y,button)
 if App.state~='playing' or Replay.playing then return false end
 local ox,oy,s=T.layout();x=(x-ox)/s;y=(y-oy)/s
 if x<0 or x>320 or y<0 or y>(T.open and 364 or 34)then return false end
 if button~=1 then return true end
 if y<34 then T.open=not T.open;T.drag=nil;return true end
 T.collect()
 if y>=40 and y<70 then
  local index=1;for i,k in ipairs(T.keys)do if k==T.selected then index=i end end
  T.selected=T.keys[(index-1+(x<160 and -1 or 1))%#T.keys+1]
 elseif y>=292 and y<319 then T.reset(x>=160)
 elseif y>=325 then T.paused=not T.paused;T.markRun()
 else
  for i,f in ipairs(fields)do local yy=98+(i-1)*46
   if y>=yy+14 and y<=yy+40 then T.drag={key=T.selected,field=f};T.mousemoved(ox+x*s,oy+y*s);break end
  end
 end
 return true
end
function T.mousemoved(x,y)
 if not T.drag then return end
 local ox,oy,s=T.layout();local f=T.drag.field
 local v=f[3]+clamp(((x-ox)/s-18)/284,0,1)*(f[4]-f[3])
 if f[1]=='sx' or f[1]=='sy'then v=math.floor(v*100+.5)/100 else v=math.floor(v+.5)end
 T.set(T.drag.key,f[1],v)
end
function T.mousereleased()T.drag=nil end
function T.key(key)
 if key=='f3' and App.state=='playing' and not Replay.playing then T.open=not T.open;T.drag=nil;return true end
 return false
end
function T.blocked()return not Replay.playing and T.open and (T.paused or T.drag~=nil)end
function T.pointerOver()
 if App.state~='playing'then return false end
 local x,y=love.mouse.getPosition();local ox,oy,s=T.layout()
 return x>=ox and x<=ox+320*s and y>=oy and y<=oy+(T.open and 364 or 34)*s
end
return T
