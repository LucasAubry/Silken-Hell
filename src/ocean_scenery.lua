-- Painted reef silhouettes baked once; only the water sway runs each frame.
local O={}
local function random(i,k)local n=math.sin(i*127.1+k*311.7)*43758.5453;return n-math.floor(n)end
local function frond(x,y,height,lean,color)
 local g=love.graphics;local points={}
 for j=0,9 do
  local t=j/9;local px=x+lean*t+math.sin(t*4)*height*.12;local py=y-height*t
  points[#points+1]=px;points[#points+1]=py
  if j>1 and j<9 then
   local side=j%2==0 and 1 or -1;local width=height*.17*math.sin(t*math.pi)
   g.setColor(color[1],color[2],color[3],.85)
   g.polygon('fill',px,py+3,px+side*width,py-4,px+side*width*.6,py-10,px+1,py-3)
  end
 end
 g.setColor(color[1]*1.15,color[2]*1.15,color[3]*1.15,.85);g.setLineWidth(1.3);g.line(points)
end
local function coral(x,y,size,pink,abyss,lit)
 local g=love.graphics;local c=abyss and {.16,.11,.25} or pink and {.40,.16,.45} or {.06,.45,.43}
 for branch=1,5 do
  local dx=(branch-3)*size*.22;local top=y-size*(.55+random(branch,x)*.45)
  g.setColor(c[1]*.5,c[2]*.5,c[3]*.5,1);g.setLineWidth(4)
  g.line(x,y,x+dx*.3,y-size*.3,x+dx,top)
  g.setColor(c[1],c[2],c[3],1);g.setLineWidth(2)
  g.line(x,y,x+dx*.3,y-size*.3,x+dx,top)
  g.line(x+dx*.65,y-size*.45,x+dx+size*.10,top+size*.14)
  if not abyss or lit and branch%2==0 then g.setColor(abyss and {.48,.40,.70,.65} or pink and {.87,.43,.70,.85} or {.30,.90,.77,.85});g.circle('fill',x+dx,top,abyss and .9 or 1.4) end
 end
end
function O.bake()
 local abyss=Campaign.biome==7
 local g=love.graphics;local target=g.getCanvas();local density=target and math.min(2,target:getDPIScale()) or 1
 local key=Campaign.biome..':'..Arena.width..':'..density
 if O.key==key then return end
 O.key=key;if O.canvas then O.canvas:release() end
 O.canvas=g.newCanvas(Arena.width,600,{dpiscale=density});O.canvas:setFilter('linear','linear')
 g.push('all');g.setCanvas(O.canvas);g.origin();g.setScissor();g.setShader();g.clear()
 -- Edge vegetation stays behind the collision wall and the playable actors.
 for side=1,4 do
  g.push()
  if side==2 then g.translate(Arena.width,600);g.rotate(math.pi)
  elseif side==3 then g.translate(0,600);g.rotate(-math.pi/2)
  elseif side==4 then g.translate(Arena.width,0);g.rotate(math.pi/2) end
  local length=side<=2 and Arena.width or 600
  for i=1,math.floor(length/42) do
   local x=18+i*42+random(i,side)*14
   local h=18+random(i,side+4)*26
   -- Inward-facing leaves establish a foreground frame without filling paths.
   g.push();g.translate(x,15);g.rotate(math.pi)
   frond(0,0,h,(random(i,7)-.5)*22,abyss and {.095,.07+random(i,2)*.05,.18} or {.025,.16+random(i,2)*.10,.22})
   if i%3==0 then coral(8,0,h*.70,i%2==0,abyss,i%9==0) end
   g.pop()
  end
  g.pop()
 end
 -- Four recognizable luminous reef clusters, paired with real light sources.
 if not abyss then
 for i=1,4 do
  local x,y=require('biome_radiance').coralPosition(i)
  local left=i%2~=0
  g.push();g.translate(left and 15 or Arena.width-15,y);g.rotate(left and math.pi/2 or -math.pi/2)
  coral(0,0,30+i%2*8,i%2==0)
  frond(-7,0,38,-12,{.04,.29,.32});g.pop()
 end
 for i=1,80 do
  local x=30+random(i,11)*(Arena.width-60);local y=35+random(i,12)*530
  g.setColor(.24,.48,.47,.12);g.ellipse('fill',x,y,1.5+random(i,13)*2,.7)
 end
 end
 g.pop()
end
function O.draw()
 if (Campaign.biome~=4 and Campaign.biome~=7) or Secret.inArena() then return end
 O.bake();local g=love.graphics
 O.shader=O.shader or g.newShader('assets/shaders/ocean_fronds.glsl')
 O.shader:send('clock',Graphics.effects and UI.clock or 0);O.shader:send('dimensions',{Arena.width,600})
 g.push('all');g.setShader(O.shader);g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(O.canvas);g.pop()
end
return O
