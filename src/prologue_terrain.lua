-- Native autumn clearing: soft banks and uneven plant clusters, baked once.
local T={}
local function rand(i,s)local n=math.sin(i*127.1+s*311.7)*43758.5453;return n-math.floor(n)end
local function leaf(x,y,size,a,color)
 local g=love.graphics;g.push();g.translate(x,y);g.rotate(a);g.setColor(color)
 g.ellipse('fill',0,0,size,size*.43);g.pop()
end
local function ribbon(stream,width,color)
 local g=love.graphics;g.setColor(color)
 for y=-4,750,4 do
  local a,b=stream(y),stream(y+4)
  local wa=width+math.sin(y*.025)*2+math.sin(y*.061)*1.2
  local wb=width+math.sin((y+4)*.025)*2+math.sin((y+4)*.061)*1.2
  g.polygon('fill',a-wa,y,a+wa,y,b+wb,y+4,b-wb,y+4)
 end
end
local function shrub(x,y,r,seed)
 local g=love.graphics
 for layer=4,1,-1 do g.setColor(.035,.055,.022,.055);g.ellipse('fill',x+4,y+7,r+layer*3,(r+layer*2)*.65) end
 for j=1,55 do
  local a=j*2.399;local spread=math.sqrt(rand(j,seed))*r
  local xx,yy=x+math.cos(a)*spread,y+math.sin(a)*spread*.63
  local light=rand(j,seed+7);local warm=rand(seed,6)
  local color={.16+light*.13+warm*.13,.20+light*.13-warm*.035,.065+light*.035,1}
  leaf(xx,yy,5+rand(j,seed+3)*10,a,color)
 end
 -- A little light sits on leaf masses, without black outlines or vein patterns.
 for j=1,9 do
  local a=j*2.399+seed;local d=r*rand(j,seed+2)
  leaf(x+math.cos(a)*d-2,y+math.sin(a)*d*.5-4,4+rand(j,8)*5,a,{.49,.46,.20,.35})
 end
end
local function flower(x,y,seed)
 local g=love.graphics
 g.setColor(.25,.33,.12);g.ellipse('fill',x-2,y+2,4,1.5)
 for j=1,5 do local a=j*math.pi*.4;g.setColor(.79,.65,.35,.8);g.ellipse('fill',x+math.cos(a)*2.5,y+math.sin(a)*2,2,1.6) end
 g.setColor(.40,.27,.08);g.circle('fill',x,y,1.2)
end
function T.load(stream)
 if T.details then return end
 local g=love.graphics;T.details=g.newCanvas(1200,750)
 g.push('all');g.setCanvas(T.details);g.origin();g.setShader();g.clear(0,0,0,0)
 -- Translucent moss and silt blend into the same material as the clearing.
 for i=12,1,-1 do ribbon(stream,39+i,{.22,.29,.15,.065}) end
 ribbon(stream,38,{.075,.25,.25,1})
 for i=8,1,-1 do ribbon(stream,17+i*2,{.12,.36,.33,.09}) end
 for i=1,340 do
  local x,y=rand(i,1)*1200,rand(i,2)*750
  if math.abs(x-stream(y))>49 then
   local size=2+rand(i,4)*4
   leaf(x+1,y+1,size,rand(i,3)*6.28,{.12,.10,.035,.18})
   leaf(x,y,size,rand(i,3)*6.28,{.40+rand(i,5)*.18,.24+rand(i,6)*.15,.085,.65})
  end
 end
 -- Moss clumps and rounded stones interrupt the banks in little groups.
 for i=1,68 do
  local y=rand(i,21)*750
  if y<385 or y>470 then
   local side=i%2==0 and 1 or -1;local x=stream(y)+side*(43+rand(i,22)*13)
   if i%4==0 then
    g.setColor(.15,.19,.12,.35);g.ellipse('fill',x+2,y+3,8,5)
    g.setColor(.34,.36,.24);g.ellipse('fill',x,y,5+rand(i,23)*4,3+rand(i,24)*3)
    g.setColor(.48,.48,.32,.6);g.ellipse('fill',x-2,y-1,3,1.4)
   else
    for j=1,6 do leaf(x+(rand(j,i)-.5)*16,y+(rand(j,i+4)-.5)*9,3+rand(j,i+2)*4,j*2.399,{.27,.35,.14,.8}) end
    if i%5==0 then flower(x+7,y-3,i) end
   end
  end
 end
 local x=stream(425)
 g.setColor(.065,.07,.035,.25);g.ellipse('fill',x+2,432,64,32)
 -- Weathered planks have uneven ends; no hard square bridge frame.
 for i=0,10 do
  local xx=x-55+i*10;local dy=rand(i,32)*5
  g.setColor(.29+i%3*.022,.22+i%3*.012,.12)
  g.polygon('fill',xx,400+dy,xx+9,399+dy,xx+10,449-dy,xx+1,451-dy)
  g.setColor(.48,.37,.20,.4);g.setLineWidth(.8);g.line(xx+3,406+dy,xx+4,443-dy)
 end
 g.setColor(.24,.17,.08);g.setLineWidth(3);g.line(x-58,402,x-12,400,x+58,403);g.line(x-58,449,x+18,451,x+58,448)
 T.foliage=g.newCanvas(1200,750);g.setCanvas(T.foliage);g.clear(0,0,0,0)
 -- Irregular islands overlap the screen edge, with gaps and varying depth.
 for i=0,23 do
  local x=i*53+rand(i,40)*27
  shrub(x,rand(i,41)*19-4,23+rand(i,42)*28,i+10)
  shrub(x+rand(i,43)*20,748-rand(i,44)*16,23+rand(i,45)*30,i+50)
 end
 for i=1,13 do
  local y=i*56+rand(i,46)*27
  shrub(rand(i,47)*13-7,y,22+rand(i,48)*23,i+90)
  shrub(1198-rand(i,49)*12,y-15,25+rand(i,50)*26,i+120)
 end
 for i=1,32 do
  local x=rand(i,62)*1200;local y=i%2==0 and 42+rand(i,63)*14 or 705+rand(i,63)*17
  if math.abs(x-stream(y))>57 then flower(x,y,i) end
 end
 g.pop()
 T.sway=g.newShader([[extern number clock;
 vec4 effect(vec4 tint, Image tex, vec2 uv, vec2 p) {
  vec2 offset=vec2(sin(uv.y*24.+clock*.8)*.0013,cos(uv.x*31.+clock*.65)*.0008);
  return Texel(tex,uv+offset)*tint;
 }]])
end
function T.draw(stream,time)
 T.load(stream);local g=love.graphics
 require('biome_floor').draw(9,1200,750,0)
 g.push('all');g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(T.details)
 if not Graphics or Graphics.effects then T.sway:send('clock',time or 0);g.setShader(T.sway) end
 g.draw(T.foliage);g.pop()
end
function T.life(stream,time)
 local g=love.graphics;g.push('all')
 -- Small insects hover near the banks; wings brighten briefly as they turn.
 for i=1,12 do
  local y=75+(i*83)%610+math.sin(time*.6+i)*14
  local x=stream(y)+(i%2==0 and 1 or -1)*(65+math.sin(time*.45+i)*13)
  local wing=math.sin(time*15+i)*2
  g.setColor(.82,.83,.61,.38);g.ellipse('fill',x-2,y,2,math.abs(wing)*.5+.4);g.ellipse('fill',x+2,y,2,math.abs(wing)*.5+.4)
  g.setColor(.25,.29,.10,.7);g.circle('fill',x,y,1)
 end
 -- Faint drifting pollen, not strong beams or full-screen glow.
 for i=1,18 do
  local x=(i*137+time*3)%1200;local y=80+(i*93)%590+math.sin(time*.5+i)*7
  local a=.12+.13*(.5+.5*math.sin(time+i))
  g.setColor(.95,.81,.43,a);g.circle('fill',x,y,1.2)
 end
 g.pop()
end
return T
