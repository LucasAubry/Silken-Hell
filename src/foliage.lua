-- Static shrubs rooted in masonry; baked with borders, never gameplay obstacles.
local F={}
function F.bush(x,y,r,seed)
 local g=love.graphics;g.push('all');g.setShader()
 g.setColor(.015,.038,.019,.42);g.ellipse('fill',x+3,y+5,r*1.05,r*.64)
 for i=1,9 do
  local a=i*2.399+seed;local spread=i==9 and 0 or r*.52
  local xx,yy=x+math.cos(a)*spread,y+math.sin(a)*spread*.6
  local size=r*(.40+(i%3)*.065)
  g.setColor(.055,.145,.065);g.ellipse('fill',xx,yy+2,size,size*.72)
  g.setColor(.16+i%3*.018,.30+i%3*.025,.105);g.ellipse('fill',xx-1,yy-1,size*.93,size*.67)
  g.setColor(.36,.49,.17,.65);g.ellipse('fill',xx-size*.22,yy-size*.22,size*.48,size*.25)
  g.setColor(.09,.23,.07);g.setLineWidth(.8);g.line(xx-3,yy+1,xx+2,yy-3)
 end
 for i=1,3 do
  local a=seed+i*2.4;local xx,yy=x+math.cos(a)*r*.56,y+math.sin(a)*r*.35
  g.setColor(.75,.47,.25,.8);g.circle('fill',xx,yy,1.25)
 end
 g.pop()
end
function F.edge(length,seed)
 for i=0,math.floor(length/39) do
  F.bush(12+i*39,12+math.sin(i*3.1+seed)*3,15+(i*7+seed)%8,i+seed*19)
 end
end
return F
