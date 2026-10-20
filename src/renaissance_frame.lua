-- Near-camera forest silhouettes, composited over actors and below the HUD.
-- Local deterministic variation leaves the simulation RNG and collisions alone.
local F={}
local function noise(i,s)
 local n=math.sin(i*127.1+s*311.7)*43758.5453
 return n-math.floor(n)
end
local function curve(points)
 return love.math.newBezierCurve(points):render(4)
end
local function branch(points,width)
 local g=love.graphics;local path=curve(points)
 -- Broad cast shadow, dark bark, then a narrow moss-lit ridge.
 g.push();g.translate(3,4);g.setColor(.005,.015,.018,.24)
 g.setLineWidth(width+6);g.line(path);g.pop()
 g.setColor(.012,.027,.027);g.setLineWidth(width);g.line(path)
 g.setColor(.043,.072,.058);g.setLineWidth(width*.48);g.line(path)
 g.push();g.translate(-1,-1);g.setColor(.19,.24,.13,.45)
 g.setLineWidth(math.max(.7,width*.10));g.line(path);g.pop()
end
local function leaf(x,y,size,angle,lit)
 local g=love.graphics;g.push();g.translate(x,y);g.rotate(angle)
 local outline=curve({0,0,-size*.5,-size*.32,-size*.36,-size*.65,0,-size})
 local right=curve({0,-size,size*.34,-size*.67,size*.46,-size*.33,0,0})
 for i=3,#right-2 do outline[#outline+1]=right[i] end
 g.setColor(.009,.025,.026)
 g.polygon('fill',outline)
 if lit then
  g.setColor(.09,.15,.10,.85)
  local ridge=curve({0,-1,-size*.39,-size*.34,-size*.28,-size*.64,0,-size*.93})
  g.polygon('fill',ridge)
  g.setColor(.26,.33,.17,.48);g.setLineWidth(.7);g.line(0,-2,0,-size*.78)
 end
 g.pop()
end
local function vine(x,y,length,seed,scale)
 local g=love.graphics
 local bend=(noise(seed,3)-.5)*15
 branch({x,y,x+bend,y+length*.35,x-bend,y+length*.75,x+bend*.4,y+length},1.8*scale)
 for j=1,math.floor(length/9) do
  local t=j*9/length;local xx=x+math.sin(t*5)*bend*.45
  local size=(6+noise(j,seed)*6)*scale*(1-t*.4)
  leaf(xx,y+j*9,size,(j%2==0 and -1 or 1)*2.2,j%3~=0)
 end
end
local function fern(x,y,height,lean,seed)
 local g=love.graphics
 branch({x,y,x+lean*.1,y-height*.4,x+lean*.7,y-height*.8,x+lean,y-height},2.8)
 for j=1,7 do
  local t=j/8;local px=x+lean*t*t;local py=y-height*t
  local size=(8+height*.16)*math.sin(t*math.pi)*(.8+noise(j,seed)*.3)
  leaf(px,py,size,-1.12+t*.5,j%2==0)
  leaf(px,py,size,.95-t*.4,j%3==0)
 end
 leaf(x+lean,y-height,9,lean*.015,true)
end
local function web(x,y,sx,sy,size)
 local g=love.graphics;g.push();g.translate(x,y);g.scale(sx,sy)
 g.setLineWidth(.65)
 for ray=0,6 do
  local a=ray*math.pi/12
  g.setColor(.64,.73,.68,.22)
  g.line(0,0,math.cos(a)*size,math.sin(a)*size)
 end
 for ring=1,6 do
  local r=size*ring/6
  for ray=0,5 do
   local a,b=ray*math.pi/12,(ray+1)*math.pi/12
   local mx,my=math.cos((a+b)/2)*r*.93,math.sin((a+b)/2)*r*.93
   g.setColor(.62,.73,.68,.12+ring*.018)
   g.line(curve({math.cos(a)*r,math.sin(a)*r,mx,my,math.cos(b)*r,math.sin(b)*r}))
  end
 end
 g.pop()
end
function F.bake(width,height)
 local g=love.graphics;g.push('all');g.setShader();g.setLineStyle('smooth');g.setLineJoin('none')
 -- Broken canopy: long tendrils at the corners, short leaves above the HUD.
 for i=0,math.floor(width/29) do
  local x=i*29+noise(i,1)*18
  local corner=math.max(0,1-math.min(x,width-x)/180)
  local length=11+noise(i,2)*16+corner*36
  vine(x,-5,length,i+11,.85)
  leaf(x,6,13+noise(i,6)*9,1.1+noise(i,5)*2,true)
 end
 -- Roots wrap around both lower corners; irregular gaps keep the frame airy.
 for side=1,2 do
  g.push()
  if side==2 then g.translate(width,0);g.scale(-1,1) end
  branch({-8,height-8,16,height-65,4,height-111,12,height-164},12)
  branch({-8,height-9,49,height-37,68,height-13,116,height-24},11)
  branch({7,height-51,38,height-67,27,height-91,42,height-110},6)
  branch({8,3,26,57,7,104,14,151},8)
  for j=1,5 do
   local y=height-15-j*20
   leaf(9+noise(j,side)*8,y,15+noise(j,8)*12,.6+noise(j,9),j%2==0)
  end
  fern(28,height+5,76+side*9,22,side)
  fern(70,height+4,44,-17,side+4)
  fern(8,height-122,37,20,side+9)
  web(4,4,1,1,76+side*9)
  web(5,height-3,1,-1,69+side*7)
  g.pop()
 end
 for i=1,math.floor(width/74) do
  local x=i*74+noise(i,31)*27
  local h=27+noise(i,32)*38
  if i%3==0 then
   branch({x-30,height+5,x-18,height-28,x+13,height-26,x+28,height+4},7)
  end
  fern(x,height+8,h,(noise(i,33)-.5)*26,i+40)
  leaf(x-8,height-1,13+noise(i,34)*13,-.8,true)
 end
 g.pop()
end
function F.draw(alpha)
 if Campaign.biome~=3 or Secret.inArena() then return end
 local g=love.graphics;local target=g.getCanvas()
 local density=target and target:getDPIScale() or 1
 local key=Arena.width..':'..density
 if F.key~=key then
  if F.canvas then F.canvas:release() end
  F.canvas=g.newCanvas(Arena.width,600,{dpiscale=density})
  F.canvas:setFilter('linear','linear')
  g.push('all');g.setCanvas(F.canvas);g.origin();g.setScissor();g.setShader()
  g.setBlendMode('alpha','alphamultiply');g.clear(0,0,0,0)
  -- Enlarge the foliage inward while keeping its roots on the arena perimeter.
  local scale=1.5;g.scale(scale,scale)
  F.bake(Arena.width/scale,600/scale)
  g.pop();F.key=key
 end
 g.push('all');g.setShader();local a=alpha or 1;g.setColor(a,a,a,a)
 if Graphics.effects then
  F.shader=F.shader or g.newShader('assets/shaders/renaissance_foliage.glsl')
  F.shader:send('clock',UI.clock)
  F.shader:send('dimensions',{Arena.width,600})
  g.setShader(F.shader)
 end
 g.setBlendMode('alpha','premultiplied');g.draw(F.canvas);g.pop()
end
return F
