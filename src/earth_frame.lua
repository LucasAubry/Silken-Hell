-- Near-camera cave rim. Stone stays still; mushrooms sway from their bases.
local F={}
local function noise(i) local n=math.sin(i*127.1+311.7)*43758.5453;return n-math.floor(n) end
local function curve(points) return love.math.newBezierCurve(points):render(5) end
local function mushroom(x,y,size,angle,seed,time)
 local g=love.graphics;g.push();g.translate(x,y)
 g.rotate(angle+math.sin(time*.85+seed)*.028)
 local kind=seed%3
 local h=size*(kind==2 and 1.15 or 1);local w=h*(kind==2 and .32 or (.40+noise(seed)*.24))
 local bend=(noise(seed+8)-.5)*h*.22
 local stem=curve({0,2,-h*.10,-h*.25,bend,-h*.53,bend,-h*.73})
 g.setColor(.018,.013,.010,.6);g.setLineWidth(h*.15+3);g.line(stem)
 g.setColor(kind==1 and {.65,.58,.42} or kind==2 and {.35,.36,.44} or {.23,.20,.13});g.setLineWidth(h*.12);g.line(stem)
 g.setColor(.47,.39,.23);g.setLineWidth(h*.035);g.line(stem)
 g.translate(bend,0)
 -- A rounded umbrella, with a shaded underside and warm edge light.
 g.setColor(.055,.039,.024);g.ellipse('fill',0,-h*.72,w,w*.24)
 g.setColor(.35,.25,.12);g.ellipse('fill',0,-h*.73,w*.92,w*.17)
 g.setLineWidth(.6);g.setColor(.67,.48,.22,.38)
 for j=-4,4 do g.line(0,-h*.67,j*w*.20,-h*.74) end
 local cap=curve({-w,-h*.75,-w*.75,-h*1.16,w*.58,-h*1.20,w,-h*.75})
 local rim=curve({w,-h*.75,w*.36,-h*.81,-w*.36,-h*.81,-w,-h*.75})
 for i=3,#rim do cap[#cap+1]=rim[i] end
 g.setColor(kind==1 and {.47,.045,.035} or kind==2 and {.20,.16,.31} or {.25,.145,.065});g.polygon('fill',cap)
 local crown=curve({-w*.88,-h*.79,-w*.55,-h*1.11,w*.35,-h*1.12,w*.63,-h*.84})
 g.setColor(kind==1 and {.76,.12,.065} or kind==2 and {.40,.31,.52} or {.39,.245,.10});g.polygon('fill',crown)
 g.setColor(kind==1 and {.98,.37,.19,.7} or kind==2 and {.67,.61,.79,.65} or {.64,.43,.18,.65});g.setLineWidth(.9)
 g.line(curve({-w*.85,-h*.83,-w*.49,-h*1.12,w*.25,-h*1.10,w*.48,-h*.94}))
 for j=1,7 do
  local xx=(noise(seed+j)-.5)*w*1.15
  g.setColor(kind==1 and {.98,.94,.79,.95} or kind==2 and {.75,.70,.88,.55} or {.70,.53,.27,.35})
  g.ellipse('fill',xx,-h*(.83+noise(seed+j*7)*.14),h*(kind==1 and .065 or .025),h*(kind==1 and .038 or .015))
 end
 g.pop()
end
local function crystal(x,y,size,angle,seed,time)
 local g=love.graphics;g.push();g.translate(x,y);g.rotate(angle)
 local pulse=.5+.5*math.sin(time*.8+seed)
 g.setColor(.17,.11,.045);g.polygon('fill',-size*.24,0,-size*.30,-size*.66,0,-size,size*.26,-size*.68,size*.20,-2)
 g.setColor(.36,.23,.085);g.polygon('fill',0,-size,size*.26,-size*.68,size*.20,-2,0,-size*.12)
 g.setColor(.57,.40,.16);g.polygon('fill',0,-size,-size*.30,-size*.66,-size*.24,0,0,-size*.12)
 g.setColor(.83,.64,.30,.25+pulse*.35);g.setLineWidth(1);g.line(-size*.29,-size*.66,0,-size,0,-size*.12)
 g.setColor(.94,.76,.37,.1+pulse*.40);g.circle('fill',0,-size*.83,1.4)
 g.pop()
end
function F.bake(width,height)
 local g=love.graphics;local R=require('earth_rocks');F.mushrooms={};F.crystals={}
 -- Every side uses the same continuous rock shelf, with irregular growth and
 -- overlapping layers instead of evenly spaced, isolated decorative clusters.
 for side=1,4 do
  local length=side<=2 and width or height
  local ox,oy,angle=0,height,0
  if side==2 then ox,oy,angle=width,0,math.pi
  elseif side==3 then ox,oy,angle=0,0,math.pi/2
  elseif side==4 then ox,oy,angle=width,height,-math.pi/2 end
  local function world(x,y)
   return ox+x*math.cos(angle)-y*math.sin(angle),oy+x*math.sin(angle)+y*math.cos(angle)
  end
  g.push();g.translate(ox,oy);g.rotate(angle)
  local x,i=-15,0
  while x<length do
   local seed=side*503+i*19;local w=30+noise(seed)*32
   local depth=18+noise(seed+2)*20
   R.rock(x,-depth,w+6,depth+12,seed)
   if i%2==0 then R.rock(x+9,-depth-7,16+noise(seed+4)*16,15,seed+8) end
   -- Thin seams and mineral flecks embedded in the rock face.
   local vein=curve({x+3,-depth*.5,x+w*.3,-depth*.8,x+w*.55,-depth*.35,x+w*.85,-depth*.7})
   g.setColor(.11,.065,.022);g.setLineWidth(3);g.line(vein)
   g.setColor(.54,.35,.12,.65);g.setLineWidth(.8);g.line(vein)
   for j=1,5 do
    g.setColor(.48,.32,.12,.55)
    g.ellipse('fill',x+noise(seed+j)*w,-5-noise(seed+j*7)*depth,1.4,.8)
   end
   -- Dark moss and fine mycelium soften the cut stone silhouette.
   for j=1,6 do
    local px=x+noise(seed+j*5)*w;local py=-depth+noise(seed+j*11)*10
    g.setColor(.08,.085,.035,.85);g.ellipse('fill',px,py,3+noise(seed+j)*4,2)
   end
   if i%4==0 then
    -- Gnarled roots and tiny shelf fungi add forms between the taller caps.
    local root=curve({x+5,5,x+w*.85,-6,x+w*.15,-depth,x+w*.70,-depth-10})
    g.setColor(.09,.055,.028);g.setLineWidth(6);g.line(root)
    g.setColor(.33,.23,.10);g.setLineWidth(1.4);g.line(root)
    for j=1,3 do
     local px=x+w*.6-j*4;local py=-depth*.4-j*5
     g.setColor(.27,.14,.065);g.ellipse('fill',px,py,9-j,3)
     g.setColor(.64,.43,.20);g.setLineWidth(.8);g.arc('line','open',px,py,9-j,math.pi,math.pi*2)
    end
   end
   if i%3~=1 then
    local wx,wy=world(x+w*.48,-depth*.42)
    local h=20+noise(seed+30)*25
    F.mushrooms[#F.mushrooms+1]={wx,wy,h,angle+(noise(seed+21)-.5)*.5,seed}
    local xx,yy=world(x+w*.48+12,-depth*.30)
    F.mushrooms[#F.mushrooms+1]={xx,yy,h*.58,angle+.25,seed+31}
   end
   if i%3==1 then
    for j=1,3 do
     local wx,wy=world(x+w*.45+(j-2)*7,-depth*.60)
     F.crystals[#F.crystals+1]={wx,wy,9+noise(seed+j*3)*12,angle+(j-2)*.38,seed+j}
    end
   end
   x=x+w-5;i=i+1
  end
  g.pop()
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
 g.push('all');g.setShader();g.setColor(.66,.63,.57,1);g.setBlendMode('alpha','premultiplied');g.draw(F.canvas)
 g.setBlendMode('alpha','alphamultiply');g.setLineStyle('smooth');g.setLineJoin('none')
 local time=Graphics.effects and UI.clock or 0
 for _,v in ipairs(F.crystals) do crystal(v[1],v[2],v[3],v[4],v[5],time) end
 for _,v in ipairs(F.mushrooms) do mushroom(v[1],v[2],v[3],v[4],v[5],time) end
 g.pop()
end
return F
