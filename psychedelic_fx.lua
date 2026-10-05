-- Presentation only: no gameplay RNG, timers, movement or collision changes.
local F={clock=0,pickupScale=.45}
local Palette=require 'prism_palette'
local tau=math.pi*2
local strengths={[0]=0,[1]=.45,[2]=1}
local pulses={'deathPulse','pickupPulse'}
function F.strength() return strengths[Graphics.psychedelic or 2] or 1 end
function F.load()
 F.shader=love.graphics.newShader(love.filesystem.read('assets/prism_palette.glsl')..love.filesystem.read('hyper_demon_shader.glsl'))
 F.deathShader=love.graphics.newShader('assets/respawn_legacy.glsl')
end
function F.reset() F.deathPulse=nil;F.pickupPulse=nil;F.clock=0 end
function F.death(x,y)
 if Replay and Replay.ghost then return end
 F.deathPulse={x=x,y=y,age=0,duration=.3,palette=Palette.player()};F.pickupPulse=nil
end
function F.collect(x,y,targetX,targetY)
 if Replay and Replay.ghost then return end
 F.pickupPulse={x=x,y=y,age=0,duration=.95,palette=Palette.get(),targetX=targetX or player.x+15,targetY=targetY or player.y+12}
end
function F.update(dt)
 F.clock=F.clock+dt
 for _,key in ipairs(pulses) do
  local p=F[key]
  if p then p.age=p.age+dt;if p.age>=p.duration then F[key]=nil end end
 end
end
local function pulse(p)
 if not p then return 0 end
 local t=p.age/p.duration
 return math.min(1,t/.06)*(1-t)^1.6
end
function F.active() return F.deathPulse~=nil or (F.strength()>0 and F.pickupPulse~=nil) end
function F.bind()
 if not F.active() then return false end
 if F.deathPulse then
  F.deathShader:send('time',UI.clock)
  F.deathShader:send('screen_size',{Arena.width,Arena.height})
  love.graphics.setShader(F.deathShader);return true
 end
 local s=F.shader;local d,c=F.deathPulse,F.pickupPulse
 Palette.send(s,Palette.player())
 Palette.send(s,d and d.palette or Palette.player(),'death_palette_')
 Palette.send(s,c and c.palette or Palette.player(),'pickup_palette_')
 s:send('time',F.clock);s:send('screen_size',{Arena.width,Arena.height})
 s:send('focus',{(player.x+15)/Arena.width,(player.y+12)/Arena.height})
 s:send('velocity',{0,1});s:send('speed',0)
 s:send('surge_amount',0)
 s:send('death_center',{d and d.x/Arena.width or .5,d and d.y/Arena.height or .5})
 s:send('pickup_center',{c and c.x/Arena.width or .5,c and c.y/Arena.height or .5})
 s:send('death_amount',pulse(d));s:send('pickup_amount',pulse(c))
 s:send('death_progress',d and d.age/d.duration or 0)
 s:send('pickup_progress',c and c.age/c.duration or 0)
 s:send('death_scale',1);s:send('pickup_scale',F.pickupScale)
 s:send('intensity',F.strength())
 love.graphics.setShader(s);return true
end
local function spectrum(phase,alpha,biome)
 local r,g,b=Palette.sample(phase/tau,biome or Palette.player())
 love.graphics.setColor(r,g,b,alpha)
end
-- The source and destination belong to the collection event, not the next level.
local function silk(p)
 local g=love.graphics;local t=math.min(1,p.age/.65)
 if t>=1 then return end
 local count=Graphics.quality==1 and 5 or 8
 local fade=math.min(1,t*12)*(1-t)^.55*F.strength()
 for i=1,count do
  local a=i/count*tau;local reach=25+(i%3)*7
  local sx,sy=p.x+math.cos(a)*9,p.y+math.sin(a)*12
  local cx,cy=p.x+math.cos(a+.7)*reach,p.y+math.sin(a+.7)*reach
  local bx,by=p.targetX+math.cos(a+1.6)*reach*.6,p.targetY+math.sin(a+1.6)*reach*.6
  local points={};local head=math.min(1,t*1.5+.12);local tail=math.min(1,math.max(0,t*1.5-.38))
  for j=0,16 do
   local u=tail+(head-tail)*j/16;local v=1-u
   points[#points+1]=v^3*sx+3*v*v*u*cx+3*v*u*u*bx+u^3*p.targetX
   points[#points+1]=v^3*sy+3*v*v*u*cy+3*v*u*u*by+u^3*p.targetY
  end
  spectrum(a+t*2,fade*.15,p.palette);g.setLineWidth(3);g.line(points)
  spectrum(a+t*2,fade*.9,p.palette);g.setLineWidth(.9);g.line(points)
  g.circle('fill',points[#points-1],points[#points],1.2*(1-t))
 end
end
local function seal(p)
 local g=love.graphics;local t=p.age/p.duration
 local close=math.max(0,(t-.28)/.72);close=close*close*(3-2*close)
 local radius=(14+30*math.min(1,t/.20))*(1-close)
 local fade=math.min(1,t/.12)*(1-t)^.55*F.strength()
 local spokes=8;local segments=Graphics.quality==1 and 4 or 8
 g.push();g.translate(p.x,p.y);g.rotate(-.12*close)
 -- Eight radial anchors, joined by concave silk strands, close into a small seal.
 for i=1,spokes do
  local a=i/spokes*tau;local grow=math.min(1,math.max(0,t*7-i*.055))
  spectrum(a+t,fade*.58,p.palette);g.setLineWidth(.8)
  g.line(math.cos(a)*radius*.08,math.sin(a)*radius*.08,math.cos(a)*radius*grow,math.sin(a)*radius*grow)
  for ring=1,3 do
   local points={};local r=radius*ring/3*grow
   for j=0,segments do
    local u=j/segments;local angle=a+u*tau/spokes
    local bowed=r*(1-.16*math.sin(u*math.pi))
    points[#points+1]=math.cos(angle)*bowed;points[#points+1]=math.sin(angle)*bowed
   end
   spectrum(a+ring*.7+t,fade*(ring==3 and .8 or .55),p.palette)
   g.setLineWidth(ring==3 and 1.1 or .65);g.line(points)
  end
  spectrum(a+t,fade*.8,p.palette);g.circle('fill',math.cos(a)*radius*grow,math.sin(a)*radius*grow,1.2)
 end
 if close>.55 then
  spectrum(t*tau,fade*.75,p.palette);g.circle('fill',0,0,1.5+2*math.sin(close*math.pi))
 end
 g.pop()
end
function F.draw()
 if F.strength()<=0 or not F.pickupPulse or F.deathPulse then return end
 local g=love.graphics;g.push('all');g.setShader();g.setBlendMode('alpha')
 seal(F.pickupPulse);silk(F.pickupPulse)
 g.pop()
end
return F
