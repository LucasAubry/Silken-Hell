-- Cached, shaded shell: all geometry and grain are built once, not per frame.
local E={}
local spots={{-5,-7,4,4.5,-.4},{5,4,3.6,5,.5},{-6,5,3.2,3.7,-.2},{3,-2,2.2,2.5,.3},{-1,11,2.2,1.8,0},{2,-11,1.5,2,.1},{-1,3,1.3,1.5,0}}
local function vertex(radius,angle)
 local nx,ny=math.cos(angle)*radius,math.sin(angle)*radius
 local x,y=nx*11*(1+ny*.18),ny*16
 local nz=math.sqrt(math.max(0,1-radius*radius))
 local light=math.max(0,-nx*.38-ny*.42+nz*.82)
 local shade=.53+.46*light
 local grain=math.sin(math.floor(x*3)*127.1+math.floor(y*3)*311.7)*43758.5453
 grain=grain-math.floor(grain)
 shade=shade+(grain-.5)*.055
 local red,green,blue=1,.985,.94
 for _,p in ipairs(spots) do
  local dx,dy=x-p[1],y-p[2];local c,s=math.cos(p[5]),math.sin(p[5])
  if ((dx*c+dy*s)/p[3])^2+((-dx*s+dy*c)/p[4])^2<1 then red,green,blue=.065,.22,.49;break end
 end
 local shine=math.max(0,-nx*.32-ny*.4+nz*.86)^30*.12
 return {x,y,0,0,math.min(1,red*shade+shine),math.min(1,green*shade+shine),math.min(1,blue*shade+shine),1}
end
function E.draw(x,y,size,cracks,angle)
 local g=love.graphics
 if not E.shell then
  local vertices={};local rings,segments=24,96;E.outline={}
  for r=0,rings-1 do for i=0,segments-1 do
   local a,b=i*math.pi*2/segments,(i+1)*math.pi*2/segments
   local p,q,s,t=vertex(r/rings,a),vertex((r+1)/rings,a),vertex((r+1)/rings,b),vertex(r/rings,b)
   for _,v in ipairs({p,q,s,p,s,t}) do vertices[#vertices+1]=v end
  end end
  for i=0,segments do local v=vertex(1,i*math.pi*2/segments);E.outline[#E.outline+1]=v[1];E.outline[#E.outline+1]=v[2] end
  E.shell=g.newMesh(vertices,'triangles','static')
 end
 g.push('all');g.translate(x,y);g.rotate(angle or 0);g.scale(size/16)
 g.setColor(.12,.19,.25);g.setLineWidth(.6);g.polygon('line',E.outline)
 g.setColor(1,1,1);g.draw(E.shell)
 if (cracks or 0)>0 then
  local path={0,-15.7,-1.6,-12,1.1,-8.5,-1.4,-5,1.8,-1.8,-.7,2,2.2,5.5,-.8,9,1.1,12.5,0,15.7}
  local count=math.min(10,math.max(2,math.ceil(cracks)+1))
  local points={};for i=1,count*2 do points[i]=path[i] end
  g.setLineWidth(.85);g.setColor(.12,.18,.24);g.line(unpack(points))
  g.setLineWidth(.23);g.setColor(.83,.87,.90);g.push();g.translate(.45,0);g.line(unpack(points));g.pop()
  if cracks>=4 then g.setColor(.16,.23,.3);g.setLineWidth(.4);g.line(-1.4,-5,-4,-6.5,-5,-9) end
  if cracks>=7 then g.line(2.2,5.5,5,4.5,6,1.5) end
 end
 g.pop()
end
return E
