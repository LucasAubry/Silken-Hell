-- Draw once into a sharp canvas; flowers and grass never grow runtime arrays.
local M={}
function M.draw()
 local g=love.graphics
 if not M.canvas or M.width~=Arena.width then
  if M.canvas then M.canvas:release() end
  M.width=Arena.width;M.canvas=g.newCanvas(Arena.width,600);M.canvas:setFilter('linear','linear')
  local old=g.getCanvas();g.push('all');g.setCanvas(M.canvas);g.origin();g.clear(0,0,0,0)
  local function scatter(i,k) local n=math.sin(i*127.1+k*311.7)*43758.5453;return n-math.floor(n) end
  -- Transparent painted details over the shared soft meadow floor.
  g.clear(0,0,0,0)
  for i=1,90 do
   local x=scatter(i,1)*Arena.width;local y=scatter(i,2)*600;local v=scatter(i,3)
   g.setColor(.39+v*.025,.52+v*.045,.20,.045)
   g.ellipse('fill',x,y,25+v*80,12+v*32)
  end
  for i=1,55 do
   local y=45+i*9;local x=Arena.width*.5+math.sin(y*.010)*Arena.width*.14
   g.setColor(.66,.73,.32,.022);g.ellipse('fill',x,y,75+math.sin(i*.7)*15,19)
  end
  for i=1,420 do
   local x=25+scatter(i,4)*(Arena.width-50);local y=28+scatter(i,5)*544;local h=3+scatter(i,6)*6
   g.setColor(.49,.61,.26,.16);g.setLineWidth(1)
   g.line(x-2,y,x,y-h,x+2,y-1);g.line(x,y,x+4,y-h*.7)
  end
  for i=1,65 do
   local x=scatter(i,7)*Arena.width;local y=scatter(i,8)*600
   if x<95 or x>Arena.width-95 or y<70 or y>535 then
    local r=9+scatter(i,9)*22
    g.setColor(.035,.09,.09,.20);g.ellipse('fill',x+4,y+6,r*1.2,r*.7)
    for j=1,5 do
     local a=j*math.pi*.4;g.setColor(.16+j*.009,.28+j*.009,.13,.35)
     g.ellipse('fill',x+math.cos(a)*r*.5,y+math.sin(a)*r*.3,r*.65,r*.42)
    end
   end
  end
  for i=1,35 do
   local x=40+scatter(i,10)*(Arena.width-80);local y=50+scatter(i,11)*500
   g.setColor(.34,.48,.25,.45);g.line(x,y+3,x,y-2)
   g.setColor(.84,.90,.48,.6);g.circle('fill',x-1,y-3,1.5);g.circle('fill',x+2,y-2,1.5)
  end
  g.setCanvas(old);g.pop()
 end
 g.setColor(1,1,1);g.draw(M.canvas)
end
function M.wall(r)
 local g=love.graphics
 g.setColor(.025,.055,.055);g.rectangle('fill',r.x,r.y+3,r.w,r.h)
 g.setColor(.12,.23,.24);g.rectangle('fill',r.x,r.y,r.w,r.h,3)
 g.setColor(.32,.43,.38);g.setLineWidth(2);g.line(r.x+2,r.y+2,r.x+r.w-2,r.y+2)
 for x=r.x+5,r.x+r.w-3,10 do g.setColor(.32,.44,.16);g.polygon('fill',x-3,r.y+2,x-2,r.y-4,x+1,r.y,x+4,r.y-3,x+3,r.y+3) end
 local length=math.max(r.w,r.h);local count=math.max(1,math.floor(length/35))
 for i=1,count do require('foliage').bush(r.x+r.w*(r.w>=r.h and (i-.5)/count or .5),r.y+r.h*(r.w>=r.h and .5 or (i-.5)/count),14,i+r.x) end
 g.setLineWidth(1);g.setColor(1,1,1)
end
return M
