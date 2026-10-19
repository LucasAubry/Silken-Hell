-- Native biome material and foliage, with the opening's autumn palette.
local T={}
local function rand(i,s)local n=math.sin(i*127.1+s*311.7)*43758.5453;return n-math.floor(n)end
local function ribbon(stream,width,color)
 local g=love.graphics;g.setColor(color)
 for y=-12,750,12 do
  local a,b=stream(y),stream(y+12)
  local wa=width+math.sin(y*.041)*2.5;local wb=width+math.sin((y+12)*.041)*2.5
  g.polygon('fill',a-wa,y,a+wa,y,b+wb,y+12,b-wb,y+12)
 end
end
function T.load(stream)
 if T.details then return end
 local g=love.graphics;T.details=g.newCanvas(1200,750)
 g.push('all');g.setCanvas(T.details);g.origin();g.setShader();g.clear(0,0,0,0)
 ribbon(stream,49,{.12,.105,.055,1});ribbon(stream,44,{.28,.31,.16,1})
 ribbon(stream,38,{.055,.22,.23,1});ribbon(stream,29,{.09,.30,.30,1})
 -- Small leaf clusters keep the material legible instead of painting over it.
 for i=1,620 do
  local x,y=rand(i,1)*1200,rand(i,2)*750
  if math.abs(x-stream(y))>49 then
   local size=2+rand(i,4)*5;g.push();g.translate(x,y);g.rotate(rand(i,3)*6.28)
   g.setColor(.16,.09,.035,.4);g.ellipse('fill',1,2,size,size*.42)
   g.setColor(.38+rand(i,5)*.20,.19+rand(i,6)*.14,.055,.8)
   g.polygon('fill',-size,0,-size*.25,-size*.55,size,0,size*.25,size*.5)
   g.setColor(.72,.45,.17,.38);g.setLineWidth(.6);g.line(-size*.6,0,size*.7,0);g.pop()
  end
 end
 local x=stream(425)
 g.setColor(.065,.07,.035,.5);g.rectangle('fill',x-56,401,112,55)
 for i=0,10 do
  local xx=x-55+i*10
  g.setColor(.26+i%3*.025,.17+i%3*.016,.085);g.rectangle('fill',xx,400,9,50)
  g.setColor(.49,.34,.16,.7);g.setLineWidth(1);g.line(xx+2,403,xx+2,446)
 end
 g.setColor(.16,.105,.05);g.setLineWidth(5);g.line(x-60,400,x+60,400);g.line(x-60,450,x+60,450)
 -- Reuse Renaissance's foliage drawing without touching campaign state.
 T.foliage=g.newCanvas(1200,750);g.setCanvas(T.foliage);g.clear(0,0,0,0)
 for i=0,30 do
  local x=i*40
  require('foliage').bush(x,18+rand(i,9)*25,28+rand(i,10)*17,i)
  require('foliage').bush(x,738-rand(i,11)*14,24+rand(i,12)*14,i+31)
 end
 for i=1,17 do
  local y=i*42
  require('foliage').bush(12,y,25+rand(i,14)*13,i+60)
  require('foliage').bush(1190,y,28+rand(i,15)*16,i+90)
 end
 require('renaissance_frame').bake(1200,750)
 g.pop()
 T.autumn=g.newShader([[vec4 effect(vec4 tint, Image tex, vec2 uv, vec2 p) {
  vec4 c=Texel(tex,uv);return vec4(c.r*.8+c.g*.66,c.g*.66+c.r*.12,c.b*.63,c.a)*tint;
 }]])
end
function T.draw(stream,time)
 T.load(stream);local g=love.graphics
 require('biome_floor').draw(9,1200,750,0)
 g.push('all');g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(T.details)
 g.setShader(T.autumn);g.draw(T.foliage);g.pop()
end
return T
