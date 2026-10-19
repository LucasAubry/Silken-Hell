-- Obsidian and scorched iron frame; only fire and embers animate.
local F={}
local function noise(i) local n=math.sin(i*127.1+311.7)*43758.5453;return n-math.floor(n) end
local function curve(p) return love.math.newBezierCurve(p):render(4) end
local function spike(x,y,h,lean)
 local g=love.graphics;local w=h*.27
 g.setColor(.065,.043,.048);g.polygon('fill',x-w,y,x-w*.6,y-h*.45,x+lean,y-h,x+w*.7,y-h*.29,x+w,y)
 g.setColor(.24,.12,.105);g.polygon('fill',x-w,y,x-w*.6,y-h*.45,x+lean,y-h,x-1,y-3)
 g.setColor(.46,.22,.13);g.setLineWidth(.9);g.line(x-w*.6,y-h*.45,x+lean,y-h,x-1,y-3)
end
local function fire(x,y,h,seed,time)
 local g=love.graphics
 local pulse=.85+.15*math.sin(time*3.1+seed)
 for j=6,1,-1 do
  g.setColor(1,.22,.035,.012*pulse);g.ellipse('fill',x,y-h*.25,h*j*.27,h*j*.20)
 end
 -- Three overlapping tongues, with tapered translucent edges and pale cores.
 -- Flame tips follow the inward normal of their supporting wall.
 for tongue=1,3 do
  local phase=seed+tongue*2.7
  local height=h*(tongue==2 and 1 or .65)*(.9+.1*math.sin(time*3.3+phase))
  local bx=x+(tongue-2)*h*.16
  local bend=(math.sin(time*2.4+phase)+.35*math.sin(time*5.1+phase))*h*.12
  for layer=1,4 do
   local scale=1-(layer-1)*.18
   local hh=height*scale;local w=h*.19*scale
   local tip=bx+bend*scale
   local points=curve({bx-w,y,bx-w*1.8,y-hh*.30,tip-w*.3,y-hh*.72,tip,y-hh})
   local right=curve({tip,y-hh,tip+w*.6,y-hh*.52,bx+w*1.5,y-hh*.23,bx+w,y})
   for i=3,#right do points[#points+1]=right[i] end
   local colors={{.88,.12,.015,.28},{1,.30,.025,.52},{1,.58,.10,.70},{1,.88,.46,.85}}
   g.setColor(colors[layer]);g.polygon('fill',points)
  end
 end
 for j=1,3 do
  local t=(time*(.45+j*.06)+noise(seed+j))%1
  local xx=x+math.sin(t*5+seed+j)*h*.18;local yy=y-h*(.3+t*1.1)
  g.setColor(1,.59,.14,math.sin(t*math.pi)*.65);g.ellipse('fill',xx,yy,.7,1.6)
 end
end
function F.bake(width,height)
 local g=love.graphics;F.fires={};F.embers={}
 for side=1,4 do
  local ox,oy,angle=0,height,0
  if side==2 then ox,oy,angle=width,0,math.pi
  elseif side==3 then ox,oy,angle=0,0,math.pi/2
  elseif side==4 then ox,oy,angle=width,height,-math.pi/2 end
  local length=side<=2 and width or height
  g.push();g.translate(ox,oy);g.rotate(angle)
  for i=0,math.ceil(length/44) do
   local seed=side*401+i*17;local x=i*44;local d=18+noise(seed)*16
   g.setColor(.055,.028,.034);g.polygon('fill',x-7,8,x-5,-d*.7,x+8,-d,x+29,-d+4,x+48,-d*.65,x+49,8)
   g.setColor(.22,.10,.085);g.polygon('fill',x-5,-d*.7,x+8,-d,x+29,-d+4,x+48,-d*.65,x+26,-d*.35,x+5,-d*.4)
   g.setColor(.42,.20,.12);g.setLineWidth(1);g.line(x-5,-d*.7,x+8,-d,x+29,-d+4)
   local crack={x+9,-d+2,x+17,-d*.60,x+13,-d*.32,x+23,3}
   g.setColor(.62,.10,.025,.55);g.setLineWidth(4);g.line(crack)
   g.setColor(1,.40,.06,.85);g.setLineWidth(1);g.line(crack)
   local motif=(i+side*3)%8
   if motif==0 or motif==3 then
    spike(x+17,-9,38+noise(seed+2)*30,(noise(seed+8)-.5)*20)
    spike(x+32,-7,24+noise(seed+3)*17,8)
   elseif motif==1 then
    -- Curved burnt thorns, highlighted by the lava below.
    local p=curve({x+7,2,x+34,-20,x-4,-35,x+23,-56})
    g.setColor(.025,.015,.022);g.setLineWidth(7);g.line(p)
    g.setColor(.30,.10,.06);g.setLineWidth(1.2);g.line(p)
    spike(x+16,-24,14,-12);spike(x+13,-38,11,10)
   elseif motif==2 or motif==6 then
    F.fires[#F.fires+1]={ox+(x+21)*math.cos(angle)+12*math.sin(angle),oy+(x+21)*math.sin(angle)-12*math.cos(angle),angle,21+noise(seed+6)*14,seed}
   elseif motif==5 then
    -- Charred, curling roots replace the broad block-like stones.
    for j=1,3 do
     local xx=x+7+j*8;local h=26+noise(seed+j)*22
     local p=curve({xx,-3,xx-13,-h*.35,xx+12,-h*.65,xx+5,-h})
     g.setColor(.075,.025,.025);g.setLineWidth(5);g.line(p)
     g.setColor(.52,.15,.045);g.setLineWidth(1);g.line(p)
     spike(xx+5,-h+5,10,5)
    end
   elseif motif==7 then
    for j=1,3 do
     local h=22+noise(seed+j)*30;local xx=x+7+j*8
     spike(xx,-4,h,(noise(seed+j)-.5)*12)
     g.setColor(.75,.25,.07,.75);g.setLineWidth(.8);g.line(xx-2,-h*.8,xx+1,-h*.4,xx,-7)
    end
   else
    -- Broken iron links embedded in the rim.
    for j=1,4 do
     g.push();g.translate(x+11+j*3,-6-j*8);g.rotate(j%2==0 and .4 or -.3)
     g.setColor(.025,.02,.025);g.setLineWidth(4);g.ellipse('line',0,0,4,7)
     g.setColor(.35,.18,.13);g.setLineWidth(1);g.arc('line','open',0,0,5,math.pi,math.pi*2);g.pop()
    end
   end
   F.embers[#F.embers+1]={ox+(x+22)*math.cos(angle)+35*math.sin(angle),oy+(x+22)*math.sin(angle)-35*math.cos(angle),seed,angle}
  end
  g.pop()
 end
end
function F.draw()
 if Campaign.biome~=2 or Secret.inArena() then return end
 local g=love.graphics;local target=g.getCanvas();local density=target and target:getDPIScale() or 1
 local key=Arena.width..':'..density
 if F.key~=key then
  if F.canvas then F.canvas:release() end
  F.canvas=g.newCanvas(Arena.width,600,{dpiscale=density});F.canvas:setFilter('linear','linear')
  g.push('all');g.setCanvas(F.canvas);g.origin();g.setScissor();g.setShader();g.setBlendMode('alpha','alphamultiply');g.clear(0,0,0,0)
  F.bake(Arena.width,600)
  -- Match Paradise's subtle cached soft focus without blurring gameplay.
  F.blur=F.blur or g.newShader('assets/shaders/paradise_frame_blur.glsl')
  local soft=g.newCanvas(Arena.width,600,{dpiscale=density});soft:setFilter('linear','linear')
  g.setCanvas(soft);g.clear(0,0,0,0);g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.setShader(F.blur)
  F.blur:send('stepUV',{.15/Arena.width,0});g.draw(F.canvas)
  g.setCanvas(F.canvas);g.clear(0,0,0,0);F.blur:send('stepUV',{0,.15/600});g.draw(soft)
  g.pop();soft:release();F.key=key
 end
 g.push('all');g.setShader();g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(F.canvas)
 g.setBlendMode('alpha','alphamultiply');local time=Graphics.effects and UI.clock or 0
 for _,v in ipairs(F.fires) do
  g.push();g.translate(v[1],v[2]);g.rotate(v[3]);fire(0,0,v[4],v[5],time);g.pop()
 end
 for _,v in ipairs(F.embers) do
  local t=(time*.18+noise(v[3]))%1;local a=math.sin(t*math.pi)*.7
  local drift=math.sin(t*4+v[3])*3
  local x=v[1]+drift*math.cos(v[4])+t*24*math.sin(v[4]);local y=v[2]+drift*math.sin(v[4])-t*24*math.cos(v[4])
  g.setColor(1,.28,.04,a*.18);g.circle('fill',x,y,4)
  g.setColor(1,.65,.22,a);g.circle('fill',x,y,1.1)
 end
 g.pop()
end
return F
