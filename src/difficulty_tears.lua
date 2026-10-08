local D={}
function D.draw(level,x,y,spacing,radius)
 local g=love.graphics
 local colors={{1,1,1},{1,.88,.71},{1,.65,.42},{1,.36,.24},{1,.12,.12}}
 g.setColor(colors[level] or colors[1])
 spacing=spacing or 13;radius=radius or 4
 for i=1,level do
  local xx=x+(i-1)*spacing
  g.circle('fill',xx,y+radius,radius)
  g.polygon('fill',xx-radius,y+radius*.75,xx,y-radius*1.25,xx+radius,y+radius*.75)
 end
end
return D
