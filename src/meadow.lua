-- Draw once into a sharp canvas; flowers and grass never grow runtime arrays.
local M={}
function M.draw()
 local g=love.graphics
 if not M.canvas or M.width~=Arena.width then
  if M.canvas then M.canvas:release() end
  M.width=Arena.width;M.canvas=g.newCanvas(Arena.width,600);M.canvas:setFilter('linear','linear')
  local old=g.getCanvas();g.push('all');g.setCanvas(M.canvas);g.origin();g.clear(0,0,0,0)
  local function scatter(i,k) local n=math.sin(i*127.1+k*311.7)*43758.5453;return n-math.floor(n) end
  -- Organic woodland clearing, cached once; restrained contrast keeps hazards readable.
  g.clear(.075,.14,.095,1)
  for i=1,230 do
   local x=scatter(i,1)*Arena.width;local y=scatter(i,2)*600;local v=scatter(i,3)
   g.setColor(.13+v*.025,.23+v*.045,.12,.22)
   g.ellipse('fill',x,y,25+v*80,12+v*32)
  end
  for i=1,55 do
   local y=45+i*9;local x=Arena.width*.5+math.sin(y*.010)*Arena.width*.14
   g.setColor(.29,.27,.17,.07);g.ellipse('fill',x,y,75+math.sin(i*.7)*15,19)
  end
  for i=1,1300 do
   local x=25+scatter(i,4)*(Arena.width-50);local y=28+scatter(i,5)*544;local h=3+scatter(i,6)*6
   g.setColor(.25,.36,.18,.25);g.setLineWidth(1)
   g.line(x-2,y,x,y-h,x+2,y-1);g.line(x,y,x+4,y-h*.7)
  end
  for i=1,100 do
   local x=scatter(i,7)*Arena.width;local y=scatter(i,8)*600
   if x<95 or x>Arena.width-95 or y<70 or y>535 then
    local r=9+scatter(i,9)*22
    g.setColor(.025,.07,.045,.45);g.ellipse('fill',x+4,y+6,r*1.2,r*.7)
    for j=1,5 do
     local a=j*math.pi*.4;g.setColor(.07+j*.009,.18+j*.009,.095,.85)
     g.ellipse('fill',x+math.cos(a)*r*.5,y+math.sin(a)*r*.3,r*.65,r*.42)
    end
   end
  end
  for i=1,60 do
   local x=40+scatter(i,10)*(Arena.width-80);local y=50+scatter(i,11)*500
   g.setColor(.29,.40,.20,.6);g.line(x,y+3,x,y-2)
   g.setColor(.8,.78,.56,.7);g.circle('fill',x-1,y-3,1.5);g.circle('fill',x+2,y-2,1.5)
  end
  g.setCanvas(old);g.pop()
 end
 g.setColor(1,1,1);g.draw(M.canvas)
end
function M.wall(r)
 local g=love.graphics
 g.setColor(.035,.055,.07);g.rectangle('fill',r.x,r.y+3,r.w,r.h)
 g.setColor(.16,.22,.25);g.rectangle('fill',r.x,r.y,r.w,r.h,3)
 g.setColor(.36,.48,.5);g.setLineWidth(2);g.line(r.x+2,r.y+2,r.x+r.w-2,r.y+2)
 for x=r.x+5,r.x+r.w-3,10 do g.setColor(.19,.34,.3);g.polygon('fill',x-3,r.y+2,x-2,r.y-4,x+1,r.y,x+4,r.y-3,x+3,r.y+3) end
 g.setLineWidth(1);g.setColor(1,1,1)
end
return M
