-- A small, cached pixel-art shell. Faceted shading and mineral speckles use a
-- fixed pattern: rendering never consumes the gameplay random generator.
local E={}
local colors={{.065,.12,.13},{.16,.28,.27},{.29,.43,.36},{.52,.62,.46},{.73,.78,.58},{.91,.88,.70},{1,.96,.82}}
local function inside(x,y)
 local yy=(y-49)/46;local radius=32*(.91+.11*yy)*math.sqrt(math.max(0,1-yy*yy))
 return math.abs(x-35)<radius and math.abs(yy)<1
end
function E.load()
 if E.image then return end
 local data=love.image.newImageData(72,100)
 for y=0,99 do for x=0,71 do
  local px,py=math.floor(x/2)*2,math.floor(y/2)*2
  if inside(px,py) then
   local edge=not inside(px-2,py) or not inside(px+2,py) or not inside(px,py-2) or not inside(px,py+2)
   local nx,ny=(px-35)/30,(py-49)/46
   local light=.70-nx*.27-ny*.15-math.abs(nx)*.17
   local index=edge and 1 or math.max(2,math.min(6,math.floor(light*6)+1))
   if not edge then
    local hx,hy=(px-27)/10,(py-24)/19
    if hx*hx+hy*hy<1 then index=math.min(7,index+1) end
    local cx,cy=math.floor(px/4),math.floor(py/4)
    local noise=(cx*37+cy*61+cx*cy*13)%101
    if noise<6 and py>21 and py<87 then index=math.max(2,index-1)
    elseif noise>96 then index=math.min(6,index+1) end
   end
   local c=colors[index];data:setPixel(x,y,c[1],c[2],c[3],1)
  end
 end end
 E.image=love.graphics.newImage(data);E.image:setFilter('nearest','nearest');data:release()
end
function E.draw(x,y,size,cracks)
 E.load();local g=love.graphics;local scale=size/46
 g.setColor(1,1,1);g.draw(E.image,x,y,0,scale,scale,35,49)
 if (cracks or 0)>0 then
  g.push('all');g.translate(x,y);g.scale(scale,scale);g.setLineStyle('rough')
  local paths={{-12,-17,-5,-10,-9,-2,-2,5},{13,-27,6,-18,11,-11,3,-5},{-17,15,-8,12,-3,20,5,15},{17,9,11,16,15,26,8,32},{-3,-38,1,-29,-3,-24,2,-16}}
  for i=1,math.min(cracks,#paths) do
   g.setLineWidth(3);g.setColor(.12,.22,.20);g.line(paths[i])
   g.translate(-1,0);g.setLineWidth(1);g.setColor(.95,.9,.66,.7);g.line(paths[i]);g.translate(1,0)
  end
  g.pop()
 end
end
return E
