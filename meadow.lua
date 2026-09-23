-- Draw once into a sharp canvas; flowers and grass never grow runtime arrays.
local M={}
function M.draw()
 local g=love.graphics
 if not M.canvas or M.width~=Arena.width then
  if M.canvas then M.canvas:release() end
  M.width=Arena.width;M.canvas=g.newCanvas(Arena.width,600);M.canvas:setFilter('linear','linear')
  local old=g.getCanvas();g.push('all');g.setCanvas(M.canvas);g.origin();g.clear(0,0,0,0)
  local function scatter(i,k) local n=math.sin(i*127.1+k*311.7)*43758.5453;return n-math.floor(n) end
  for i=1,1400 do local x=28+scatter(i,1)*(Arena.width-56);local y=45+scatter(i,2)*510
   local h=3+i%6;g.setColor(.16+(i%3)*.045,.48+(i%5)*.035,.07,.7);g.setLineWidth(1)
   g.line(x-2,y,x,y-h,x+1,y-1,x+4,y-h*.7)
  end
  local colors={{.2,.57,1},{1,.86,.2},{.95,.18,.15}}
  for i=1,125 do local x=40+scatter(i,3)*(Arena.width-80);local y=65+scatter(i,4)*470;local c=colors[i%3+1]
   g.setColor(.07,.29,.055,.65);g.ellipse('fill',x+2,y+3,5,2)
   g.setColor(c[1],c[2],c[3],.95)
   for j=1,5 do local a=j*math.pi*2/5;g.circle('fill',x+math.cos(a)*2.5,y+math.sin(a)*2.5,2.3) end
   g.setColor(1,.93,.64);g.circle('fill',x,y,1.3)
  end
  g.setCanvas(old);g.pop()
 end
 g.setColor(1,1,1);g.draw(M.canvas)
end
function M.wall(r)
 local g=love.graphics
 g.setColor(.025,.12,.035);g.rectangle('fill',r.x,r.y+3,r.w,r.h)
 g.setColor(.14,.34,.085);g.rectangle('fill',r.x,r.y,r.w,r.h,3)
 g.setColor(.42,.72,.18);g.setLineWidth(2);g.line(r.x+2,r.y+2,r.x+r.w-2,r.y+2)
 for x=r.x+5,r.x+r.w-3,10 do g.setColor(.26,.63,.09);g.polygon('fill',x-3,r.y+2,x-2,r.y-4,x+1,r.y,x+4,r.y-3,x+3,r.y+3) end
 g.setLineWidth(1);g.setColor(1,1,1)
end
return M
