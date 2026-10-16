-- Near-camera cave rim. Stone stays still; mushrooms sway from their bases.
local F={}
local function noise(i) local n=math.sin(i*127.1+311.7)*43758.5453;return n-math.floor(n) end
local function mushroom(x,y,size,angle,seed,time)
 local g=love.graphics;g.push();g.translate(x,y)
 g.rotate(angle+math.sin(time*.85+seed)*.035)
 local h=size;local w=size*.56
 g.setColor(.025,.018,.014,.5);g.ellipse('fill',3,3,w*.65,5)
 g.setColor(.18,.16,.12);g.polygon('fill',-h*.10,0,h*.12,0,h*.05,-h*.77,-h*.07,-h*.77)
 g.setColor(.51,.45,.30);g.polygon('fill',-h*.07,0,0,0,-h*.01,-h*.75,-h*.07,-h*.75)
 g.setColor(.08,.055,.035);g.ellipse('fill',0,-h*.72,w,w*.27)
 g.setColor(.48,.32,.15);g.ellipse('fill',0,-h*.75,w*.94,w*.20)
 g.setLineWidth(.7);g.setColor(.77,.58,.29,.45)
 for j=-3,3 do g.line(0,-h*.68,j*w*.24,-h*.78) end
 g.setColor(.20,.12,.062)
 g.polygon('fill',-w,-h*.77,-w*.72,-h*.98,-w*.23,-h*1.10,w*.30,-h*1.07,w*.77,-h*.94,w,-h*.77)
 g.setColor(.48,.29,.12)
 g.polygon('fill',-w,-h*.77,-w*.72,-h*.98,-w*.23,-h*1.10,w*.30,-h*1.07,w*.12,-h*.92)
 g.setColor(.73,.50,.24,.8);g.line(-w*.79,-h*.91,-w*.23,-h*1.075,w*.29,-h*1.05)
 for j=1,5 do
  local xx=(noise(seed+j)-.5)*w*1.1
  g.setColor(.78,.64,.37,.6);g.ellipse('fill',xx,-h*(.85+noise(seed+j*7)*.16),h*.035,h*.022)
 end
 g.pop()
end
local function crystal(x,y,size,angle,seed,time)
 local g=love.graphics;g.push();g.translate(x,y);g.rotate(angle)
 local pulse=.5+.5*math.sin(time*.8+seed)
 g.setColor(.10,.19,.18);g.polygon('fill',-size*.24,0,-size*.30,-size*.66,0,-size,size*.26,-size*.68,size*.20,-2)
 g.setColor(.27,.42,.36);g.polygon('fill',0,-size,size*.26,-size*.68,size*.20,-2,0,-size*.12)
 g.setColor(.50,.62,.43);g.polygon('fill',0,-size,-size*.30,-size*.66,-size*.24,0,0,-size*.12)
 g.setColor(.77,.82,.53,.35+pulse*.45);g.setLineWidth(1);g.line(-size*.29,-size*.66,0,-size,0,-size*.12)
 g.setColor(.88,.86,.55,.1+pulse*.45);g.circle('fill',0,-size*.83,1.4)
 g.pop()
end
function F.bake(width,height)
 local g=love.graphics;local R=require('earth_rocks');F.mushrooms={};F.crystals={}
 local function cluster(x,y,angle,seed,large)
  g.push();g.translate(x,y);g.rotate(angle)
  local size=large and 1.5 or 1
  R.rock(-28*size,-19*size,57*size,37*size,seed)
  R.rock(-8*size,-33*size,31*size,29*size,seed+3)
  for j=1,3 do
   local px=(j-2)*17*size;local py=-15*size
   local wx=x+px*math.cos(angle)-py*math.sin(angle)
   local wy=y+px*math.sin(angle)+py*math.cos(angle)
   F.crystals[#F.crystals+1]={wx,wy,(16+noise(seed+j)*17)*size,angle+(j-2)*.35,seed+j}
  end
  g.pop()
  for j=1,2 do
   local px=(j==1 and -35 or 27)*size;local py=2
   F.mushrooms[#F.mushrooms+1]={x+px*math.cos(angle)-py*math.sin(angle),y+px*math.sin(angle)+py*math.cos(angle),(25+noise(seed+j*9)*22)*size,angle+(j==1 and -.16 or .2),seed+j*11}
  end
 end
 for i=0,math.floor(width/145) do
  local x=25+i*145+noise(i+4)*30
  cluster(x,height-4,0,40+i,i==0 or x>width-150)
 end
 -- Sparse ceiling fragments leave the timer and buttons clear.
 for _,x in ipairs({16,width-16}) do cluster(x,0,math.pi,math.floor(x)+90,false) end
 for side=1,2 do
  for j=1,3 do
   cluster(side==1 and 1 or width-1,115+j*106+(side-1)*27,side==1 and math.pi/2 or -math.pi/2,side*100+j,j==3)
  end
 end
end
function F.draw()
 if Campaign.biome~=5 or Secret.inArena() then return end
 local g=love.graphics;local target=g.getCanvas();local density=target and target:getDPIScale() or 1
 local key=Arena.width..':'..density
 if F.key~=key then
  if F.canvas then F.canvas:release() end
  F.canvas=g.newCanvas(Arena.width,600,{dpiscale=density});F.canvas:setFilter('linear','linear')
  g.push('all');g.setCanvas(F.canvas);g.origin();g.setScissor();g.setShader();g.setBlendMode('alpha','alphamultiply');g.clear(0,0,0,0)
  F.bake(Arena.width,600);g.pop();F.key=key
 end
 g.push('all');g.setShader();g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(F.canvas)
 g.setBlendMode('alpha','alphamultiply');g.setLineStyle('smooth');g.setLineJoin('none')
 local time=Graphics.effects and UI.clock or 0
 for _,v in ipairs(F.crystals) do crystal(v[1],v[2],v[3],v[4],v[5],time) end
 for _,v in ipairs(F.mushrooms) do mushroom(v[1],v[2],v[3],v[4],v[5],time) end
 g.pop()
end
return F
