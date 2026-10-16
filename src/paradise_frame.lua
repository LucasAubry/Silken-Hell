-- Luminous cloud garden in front of actors, beneath the HUD.
local F={}
local function noise(i) local n=math.sin(i*127.1+311.7)*43758.5453;return n-math.floor(n) end
local function curve(points) return love.math.newBezierCurve(points):render(4) end
local function glow(x,y,size)
 local g=love.graphics
 for j=7,1,-1 do
  g.setColor(1,.80,.36,.012+(8-j)*.003)
  g.ellipse('fill',x,y,size*j/4,size*j/4)
 end
end
local function leaf(x,y,size,angle)
 local g=love.graphics;g.push();g.translate(x,y);g.rotate(angle)
 local p=curve({0,0,-size*.65,-size*.3,-size*.35,-size*.8,0,-size})
 local r=curve({0,-size,size*.4,-size*.7,size*.50,-size*.3,0,0})
 for i=3,#r do p[#p+1]=r[i] end
 g.setColor(.33,.46,.45);g.polygon('fill',p)
 g.setColor(.79,.80,.53);g.polygon('fill',curve({0,0,-size*.60,-size*.3,-size*.30,-size*.8,0,-size}))
 g.setColor(1,.94,.65,.8);g.setLineWidth(.7);g.line(0,0,0,-size*.88)
 g.pop()
end
local function sprig(x,y,height,lean)
 local g=love.graphics
 local stem=curve({x,y,x+lean*.1,y-height*.3,x+lean*.65,y-height*.8,x+lean,y-height})
 g.setColor(.26,.36,.34);g.setLineWidth(3);g.line(stem)
 g.setColor(.93,.80,.43);g.setLineWidth(1.1);g.line(stem)
 for j=1,4 do
  local t=j/5;local size=height*.24*math.sin(t*math.pi)
  leaf(x+lean*t*t,y-height*t,size,-.85)
  leaf(x+lean*t*t,y-height*t,size,.85)
 end
 local bx,by=x+lean,y-height
 glow(bx,by,9)
 for j=1,5 do
  g.push();g.translate(bx,by);g.rotate(j*math.pi*2/5)
  g.setColor(.63,.68,.55);g.ellipse('fill',0,-4.5,3.5,7)
  g.setColor(1,.96,.77);g.ellipse('fill',-.7,-5,2.5,5.8);g.pop()
 end
 g.setColor(1,.79,.28);g.circle('fill',bx,by,2.8)
 g.setColor(1,1,.9);g.circle('fill',bx-.5,by-.5,1.3)
end
local function feather(x,y,size,angle)
 local g=love.graphics;g.push();g.translate(x,y);g.rotate(angle)
 local p=curve({0,0,-size*.38,-size*.28,-size*.28,-size*.77,size*.12,-size})
 local r=curve({size*.12,-size,size*.36,-size*.66,size*.31,-size*.30,0,0})
 for j=3,#r do p[#p+1]=r[j] end
 g.setColor(.46,.62,.65);g.polygon('fill',p)
 g.setColor(.94,.97,.88);g.polygon('fill',curve({0,0,-size*.36,-size*.28,-size*.24,-size*.76,size*.12,-size}))
 g.setLineWidth(.7)
 for j=2,8 do
  local t=j/10;local w=math.sin(t*math.pi)*size*.19
  g.setColor(.69,.81,.78,.85);g.line(size*.1*t,-size*t,-w,-size*t-size*.13)
  g.setColor(1,.98,.82,.9);g.line(size*.1*t,-size*t,w,-size*t-size*.10)
 end
 g.setColor(1,.87,.50);g.setLineWidth(1);g.line(0,3,size*.12,-size*.93)
 g.pop()
end
local function crystal(x,y,size,angle)
 local g=love.graphics;g.push();g.translate(x,y);g.rotate(angle)
 glow(0,-size*.6,size*.45)
 g.setColor(.34,.53,.57);g.polygon('fill',-size*.21,0,-size*.24,-size*.65,0,-size,size*.23,-size*.62,size*.17,0)
 g.setColor(.67,.87,.87);g.polygon('fill',0,0,0,-size,size*.23,-size*.62,size*.17,0)
 g.setColor(1,.96,.75);g.setLineWidth(1);g.line(-size*.21,0,-size*.24,-size*.65,0,-size,0,0)
 g.pop()
end
local function lotus(x,y,size)
 local g=love.graphics;glow(x,y,size*.9)
 for layer=1,2 do
  for j=1,7 do
   g.push();g.translate(x,y);g.rotate(j*math.pi*2/7+layer*.35)
   local h=size*(layer==1 and 1 or .65)
   local p=curve({0,2,-h*.55,-h*.35,-h*.30,-h*.8,0,-h})
   local r=curve({0,-h,h*.30,-h*.8,h*.55,-h*.35,0,2})
   for k=3,#r do p[#p+1]=r[k] end
   g.setColor(layer==1 and {.62,.66,.78} or {.94,.85,.84});g.polygon('fill',p)
   g.setColor(1,.98,.88,.75);g.setLineWidth(.7);g.line(0,-1,0,-h*.85)
   g.pop()
  end
 end
 g.setColor(1,.82,.35);g.circle('fill',x,y,size*.22)
 g.setColor(1,1,.86);g.circle('fill',x-1,y-1,size*.10)
end
local function tallPlant(x,y,height,lean,bells)
 local g=love.graphics
 local stem=curve({x,y,x+lean*.05,y-height*.3,x+lean*.8,y-height*.75,x+lean,y-height})
 g.setColor(.27,.45,.41);g.setLineWidth(2.6);g.line(stem)
 g.setColor(.88,.91,.63);g.setLineWidth(.8);g.line(stem)
 for j=1,7 do
  local t=j/8;local px=x+lean*t*t;local py=y-height*t
  local size=height*(bells and .16 or .27)*math.sin(t*math.pi)
  if j%2==1 then
   leaf(px,py,size,-1.05+t*.3);leaf(px,py,size,.95-t*.25)
  end
  if bells and j%2==1 then
   local bx=px+(j%4==1 and -1 or 1)*size*.9
   glow(bx,py+2,5)
   g.setColor(.64,.69,.84);g.ellipse('fill',bx,py+2,4,6)
   g.setColor(.94,.94,1);g.ellipse('fill',bx-.7,py,2.7,4.5)
   g.setColor(1,.90,.50);g.ellipse('fill',bx,py+6,3.5,1.5)
  end
 end
 leaf(x+lean,y-height,12,lean*.01)
end
function F.bake(width,height)
 local g=love.graphics;F.stars={}
 for side=1,4 do
  local ox,oy,angle=0,height,0
  if side==2 then ox,oy,angle=width,0,math.pi
  elseif side==3 then ox,oy,angle=0,0,math.pi/2
  elseif side==4 then ox,oy,angle=width,height,-math.pi/2 end
  local length=side<=2 and width or height
  g.push();g.translate(ox,oy);g.rotate(angle);g.scale(1,1.18)
  for i=0,math.ceil(length/34) do
   local seed=side*307+i*13;local x=i*34+noise(seed)*10
   local depth=13+noise(seed+2)*15
   -- Overlapping cloud banks: blue-grey undersides and warm ivory rims.
   g.setColor(.16,.25,.29,.5);g.ellipse('fill',x+3,1,31,depth+7)
   g.setColor(.39,.50,.51,.95);g.ellipse('fill',x,6,29,depth+4)
   g.setColor(.64,.70,.64);g.ellipse('fill',x-3,3,26,depth)
   g.setColor(.85,.86,.72);g.ellipse('fill',x-6,-3,18,depth*.71)
   g.setColor(1,.96,.78,.65)
   g.setLineWidth(.85);g.line(curve({x-21,-depth*.20,x-16,-depth*.90,x,-depth*.96,x+10,-depth*.48}))
   local motif=(i+side*3)%10
   g.push();g.translate(0,8);g.translate(x,-8);g.scale(.85+noise(seed+36)*.22,.88+noise(seed+37)*.20);g.translate(-x,8)
   if motif==1 or motif==5 then
    sprig(x,-9,24+noise(seed+9)*26,(noise(seed+12)-.5)*24)
    if motif==5 then lotus(x+9,-depth-15,11) end
   elseif motif==2 then
    feather(x-8,-7,38+noise(seed+4)*17,-.38)
    feather(x+6,-8,30+noise(seed+5)*12,.35)
   elseif motif==3 then
    crystal(x-9,-depth*.7,24,-.32)
    crystal(x,-depth*.7,36,0)
    crystal(x+9,-depth*.7,21,.4)
   elseif motif==4 then
    leaf(x-4,-9,31,-.7);leaf(x+4,-9,28,.6)
    lotus(x,-depth-15,16+noise(seed+6)*5)
   elseif motif==6 then
    local cy=-depth-15;glow(x,cy,16)
    g.setColor(1,.82,.34,.7);g.setLineWidth(2);g.ellipse('line',x,cy,13,7)
    g.setColor(1,.98,.78,.85);g.setLineWidth(.8);g.ellipse('line',x,cy,16,10)
    feather(x,-7,27,.2)
   elseif motif==8 or motif==9 then
    tallPlant(x,-8,60+noise(seed+25)*16,(noise(seed+26)-.5)*27,motif==9)
    if motif==8 then lotus(x+9,-15,9) end
   elseif motif==7 then
    for j=1,3 do
     sprig(x+(j-2)*10,-8,18+noise(seed+j)*17,(j-2)*8)
    end
   end
   g.pop()
   local px,py=x,(-depth-17-noise(seed+20)*15)*1.18
   F.stars[#F.stars+1]={ox+px*math.cos(angle)-py*math.sin(angle),oy+px*math.sin(angle)+py*math.cos(angle),seed}
  end
  -- A foreground lip hides the stems where they enter the cloud wall.
  for i=0,math.ceil(length/34) do
   local seed=side*307+i*13;local x=i*34+noise(seed)*10
   local lip=13+noise(seed+2)*5
   g.setColor(.64,.70,.64);g.ellipse('fill',x-3,8,27,lip)
   g.setColor(.85,.86,.72);g.ellipse('fill',x-6,6,20,lip*.72)
  end
  g.pop()
 end
 -- Larger feather-and-flower nests anchor all four corners.
 for corner=1,4 do
  g.push();g.translate(corner%2==0 and width or 0,corner<=2 and height or 0)
  g.scale(corner%2==0 and -1 or 1,corner<=2 and 1.1 or -1.1)
  glow(38,-35,28)
  g.setColor(.44,.57,.58,.94);g.ellipse('fill',20,-15,46,33)
  g.setColor(.78,.82,.73,.95);g.ellipse('fill',14,-22,32,29)
  g.setColor(.96,.94,.78,.75);g.ellipse('fill',7,-33,22,20)
  g.push();g.translate(-5,8)
  feather(20,-14,74,.63);feather(12,-22,60,1.02)
  feather(36,-8,54,.20)
  leaf(16,-19,36,-.3)
  crystal(10,-35,31,.5);crystal(42,-8,26,.3)
  lotus(33,-31,20);lotus(16,-49,12);lotus(56,-13,11)
  glow(61,-53,14)
  g.setColor(1,.86,.47,.7);g.setLineWidth(1.5);g.ellipse('line',61,-53,14,6)
  g.pop()
  g.setColor(.64,.70,.64);g.ellipse('fill',16,3,34,16)
  g.setColor(.85,.86,.72);g.ellipse('fill',10,1,26,11)
  g.pop()
 end
end
function F.draw()
 if Campaign.biome~=1 or Secret.inArena() then return end
 local g=love.graphics;local target=g.getCanvas();local density=target and target:getDPIScale() or 1
 local key=Arena.width..':'..density
 if F.key~=key then
  if F.canvas then F.canvas:release() end
  F.canvas=g.newCanvas(Arena.width,600,{dpiscale=density});F.canvas:setFilter('linear','linear')
  g.push('all');g.setCanvas(F.canvas);g.origin();g.setScissor();g.setShader();g.setBlendMode('alpha','alphamultiply');g.clear(0,0,0,0)
  F.bake(Arena.width,600)
  -- Static soft focus is baked once, so actors stay sharp and frames stay cheap.
  F.blur=F.blur or g.newShader('assets/shaders/paradise_frame_blur.glsl')
  local soft=g.newCanvas(Arena.width,600,{dpiscale=density});soft:setFilter('linear','linear')
  g.setCanvas(soft);g.clear(0,0,0,0);g.setColor(1,1,1)
  g.setBlendMode('alpha','premultiplied');g.setShader(F.blur)
  F.blur:send('stepUV',{.15/Arena.width,0});g.draw(F.canvas)
  g.setCanvas(F.canvas);g.clear(0,0,0,0)
  F.blur:send('stepUV',{0,.15/600});g.draw(soft)
  g.pop();soft:release();F.key=key
 end
 g.push('all');g.setShader();g.setColor(1,1,1)
 if Graphics.effects then
  F.shader=F.shader or g.newShader('assets/shaders/renaissance_foliage.glsl')
  F.shader:send('clock',UI.clock*.7);F.shader:send('dimensions',{Arena.width,600});g.setShader(F.shader)
 end
 g.setBlendMode('alpha','premultiplied');g.draw(F.canvas)
 g.setShader();g.setBlendMode('alpha','alphamultiply');g.setLineWidth(.8)
 local time=Graphics.effects and UI.clock or 0
 for _,v in ipairs(F.stars) do
  local pulse=(.5+.5*math.sin(time*1.2+v[3]))^3
  local x,y=v[1],v[2]+math.sin(time*.65+v[3])*2
  g.setColor(1,.87,.48,.08+pulse*.18);g.circle('fill',x,y,4)
  g.setColor(1,.97,.78,.18+pulse*.72)
  g.line(x-2-pulse*2,y,x+2+pulse*2,y);g.line(x,y-3-pulse*2,x,y+3+pulse*2)
 end
 g.pop()
end
return F
