-- Draw once into a sharp canvas; flowers and grass never grow runtime arrays.
local M={}
function M.draw()
 local g=love.graphics
 if not M.canvas or M.width~=Arena.width then
  if M.canvas then M.canvas:release() end
  M.width=Arena.width;M.canvas=g.newCanvas(Arena.width,600);M.canvas:setFilter('linear','linear')
  local old=g.getCanvas();g.push('all');g.setCanvas(M.canvas);g.origin();g.clear(0,0,0,0)
  local function scatter(i,k) local n=math.sin(i*127.1+k*311.7)*43758.5453;return n-math.floor(n) end
  -- A quiet moonlit garden: pale stone paths, moss and fine silk strands.
  g.clear(.045,.065,.09,1)
  for row=0,14 do
   for col=0,math.ceil(Arena.width/86) do
    local x=col*86+(row%2)*43-43;local y=row*44
    local v=scatter(row*31+col,4)
    g.setColor(.085+v*.025,.115+v*.025,.145+v*.035)
    g.rectangle('fill',x+2,y+2,82,40,7)
    g.setColor(.3,.4,.46,.08);g.line(x+10,y+3,x+74,y+3)
   end
  end
  for i=1,75 do
   local x=scatter(i,1)*Arena.width;local y=scatter(i,2)*600
   g.setColor(.1,.23,.21,.12);g.ellipse('fill',x,y,18+scatter(i,3)*38,6+scatter(i,4)*16)
  end
  for i=28,1,-1 do
   g.setColor(.36,.43,.58,.009);g.ellipse('fill',Arena.width*.5,300,i*14,i*7)
  end
  for i=1,38 do
   local x=scatter(i,5)*Arena.width;local y=scatter(i,6)*600
   g.setColor(.72,.8,.9,.06);g.setLineWidth(1)
   g.line(x,y,x+18,y+5,x+42,y+7,x+65,y+4)
  end
  for i=1,95 do
   local x=25+scatter(i,7)*(Arena.width-50);local y=30+scatter(i,8)*540
   if math.abs(x-Arena.width*.5)>Arena.width*.31 or y>510 or y<90 then
    g.setColor(.2,.36,.32,.65);g.line(x,y,x-4,y-8,x-7,y-10)
    g.setColor(.69,.77,.86,.65);g.circle('fill',x-7,y-10,1.7)
   end
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
