-- Self-contained dioramas: shared game art, deterministic motion, no combat updates.
local P={entries={}}
local g=love.graphics
local function glow(x,y,r,color,alpha)
 g.push('all');g.setBlendMode('add')
 for i=10,1,-1 do g.setColor(color[1],color[2],color[3],alpha*(1-i/11)/9);g.circle('fill',x,y,r*i/10) end
 g.pop()
end
local function mob(id,x,y,size,t)
 local e=P.entries[id];assert(e and not e.boss,'World previews only show ordinary creatures')
 P.poses=P.poses or {}
 local p=P.poses[id];local dir=p and Art.direction(x-p.x,y-p.y,p.dir) or 'down'
 P.poses[id]={x=x,y=y,dir=dir}
 require('bestiary_animation').draw(e,x,y,size,t,dir)
end
local function motes(t,color,count,up)
 for i=1,count do
  local x=(i*97.7+math.sin(t*.6+i)*12)%680;local y=(i*61.3-t*up)%300
  local a=.35+.25*math.sin(t*1.8+i)
  glow(x,y,7,color,a*.5);g.setColor(color[1],color[2],color[3],a);g.circle('fill',x,y,1+i%3*.5)
 end
end
function P.fishPose(t,i,yellow)
 local speed=yellow and 155 or 115;local distance=(t*speed+i*237)%860
 local reverse=i%2==0
 local f={yellow=yellow,originX=reverse and 770 or -90,originY=yellow and 190 or 85+i*17,heading=reverse and math.pi or 0,phase=i*.8,distance=0}
 local project=require('mobs.bosses.abyss.charged_fish').project
 if not yellow then return f.originX+(reverse and -distance or distance),f.originY,f.heading end
 local x,y=project(f,distance);local nx,ny=project(f,distance+1)
 return x,y,math.atan2(ny-y,nx-x)
end
local function abyss(t)
 glow(350+math.sin(t*.4)*135,145,260,{.08,.45,1},.28)
 for i=1,4 do
  local yellow=i>2;local x,y,angle=P.fishPose(t,i,yellow)
  g.setColor(.66,.78,.94,.94);Art.draw('abyss_fish',x,y,100,angle)
  local a=Art.images.abyss_fish;local h=100*a.h/a.w
  local ex=x+math.cos(angle)*30+math.sin(angle)*h*.07
  local ey=y+math.sin(angle)*30-math.cos(angle)*h*.07
  local color=yellow and {1,.9,.12} or {1,.08,.03}
  glow(ex,ey,23,color,.8);g.setColor(color);g.circle('fill',ex,ey,2.8)
 end
 local jx,jy=340+math.sin(t*.4)*60,125+math.sin(t)*14
 glow(jx,jy,115,{.1,.65,1},.4);mob('light_jelly',jx,jy,100,t)
 motes(t,{.18,.7,1},70,8)
end
local function burrow(kind,x,y,size,age)
 local phase,amount
 if kind=='mole' then phase,amount=Realms.molePhase(age) else phase,amount=Realms.wormPhase(age) end
 require('earth_mound').draw(x,y+size*.25,size*.95,size*.45)
 if phase~='hidden' and phase~='warning' then
  g.setColor(1,1,1)
  if phase=='dig' or phase=='emerge' then Art.drawBurrowing(kind,'down',x,y,size,amount)
  elseif kind=='worm' then Art.drawWorm('left',x,y,size,age)
  else Art.drawFacing(kind,'down',x,y,size) end
 end
 if phase~='surface' then
  for j=1,13 do local a=j*2.4;local travel=(age*2+j*.13)%1;local r=10+travel*size*.42
   g.setColor(.42+j%3*.06,.27,.13,.8*(1-travel));g.circle('fill',x+math.cos(a)*r,y+size*.3+math.sin(a)*r*.35-math.sin(travel*math.pi)*15,2+j%3)
  end
 end
end
local function earth(t)
 glow(340,145,260,{.66,.38,.13},.16)
 burrow('mole',155,105,100,t+.8);burrow('mole',530,210,82,t+3)
 burrow('worm',445,95,125,t+1.9)
 local shot=((t+1.9)%4)-1.65
 if shot>0 and shot<1.55 then
  for i=-1,1 do local x=405-shot*185;local y=95+i*shot*40
   g.setColor(.24,.12,.09);g.ellipse('fill',x,y,7,6)
   g.setColor(.96,.72,.53);g.circle('fill',x,y-1,5)
   g.setColor(1,.94,.75);g.circle('fill',x-1,y-3,2)
  end
 end
 Art.drawWorm('right',235+math.sin(t)*22,235,45,t)
 motes(t,{.66,.46,.22},22,3)
end
local function ocean(t)
 for i=1,3 do
  local phase=t%3
  local distance=math.floor(t/3)*(2.3*13+.7*440)+math.min(phase,2.3)*13+math.max(0,phase-2.3)*440
  local x=(distance+i*42)%840-80;local y=115+math.abs(i-2)*24
  g.setColor(1,1,1);Art.drawFacing('fish','right',x,y,76)
 end
 local x,y=445+math.sin(t*.6)*35,175+math.sin(t*1.2)*20
 glow(x,y,120,{.13,.65,1},.4);mob('jelly',x,y,105,t)
 local charge=t%3.5
 if charge>2.3 then for i=1,8 do
  local a=i*math.pi/4;local r=35+(charge-2.3)*95
  require('abyss_light_fx').bolt({x=x+math.cos(a)*r,y=y+math.sin(a)*r,vx=math.cos(a),vy=math.sin(a),seed=i},t)
 end end
 local route=(t*72)%260;local right=route<130
 local cx=115+(right and route or 260-route)
 g.setColor(1,1,1);Art.draw(math.floor(t*6)%2==0 and 'crab_open' or 'crab_closed',cx,239,85,right and -math.pi/2 or math.pi/2)
 for i=1,18 do g.setColor(.55,.88,1,.3);g.circle('line',(i*97)%680,(i*59-t*19)%300,2+i%4) end
end
local function sky(t)
 require('mobs.cloud_beast').art(230+math.sin(t)*55,240,65,t,-math.pi/2)
 local x=(t*125)%860-90
 require('sky_insect_art').draw('wind_bat',x,75,76,t,-math.pi/2)
 local points={}
 for i=18,0,-1 do local age=t-i*.035;points[#points+1]=340+math.sin(age*.9)*185;points[#points+1]=180+math.sin(age*2.7)*43 end
 g.setColor(.25,.7,1,.4);g.setLineWidth(4);g.line(points);g.setColor(.65,.93,1,.9);g.setLineWidth(1);g.line(points)
 local dx,dy=340+math.sin(t*.9)*185,180+math.sin(t*2.7)*43
 require('sky_insect_art').draw('dragonfly',dx,dy,77,t,math.atan2(math.cos(t*2.7)*116.1,math.cos(t*.9)*166.5)-math.pi/2)
 require('tornado_art').draw(Art,560,165,t,100)
 glow(dx,dy,50,{.2,.65,1},.25)
end
local function paradise(t)
 glow(290+math.sin(t*.3)*120,115,230,{1,.85,.42},.25)
 mob('ange',220+math.sin(t*.65)*55,128+math.cos(t*.65)*23,102,t)
 mob('snake',450+math.sin(t*.5)*60,200+math.sin(t*1.2)*20,100,t)
 motes(t,{1,.9,.54},36,13)
end
local function hell(t)
 mob('lava',160,223,190,t);mob('lava',565,80,125,t)
 glow(160,220,150,{1,.21,.025},.35)
 require('sky_insect_art').draw('lava_scorpion',360+math.sin(t*.7)*95,155+math.sin(t*1.1)*35,115,t,math.atan2(math.cos(t*1.1)*38.5,math.cos(t*.7)*66.5)-math.pi/2)
 mob('magma_larva',190+math.sin(t*.8)*45,90+math.sin(t)*20,68,t)
 mob('spinner',530+math.sin(t)*35,235,75,t)
 motes(t,{1,.36,.055},35,32)
end
function P.updateBabies(t)
 if not P.babies or t<(P.babyTime or 0) then
  P.babies={}
  for i=1,6 do P.babies[i]={x=90+i*75,y=70+(i%3)*75,seed=i,walkPhase=i,angle=0} end
  P.babyTime=t
 end
 local elapsed=math.min(.1,math.max(0,t-P.babyTime));P.babyTime=t
 local steps=math.max(1,math.ceil(elapsed*60));local dt=elapsed/steps
 for _=1,steps do
  local targetX,targetY=340+math.sin(t*.8)*220,150+math.cos(t*1.1)*90
  for _,b in ipairs(P.babies) do
   local tx,ty=targetX,targetY
   for _,other in ipairs(P.babies) do if other~=b then
    local dx,dy=b.x-other.x,b.y-other.y;local d=math.sqrt(dx*dx+dy*dy)
    if d>0 and d<30 then tx=tx+dx/d*(30-d)*2;ty=ty+dy/d*(30-d)*2 end
   end end
   local dx,dy=tx-b.x,ty-b.y;local d=math.sqrt(dx*dx+dy*dy)
   local travel=math.min(d,(120+(b.seed%5)*9)*dt)
   if d>0 then
    b.x=math.max(35,math.min(645,b.x+dx/d*travel));b.y=math.max(35,math.min(265,b.y+dy/d*travel))
    b.angle=math.atan2(dy,dx)-math.pi/2
   end
   require('brown_walk').advance(b,travel,dt)
  end
 end
 return P.babies
end
local function renaissance(t)
 for i,b in ipairs(P.updateBabies(t)) do
  local variant=({'baby_red','baby_white','baby_black'})[(i-1)%3+1]
  g.setColor(1,1,1);require('final_art').spider(variant,b.x,b.y,36,b.angle,b)
 end
 -- Threads catch the green light without obscuring the miniature.
 g.setColor(.65,.8,.66,.2);g.setLineWidth(1)
 for i=1,6 do g.line(0,0,60+i*50,300);g.line(680,0,680-i*45,300) end
 glow(330,160,230,{.25,.65,.35},.18);motes(t,{.6,1,.68},28,6)
end
local function sanctuary(t)
 g.push('all');g.translate(340,-12);g.scale(.58)
 require('sanctuary_scene').emptyThrone(0,{.58,.67,.82})
 g.pop()
 glow(340,115,160,{.48,.61,1},.28+.06*math.sin(t*1.2))
 motes(t,{.65,.77,1},40,9)
end
local scenes={[1]=paradise,[2]=hell,[3]=renaissance,[4]=ocean,[5]=earth,[6]=sky,[7]=abyss}
function P.revealed(world)
 return Worlds.canEnter(world)
end
function P.draw(world,x,y,w,h,hardcore)
 if next(P.entries)==nil then for _,e in ipairs(Bestiary.entries) do P.entries[e.id]=e end end
 local biome=world==8 and 3 or world
 local time=Graphics.effects and UI.clock or 2.8
 P.scene=P.scene or g.newCanvas(680,300);P.scene:setFilter('linear','linear')
 g.push('all');g.setCanvas(P.scene);g.origin();g.setScissor();g.clear();g.setShader();g.setColor(1,1,1)
 if world==8 then
  g.push('all');g.scale(680/Arena.width,.5)
  require('sanctuary_scene').hall(hardcore)
  g.pop()
 else require('biome_floor').draw(biome,680,300,time) end
 if world==8 or P.revealed(world) then require('biome_radiance').preview(world,time) end
 if world==8 then sanctuary(time)
 elseif not P.revealed(world) then
  require('reached_level_preview').border(world)
  P.mysteryFont=P.mysteryFont or g.newFont(190)
  local font=P.mysteryFont;local tx=(680-font:getWidth('?'))/2
  local ty=(300-font:getHeight())/2-10
  glow(340,150,125,{.65,.48,1},.3+.06*math.sin(time*1.4))
  g.setFont(font);g.setColor(.04,.015,.09,.9);g.print('?',tx+3,ty+5)
  g.setColor(.96,.89,1);g.print('?',tx,ty)

 else
  if scenes[world] then scenes[world](time) end
  require('reached_level_preview').border(world)
 end
 g.pop()
 g.push('all');g.setShader();g.setColor(1,1,1);g.draw(P.scene,x,y,0,w/680,h/300)
 local c=hardcore and {1,.38,.23} or Worlds.color(biome).tear
 g.setColor(c[1],c[2],c[3],.55);g.setLineWidth(1);g.rectangle('line',x,y,w,h)
 for _,xx in ipairs({x,x+w}) do for _,yy in ipairs({y,y+h}) do
  local sx=xx==x and 1 or -1;local sy=yy==y and 1 or -1
  g.setColor(.96,.86,.62,.9);g.line(xx,yy+sy*12,xx,yy,xx+sx*12,yy)
 end end
 g.pop()
end
return P
