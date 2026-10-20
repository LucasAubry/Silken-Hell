-- Permanent electric paths are deduplicated on a six-unit grid and indexed
-- spatially. Collision cost depends on nearby paths, not the length of a run.
local T={}
function T.reset()
 T.keys={};T.cells={};T.drawn=0
 if T.canvas then T.canvas:release();T.canvas=nil end
end
local function index(p)
 for y=math.floor((math.min(p.y,p.ty)-5)/32),math.floor((math.max(p.y,p.ty)+5)/32) do
  for x=math.floor((math.min(p.x,p.tx)-5)/32),math.floor((math.max(p.x,p.tx)+5)/32) do
   local key=x..':'..y;T.cells[key]=T.cells[key] or {};T.cells[key][#T.cells[key]+1]=p
  end
 end
end
function T.add(list,x,y,tx,ty,time)
 local function snap(v)return math.floor(v/6+.5)*6 end
 x,y,tx,ty=snap(x),snap(y),snap(tx),snap(ty)
 if x==tx and y==ty then return end
 local a,b=x..','..y,tx..','..ty;if a>b then a,b=b,a end
 local key=a..':'..b;if T.keys[key] then return end
 T.keys[key]=true
 local p={x=x,y=y,tx=tx,ty=ty,time=time};list[#list+1]=p;index(p)
end
function T.resize(list,ratio)
 T.reset()
 for _,p in ipairs(list) do p.x=p.x*ratio;p.tx=p.tx*ratio;index(p) end
end
function T.near(x,y,w,h,visit)
 local seen={}
 for row=math.floor(y/32),math.floor((y+h)/32) do for col=math.floor(x/32),math.floor((x+w)/32) do
  for _,p in ipairs(T.cells[col..':'..row] or {}) do
   if not seen[p] then seen[p]=true;if visit(p) then return true end end
  end
 end end
 return false
end
function T.draw(list,time)
 local g=love.graphics;g.push('all');g.setShader()
 if not T.canvas or T.canvas:getWidth()~=math.ceil(Arena.width) then
  if T.canvas then T.canvas:release() end
  T.canvas=g.newCanvas(math.ceil(Arena.width),600,{dpiscale=1});T.drawn=0
 end
 local previous=g.getCanvas()
 g.setCanvas(T.canvas);g.origin();g.setScissor();g.setBlendMode('alpha')
 if T.drawn==0 then g.clear() end
 g.setLineJoin('bevel')
 for i=T.drawn+1,#list do
  local p=list[i]
  g.setColor(.15,.55,1,.22);g.setLineWidth(12);g.line(p.x,p.y,p.tx,p.ty)
  g.setColor(.25,.82,1,.85);g.setLineWidth(4);g.line(p.x,p.y,p.tx,p.ty)
  g.setColor(.92,.98,.66,1);g.setLineWidth(1.5);g.line(p.x,p.y,p.tx,p.ty)
 end
 T.drawn=#list;g.setCanvas(previous);g.pop()
 g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(T.canvas)
 g.setBlendMode('alpha');g.setLineWidth(1)
 -- A bounded number of crawling sparks animate the entire persistent network.
 for i=1,math.min(75,#list) do
  local p=list[(i*131+math.floor(time*15))%#list+1]
  g.setColor(.85,.96,1,.6);g.line(p.x-2,p.y-4,p.x+2,p.y,p.x-1,p.y+4)
 end
 g.pop()
end
T.reset()
return T
