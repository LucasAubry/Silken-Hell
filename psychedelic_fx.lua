-- Presentation only: no gameplay RNG, timers, movement or collision changes.
local F={speed=0,clock=0,vx=0,vy=1}
local Palette=require 'prism_palette'
local tau=math.pi*2
local strengths={[0]=0,[1]=.45,[2]=1}
local pulses={'deathPulse','pickupPulse'}
function F.strength() return strengths[Graphics.psychedelic or 2] or 1 end
function F.load() F.shader=love.graphics.newShader(love.filesystem.read('assets/prism_palette.glsl')..love.filesystem.read('hyper_demon_shader.glsl')) end
function F.resetMotion() F.speed=0;F.vx=0;F.vy=1 end
function F.reset() F.resetMotion();F.deathPulse=nil;F.pickupPulse=nil;F.clock=0 end
function F.death(x,y)
 if Replay and Replay.ghost then return end
 F.deathPulse={x=x,y=y,age=0,duration=.72,biome=Palette.current()};F.pickupPulse=nil;F.resetMotion()
end
function F.collect(x,y)
 if Replay and Replay.ghost then return end
 F.pickupPulse={x=x,y=y,age=0,duration=.85,biome=Palette.current()}
end
function F.update(dt)
 F.clock=F.clock+dt
 for _,key in ipairs(pulses) do
  local p=F[key]
  if p then p.age=p.age+dt;if p.age>=p.duration then F[key]=nil end end
 end
 F.speed=F.speed*math.exp(-dt*7)
end
function F.motion(dx,dy,dt)
 if dt<=0 then return end
 local distance=math.sqrt(dx*dx+dy*dy)
 local target=player.dashing and math.min(1,math.max(0,(distance/dt-310)/230)) or 0
 if Abyss and Abyss.playerHidden() then target=0 end
 F.speed=F.speed+(target-F.speed)*(1-math.exp(-dt*18))
 if distance>.01 then F.vx=dx/distance;F.vy=dy/distance end
end
local function pulse(p)
 if not p then return 0 end
 local t=p.age/p.duration
 return math.min(1,t/.06)*(1-t)^1.6
end
function F.active() return F.strength()>0 and (F.speed>.015 or F.deathPulse or F.pickupPulse) end
function F.bind()
 if not F.active() then return false end
 local s=F.shader;local d,c=F.deathPulse,F.pickupPulse
 Palette.send(s)
 Palette.send(s,d and d.biome,'death_palette_')
 Palette.send(s,c and c.biome,'pickup_palette_')
 s:send('time',F.clock);s:send('screen_size',{Arena.width,Arena.height})
 s:send('focus',{(player.x+15)/Arena.width,(player.y+12)/Arena.height})
 s:send('velocity',{F.vx,F.vy});s:send('speed',F.speed)
 s:send('death_center',{d and d.x/Arena.width or .5,d and d.y/Arena.height or .5})
 s:send('pickup_center',{c and c.x/Arena.width or .5,c and c.y/Arena.height or .5})
 s:send('death_amount',pulse(d));s:send('pickup_amount',pulse(c))
 s:send('death_progress',d and d.age/d.duration or 0)
 s:send('pickup_progress',c and c.age/c.duration or 0)
 s:send('intensity',F.strength())
 love.graphics.setShader(s);return true
end
local function spectrum(phase,alpha,biome)
 local r,g,b=Palette.sample(phase/tau,biome)
 love.graphics.setColor(r,g,b,alpha)
end
function F.ghostColor(age,alpha) spectrum(F.clock*3-age*15,alpha) end
local function burst(p,death)
 if not p then return end
 local g=love.graphics;local t=p.age/p.duration;local fade=pulse(p)*F.strength()
 local radius=death and (22+210*t^.65) or (18+108*math.abs(1-t*2.8))
 local count=Graphics.quality==1 and 12 or 24
 g.push();g.translate(p.x,p.y)
 -- Interlocking halos, followed by crystalline fragments.
 for ring=1,3 do
  local points={};local segments=Graphics.quality==1 and 32 or 64
  for i=0,segments do
   local a=i/segments*tau
   local r=radius*(.74+ring*.14)*(1+(death and .13 or .035)*math.sin(a*(death and 3 or 6)+t*8+ring))
   points[#points+1]=math.cos(a)*r;points[#points+1]=math.sin(a)*r*(death and .8 or .65)
  end
  spectrum(ring*2+t*(death and -5 or 5),fade*.8,p.biome)
  g.setLineWidth(ring==2 and 2.5 or 1);g.line(points)
 end
 for i=1,count do
  local a=i/count*tau+(death and t*.6 or -t*.85)
  local r=death and (30+(85+i%5*24)*t^.65) or (12+(75+i%4*14)*(1-math.min(1,t*2.5))+(math.max(0,t-.4)*150))
  local x,y=math.cos(a)*r,math.sin(a)*r
  local size=(death and 7 or 5)*(1-t)+2
  g.push();g.translate(x,y);g.rotate(a+t*2)
  local r,green,b=Palette.sample(a/tau,p.biome)
  g.setColor(r*.055,green*.055,b*.055,fade*.55);g.polygon('fill',-size*2,0,0,-size*.55,size*2,0,0,size*.55)
  spectrum(a+t*7,fade*.5,p.biome);g.polygon('fill',-size*2,0,0,-size*.55,size*2,0)
  spectrum(a+t*7,fade*.85,p.biome);g.polygon('line',-size*2,0,0,-size*.55,size*2,0,0,size*.55)
  g.setColor(.75+r*.25,.75+green*.25,.75+b*.25,fade*.65);g.line(-size,0,size,0);g.pop()
 end
 g.pop()
end
function F.draw()
 if not F.active() then return end
 local g=love.graphics;g.push('all');g.setShader();g.setBlendMode('alpha')
 local speed=F.speed*F.strength()
 if App.state=='playing' and speed>.025 and not Abyss.playerHidden() then
  local x,y=player.x+15,player.y+12
  for side=-1,1,2 do for i=1,4 do
   local phase=(F.clock*2.4+i*.23)%1
   local back=24+phase*135;local width=17+i*7
   local px=x-F.vx*back-F.vy*width*side;local py=y-F.vy*back+F.vx*width*side
   spectrum(i*1.8+F.clock*3,speed*(1-phase)*.55);g.setLineWidth(1.5)
   g.line(px,py,px-F.vx*(16+speed*35),py-F.vy*(16+speed*35))
  end end
 end
 burst(F.deathPulse,true);burst(F.pickupPulse,false)
 g.pop()
end
return F
