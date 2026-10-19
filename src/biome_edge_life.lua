-- Deterministic perimeter decoration; visuals never consume gameplay randomness.
local E={}
local function noise(n)local v=math.sin(n*127.1)*43758.5453;return v-math.floor(v) end
local colors={[1]={1,.84,.38},[2]={1,.3,.04},[3]={.48,.94,.48},[4]={.25,.9,.85},[5]={.83,.72,.26},[6]={.67,.85,1},[7]={.15,.72,1},[8]={.63,.72,1}}
local function sides(draw)
 local g=love.graphics
 for side=1,4 do
  local x,y,a=0,600,0
  if side==2 then x,y,a=Arena.width,0,math.pi elseif side==3 then x,y,a=0,0,math.pi/2 elseif side==4 then x,y,a=Arena.width,600,-math.pi/2 end
  g.push();g.translate(x,y);g.rotate(a);draw(side<=2 and Arena.width or 600,side);g.pop()
 end
end
local function glow(x,y,r,c,a)
 local g=love.graphics
 for j=4,1,-1 do g.setColor(c[1],c[2],c[3],a*.045);g.circle('fill',x,y,r*j/4) end
 g.setColor(c[1],c[2],c[3],a);g.circle('fill',x,y,1.1)
end
function E.bake(biome)
 local g=love.graphics
 sides(function(length,side)
  for i=0,math.floor(length/65) do
   local seed=i+side*137;local x=i*65+noise(seed)*16
   if biome==4 then
    g.push();g.translate(x+20,-9);g.rotate((noise(seed)-.5)*.8)
    if i%3==0 then
     g.setColor(.82,.48,.43);local pts={}
     for j=0,9 do local a=j*math.pi/5;local r=j%2==0 and 13 or 5;pts[#pts+1]=math.cos(a)*r;pts[#pts+1]=math.sin(a)*r end
     g.polygon('fill',pts);g.setColor(1,.77,.6);g.circle('fill',0,0,2)
    else
     g.setColor(.65,.68,.59);g.arc('fill','pie',0,0,12,math.pi,math.pi*2)
     g.setColor(.91,.85,.71);g.setLineWidth(1)
     for j=1,5 do local a=math.pi+j*math.pi/6;g.line(0,0,math.cos(a)*11,math.sin(a)*11) end
    end
    g.pop()
   elseif biome==5 and i%2==0 then
    g.setColor(.18,.25,.08);g.setLineWidth(1.5)
    for j=1,5 do local xx=x+j*3;g.line(xx,0,xx-4,-12-j*2,xx+2,-18-j*2) end
   end
  end
 end)
end
function E.draw()
 local biome=Secret.inArena() and 8 or Campaign.biome
 if biome==6 or biome==7 then return end
 local g=love.graphics;local t=Graphics.effects and UI.clock or 0;local c=colors[biome] or colors[1]
 g.push('all');g.setShader();g.setLineWidth(1)
 if biome==7 or biome==4 or biome==5 then
  local target=g.getCanvas();local density=target and target:getDPIScale() or 1;local key=biome..':'..Arena.width..':'..density
  if E.key~=key then
   if E.canvas then E.canvas:release() end
   E.canvas=g.newCanvas(Arena.width,600,{dpiscale=density})
   g.push('all');g.setCanvas(E.canvas);g.origin();g.setScissor();g.clear();E.bake(biome);g.pop();E.key=key
  end
  g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(E.canvas);g.setBlendMode('alpha')
 end
 sides(function(length,side)
  local count=math.floor(length/(biome==7 and 260 or 90))
  for i=1,count do
   local seed=i+side*127;local x=(i-.5)*length/count;local phase=t*(.6+noise(seed)*.5)+seed
   if biome==1 or biome==3 or biome==5 then
    local sway=math.sin(phase)*6+math.sin(phase*1.7)*2
    local leafColor=biome==1 and {.55,.54,.26} or biome==3 and {.18,.32,.13} or {.30,.35,.12}
    g.setColor(leafColor);g.setLineWidth(1.2)
    g.line(x,0,x+sway*.35,-10,x+sway,-23)
    for j=1,3 do
     local y=-j*6;local xx=x+sway*(j/4)^2
     g.push();g.translate(xx,y);g.rotate(sway*.035)
     g.ellipse('fill',-3,-2,5,2);g.ellipse('fill',4,-4,5,2);g.pop()
    end
   end
   if biome==4 then
    -- Swaying anemones and deep-sea luminous feelers rooted in the rim.
    local h=24
    for j=-1,1 do
     local tip=x+j*4+math.sin(phase+j)*9
     g.setColor(c[1]*.4,c[2]*.5,c[3]*.5,.8);g.setLineWidth(2)
     g.line(x+j*3,-4,x+j*3+math.sin(phase)*2,-h*.55,tip,-h)
     glow(tip,-h,7,c,.55+.25*math.sin(phase+j))
    end
    if biome==4 then local rise=(t*12+seed*9)%42;g.setColor(.56,.88,1,(1-rise/42)*.45);g.circle('line',x+16+math.sin(phase)*3,-10-rise,2) end
   end
   local xx=x+math.sin(phase*.7)*16;local yy=-32-math.sin(phase*1.3)*9
   local alpha=.35+.25*math.sin(phase*2)
   glow(xx,yy,biome==7 and 5 or biome==2 and 9 or 12,c,biome==7 and alpha*.30 or alpha)
   if biome==1 or biome==3 or biome==5 then
    local wing=1.5+math.sin(t*18+seed)*1.2
    g.setColor(c[1],c[2],c[3],alpha*.7);g.ellipse('fill',xx-2,yy,wing,1.2);g.ellipse('fill',xx+2,yy,wing,1.2)
   elseif biome==6 then g.setColor(c[1],c[2],c[3],alpha*.4);g.line(xx-6,yy+2,xx+5,yy-2) end
  end
 end)
 g.pop()
end
return E
