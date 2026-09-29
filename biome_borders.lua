-- Decorative edge masonry. Arena collision rectangles are left unchanged.
local B={}
local palettes={
 [8]={{.018,.026,.035},{.07,.095,.12},{.28,.43,.55}},
 [1]={{.38,.33,.24},{.81,.76,.62},{1,.96,.83}},
 [6]={{.14,.22,.33},{.38,.53,.66},{.75,.88,1}},
 [5]={{.16,.10,.065},{.39,.25,.13},{.76,.55,.28}},
 [4]={{.035,.13,.17},{.12,.34,.38},{.40,.79,.75}},
 [7]={{.025,.04,.085},{.075,.13,.22},{.27,.48,.66}},
 [2]={{.085,.018,.03},{.23,.055,.065},{.93,.28,.10}},
 [3]={{.035,.055,.07},{.16,.22,.25},{.5,.63,.69}}
}
local function rand(i,k) local n=math.sin(i*127.1+k*311.7)*43758.5453;return n-math.floor(n) end
local function tint(c,a,m) love.graphics.setColor(c[1]*(m or 1),c[2]*(m or 1),c[3]*(m or 1),a or 1) end
function B.edge(length,biome,seed)
 local g=love.graphics;local p=palettes[biome] or palettes[1]
 tint(p[1]);g.rectangle('fill',0,0,length,22)
 for i=0,math.ceil(length/48) do local x=i*48;local shift=rand(i,seed)
  tint(p[2],1,.83+shift*.22);g.polygon('fill',x+2,2,x+43,2,x+47,6,x+45,19,x+5,21,x+1,16)
  tint(p[3],.55);g.line(x+5,3,x+42,3,x+45,6)
  tint(p[1],.75);g.line(x+5,19,x+43,18,x+45,7)
  if biome==1 then
   tint(p[3],.75);g.line(x+10,8,x+36,8);g.line(x+10,15,x+36,15)
   if i%3==0 then g.polygon('line',x+24,6,x+28,11,x+24,17,x+20,11) end
  elseif biome==6 then
   tint(p[3],.65);g.line(x+8,15,x+18,6,x+27,14,x+37,6)
   g.setColor(.88,.95,1,.55);g.ellipse('fill',x+24,20,15,3)
  elseif biome==5 then
   tint(p[1]);g.line(x+6,5,x+20,10,x+15,17,x+40,19)
   tint(p[3],.65);g.line(x+5,4,x+20,8,x+32,5,x+44,12)
  elseif biome==4 then
   tint(p[3],.75);g.circle('line',x+17,11,5);g.circle('line',x+17,11,2)
   g.setColor(.73,.38,.35,.85);g.line(x+34,20,x+34,9,x+30,5);g.line(x+34,14,x+39,8)
  elseif biome==7 then
   tint(p[3],.65);g.polygon('fill',x+12,19,x+17,5,x+22,19);g.polygon('fill',x+21,20,x+27,11,x+30,20)
   g.setColor(.34,.77,.83,.8);g.rectangle('fill',x+17,8,2,6)
  elseif biome==2 then
   tint(p[3],.9);g.line(x+8,2,x+15,9,x+11,14,x+23,21)
   g.setColor(1,.61,.16,.7);g.line(x+15,9,x+22,6)
  elseif biome==8 then
   tint(p[3],.7);g.line(x+14,6,x+24,16,x+34,6);g.rectangle('fill',x+22,6,4,4)
  else
   g.setColor(.23,.38,.34,.8);g.line(x+4,19,x+17,12,x+31,14,x+43,5)
   for j=0,2 do local xx=x+13+j*10;g.ellipse('fill',xx,11+j%2*4,5,2) end
   g.setColor(.85,.85,.66,.65);g.rectangle('fill',x+9,5,3,3)
  end
 end
 tint(p[3],.45);g.line(0,21,length,21)
end
function B.draw()
 local g=love.graphics;local biome=Secret.inArena() and 8 or Campaign.biome;local rank=Worlds.rank(biome);if rank==math.huge then rank=biome==8 and 4 or 1 end;rank=math.min(7,rank)
 local key=biome..':'..Arena.width..':'..(player.level or 1)
 if B.key~=key then
  B.key=key;if B.canvas then B.canvas:release() end
  B.canvas=g.newCanvas(Arena.width,600);B.canvas:setFilter('nearest','nearest')
  local old=g.getCanvas();g.push('all');g.setCanvas(B.canvas);g.origin();g.setShader();g.clear(0,0,0,0)
  B.edge(Arena.width,biome,1)
  g.push();g.translate(Arena.width,600);g.rotate(math.pi);B.edge(Arena.width,biome,2);g.pop()
  g.push();g.translate(0,600);g.rotate(-math.pi/2);B.edge(600,biome,3);g.pop()
  g.push();g.translate(Arena.width,0);g.rotate(math.pi/2);B.edge(600,biome,4);g.pop()
  -- The same fine silk appears increasingly often along the entire route.
  local density=3+(rank-1)*4+math.floor(((player.level or 1)-1)/4)
  local perimeter=2*(Arena.width+600)
  for i=1,density do
   local d=(i/density*perimeter+rand(i,biome)*55)%perimeter;local x,y,angle
   if d<Arena.width then x,y,angle=d,17,0 elseif d<Arena.width+600 then x,y,angle=Arena.width-17,d-Arena.width,math.pi/2
   elseif d<2*Arena.width+600 then x,y,angle=2*Arena.width+600-d,583,math.pi else x,y,angle=17,perimeter-d,-math.pi/2 end
   local size=24+rank*3+rand(i,4)*10
   g.setColor(.93,.96,1,.30+rank*.055);require('final_art').draw('web_wall',x,y,size,i*.81)
  end
  g.setCanvas(old);g.pop()
 end
 g.push('all');g.setShader();g.setColor(1,1,1);g.draw(B.canvas);g.pop()
end
return B
