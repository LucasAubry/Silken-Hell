-- Celestial stonework and inlaid ornaments; no new collision geometry.
local P={}
function P.edge(length)
 local g=love.graphics;g.push('all');g.setShader()
 g.setColor(.14,.23,.32);g.rectangle('fill',0,0,length,22)
 local count=math.ceil(length/84);local span=length/count
 for i=1,count do
  local x=(i-1)*span
  g.setColor(.63,.70,.72);g.polygon('fill',x+2,2,x+span-2,2,x+span-4,18,x+4,18)
  g.setColor(.87,.88,.77);g.setLineWidth(1.2);g.line(x+4,3,x+span-4,3)
  g.setColor(.35,.45,.53);g.line(x+4,18,x+span-4,18)
  g.setColor(.79,.64,.34);g.setLineWidth(1);g.line(x+7,8,x+span*.5-6,8);g.line(x+span*.5+6,8,x+span-7,8)
  local cx=x+span*.5
  g.setColor(.21,.45,.57);g.polygon('fill',cx,4,cx+4,9,cx,14,cx-4,9)
  g.setColor(.68,.94,.97);g.line(cx,5,cx-2,9,cx,12)
 end
 g.setColor(.84,.73,.46,.8);g.line(0,20,length,20)
 g.pop()
end
function P.draw()
 if Campaign.biome~=1 or Secret.inArena() then return end
 local g=love.graphics;local target=g.getCanvas();local density=target and target:getDPIScale() or 1
 local key=Arena.width..':'..density
 if P.key~=key then
  P.key=key;if P.canvas then P.canvas:release() end
  P.canvas=g.newCanvas(Arena.width,600,{dpiscale=density});P.canvas:setFilter('linear','linear')
  g.push('all');g.setCanvas(P.canvas);g.origin();g.setScissor();g.setShader();g.clear()
  local cx,cy=Arena.width/2,300
  -- Fine ceremonial rings are floor inlays, never raised platforms.
  for _,r in ipairs({174,181,222}) do
   g.setColor(.89,.80,.54,r==181 and .16 or .09);g.setLineWidth(r==181 and 1.4 or .8)
   g.ellipse('line',cx,cy,r*1.32,r)
  end
  for i=0,15 do
   local a=i*math.pi/8;local x,y=cx+math.cos(a)*181*1.32,cy+math.sin(a)*181
   g.setColor(.91,.84,.65,.18);g.circle('fill',x,y,i%4==0 and 2.2 or 1)
  end
  -- White-gold laurel silhouettes frame the arena's outer stone.
  for side=1,4 do
   g.push()
   if side==2 then g.translate(Arena.width,600);g.rotate(math.pi)
   elseif side==3 then g.translate(0,600);g.rotate(-math.pi/2)
   elseif side==4 then g.translate(Arena.width,0);g.rotate(math.pi/2) end
   local length=side<=2 and Arena.width or 600
   for i=1,math.floor(length/145) do
    local x=i*length/(math.floor(length/145)+1)
    g.setColor(.64,.69,.59,.5);g.setLineWidth(1);g.line(x-28,24,x,37,x+28,24)
    for j=-3,3 do
     local xx=x+j*7;local y=37-math.abs(j)*3
     g.setColor(.77,.83,.76,.40);g.polygon('fill',xx,y,xx-6,y-7,xx-3,y-13,xx+2,y-6)
     g.setColor(.91,.81,.53,.45);g.line(xx,y,xx-2,y-8)
    end
   end
   g.pop()
  end
  g.pop()
 end
 g.push('all');g.setShader();g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(P.canvas);g.pop()
end
return P
