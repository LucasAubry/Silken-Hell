local Art=require('art')
-- Separate painted mantle; the articulated vector arms keep their gameplay reach.
local H={}
function H.draw(a,x,y,angle,scale,flash)
 if not Art.images.octopus_mantle then Art.add('octopus_mantle','assets/monstres/ocean/poulpe/mantle.png') end
 local qx,qy,qw,qh=a.quad:getViewport()
 local g=love.graphics;g.push('all');g.translate(x,y);g.rotate(angle);g.setColor(1,1-flash,1-flash)
 Art.draw('octopus_mantle',(624.5-qx-qw/2)*scale,(599-qy-qh/2)*scale,373*scale,0,522*scale)
 g.pop()
end
function H.underside(a,x,y,angle,scale)
 local g=love.graphics;g.push('all');g.translate(x,y);g.rotate(angle);g.scale(scale,scale);g.setShader()
 -- Ventral skin shares the ink, pigment and layered suckers of the articulated arms.
 g.setColor(.063,.031,.184);g.ellipse('fill',0,-72,164,232,48)
 for i=0,15 do
  local t=i/15
  g.setColor(.18+t*.31,.09+t*.24,.43+t*.30)
  g.ellipse('fill',-t*22,-72-t*27,155-i*5.5,223-i*8.5,48)
 end
 for i=1,82 do
  local a=i*2.399;local r=math.sqrt(i/83)
  local px,py=math.cos(a)*r*137, -76+math.sin(a)*r*195
  local size=3+i%5
  g.setColor(.64,.43,.85,.16+(i%3)*.06);g.ellipse('fill',px,py,size,size*.75,8)
 end
 -- Radial folds converge on the beak between the eight arm roots.
 g.setLineWidth(3)
 for i=1,8 do
  local a=i*math.pi/4
  g.setColor(.23,.12,.48,.7)
  g.line(math.cos(a)*84,72+math.sin(a)*58,math.cos(a)*37,82+math.sin(a)*29)
  local px,py=math.cos(a)*53,82+math.sin(a)*37
  g.setColor(.20,.10,.56);g.ellipse('fill',px,py,15,13,8)
  g.setColor(.66,.46,.92);g.ellipse('fill',px-1,py-1,12,10,8)
  g.setColor(.36,.18,.75);g.ellipse('fill',px+1,py+1,7,6,8)
  g.setColor(.14,.07,.42);g.ellipse('fill',px+2,py+2,4,4,8)
 end
 g.setColor(.063,.031,.184);g.ellipse('fill',0,82,26,22,12)
 g.setColor(.50,.36,.62);g.polygon('fill',-17,80,0,64,16,80,0,97)
 g.setColor(.84,.71,.77);g.polygon('fill',-13,79,0,67,1,84,0,92)
 g.pop()
end
return H
