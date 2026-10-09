local R={}
local colors={[1]={1,.82,.48},[3]={.7,.94,.48},[2]={1,.32,.12},[4]={.24,.85,.94},[5]={.85,.65,.40},[6]={.60,.72,1},[7]={.25,.65,1}}
function R.fog(front,demon)
 local g=love.graphics
 R.shader=R.shader or g.newShader([[
 extern float clock;extern float front;extern float demon;extern vec2 dimensions;
 float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
 float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
 float fbm(vec2 p){return noise(p)*.55+noise(p*2.1)*.28+noise(p*4.3)*.17;}
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px){
  vec2 p=(px*(dimensions.y/love_ScreenSize.y))/dimensions;vec2 drift=vec2(clock*.018,clock*.009);
  float n=fbm(p*vec2(4.,6.)+drift+fbm(p*3.-drift));
  float mist=smoothstep(.26,.75,n);
  float low=mix(.85,smoothstep(.34,.83,p.y),front);
  float clearBoss=1.-.60*exp(-dot((p-vec2(.5,.43))*vec2(3.,4.),(p-vec2(.5,.43))*vec2(3.,4.)));
  return vec4(mix(mix(vec3(.12,.19,.25),vec3(.39,.48,.56),n),mix(vec3(.25,.025,.045),vec3(.65,.14,.16),n),demon),mist*low*clearBoss*mix(.42,.40,front));
 }]])
 g.push('all');g.setShader(R.shader);R.shader:send('clock',UI.clock);R.shader:send('front',front and 1 or 0);R.shader:send('demon',demon and 1 or 0);R.shader:send('dimensions',{Arena.width,600});g.setColor(1,1,1);g.rectangle('fill',0,0,Arena.width,600);g.pop()
end
function R.dimensions(p)
 if p.kind~='boss' and not p.hardcore then return 64 end
 if p.type=='storm' then return 150 end
 if p.type=='merle' then return 220 end
 if p.type=='wasp' then return 96 end
 if p.type=='hedgehog' then return 104 end
 if p.type=='octopus' then return 230 end
 if p.type=='skeleton_head' then return 126,153 end
 return 100
end
local function sprite(p,x,y)
 local g=love.graphics;local size,height=R.dimensions(p)
 if p.type=='final_spider' then g.setColor(1,1,1);require('final_art').spider('queen',x,y,62,0);require('final_art').clutch(x,y,62,24);return end
 if p.type=='merle' then require('mobs.bosses.raven.egg').draw(x,y,60,0);return end
 local a=Art.images[p.art]
 local w,h=size,size*a.h/a.w
 if height then h=height else local s=size/math.max(a.w,a.h);w,h=a.w*s,a.h*s end
 local breath=p.type=='skeleton_head' and 1 or 1+math.sin(UI.clock*1.5)*.012
 g.setColor(.90,.93,1)
 if p.hardcore and p.type=='wasp' then g.setShader(Wasp.lavaMaterial(UI.clock)) end
 Art.draw(p.art,x,y,w,0,h*breath);g.setShader()
end
function R.boss(p,x,y)
 local g=love.graphics
 if p.type=='wasp' then
  for i=1,3 do sprite(p,x+(i-2)*145,y+(i==2 and -20 or 30)+math.sin(UI.clock*2+i)*4) end
 elseif p.type=='skeleton_head' then
  -- One shared transform keeps the head, ribs, spine and tail attached.
  g.push();g.translate(x,y+math.sin(UI.clock*.8)*10);g.scale(1,1+math.sin(UI.clock*1.5)*.012)
  local x,y=0,0
  for i=9,1,-1 do local xx=x+210-(45+i*37);local yy=y
   g.setColor(.66,.72,.77);Art.draw('skeleton_spine',xx,yy,42,0,25)
   Art.draw('skeleton_rib',xx,yy-32,18,0,58);Art.draw('skeleton_rib',xx,yy+32,18,math.pi,58)
  end
  g.setColor(.66,.72,.77);Art.draw('skeleton_tail',x-215,y,78,0,85)
  sprite(p,x+210,y);g.pop()
 else sprite(p,x,y) end
end
function R.hall(demon)
 local g=love.graphics;local w=Arena.width
 g.setColor(.009,.014,.022);g.rectangle('fill',0,0,w,600)
 -- Tall stone arches, recessed alcoves and a perspective processional floor.
 for i=0,8 do local x=i*w/8
  g.setColor(.025,.038,.052);g.rectangle('fill',x-15,30,30,510)
  g.setColor(.07,.085,.10,.5);g.rectangle('fill',x-17,40,3,475)
  g.setColor(.05,.067,.083);g.arc('line','open',x+w/16,150,w/16,math.pi,2*math.pi)
 end
 g.setColor(.017,.024,.031);g.polygon('fill',0,600,w,600,w*.68,350,w*.32,350)
 g.setColor(.10,.14,.17,.27);g.setLineWidth(1)
 for i=0,12 do g.line(w/2+(i-6)*22,350,(i-2)*w/8,600) end
 for i=1,7 do local y=350+(i/7)^1.8*250;g.line(0,y,w,y) end
 R.fog(false,demon)
end
-- Static veins: stable between encounters and independent of gameplay RNG.
function R.arena()
 local g=love.graphics;local w=Arena.width
 if R.marbleWidth~=w then
  if R.marble then R.marble:release() end
  R.marble=g.newCanvas(w,600);R.marbleWidth=w
  g.push('all');g.setCanvas(R.marble);g.origin();g.setScissor();g.setShader();g.clear(.012,.013,.017,1)
  for i=1,16 do
   local x=(i*173.7)%w;local y=-90+(i%4)*27;local points={x,y}
   for j=1,12 do
    x=x+math.sin(i*19.7+j*7.13)*38+math.cos(i*4.3)*24;y=y+48+math.sin(i*5.9+j*3.7)*18
    points[#points+1]=x;points[#points+1]=y
   end
   for layer=3,1,-1 do
    g.setLineWidth(layer==3 and 7 or layer==2 and 2.4 or .65)
    g.setColor(.88,.90,.94,layer==3 and .025 or layer==2 and .075 or .34);g.line(points)
   end
   g.setLineWidth(.5);g.setColor(.86,.88,.92,.2)
   for j=3,9,3 do local bx,by=points[j*2-1],points[j*2]
    g.line(bx,by,bx-24,by+13,bx-39,by+42,bx-70,by+49)
   end
  end
  g.pop()
 end
 g.push('all');g.setShader();g.setColor(1,1,1);g.draw(R.marble);g.pop()
end
local function throne(x,c,selected)
 local g=love.graphics
 local function stone(light,alpha) g.setColor(c[1]*light,c[2]*light,c[3]*light,alpha or 1) end
 g.setBlendMode('add')
 for i=7,1,-1 do
  g.setColor(c[1],c[2],c[3],selected and .023 or .01)
  g.ellipse('fill',x,280,55+i*12,100+i*12)
 end
 g.setBlendMode('alpha')
 -- A pointed stone back, carved ribs, raised arms and three broad steps.
 stone(.13);g.polygon('fill',x-72,405,x-78,215,x-36,155,x,106,x+36,155,x+78,215,x+72,405)
 stone(.48);g.setLineWidth(4);g.line(x-72,405,x-78,215,x-36,155,x,106,x+36,155,x+78,215,x+72,405)
 stone(.045);g.polygon('fill',x-55,364,x-56,228,x,152,x+56,228,x+55,364)
 g.setColor(c[1],c[2],c[3],selected and .8 or .3);g.setLineWidth(1.5)
 g.line(x-45,334,x-45,233,x,171,x+45,233,x+45,334)
 for side=-1,1,2 do
  local sx=x+side*78
  stone(.20);g.rectangle('fill',sx-11,288,22,115,4)
  stone(.55);g.polygon('fill',sx-15,288,sx,267,sx+15,288,sx,301)
  stone(.28);g.rectangle('fill',sx-18,342,36,13,3)
  stone(.44);g.line(sx-7,309,sx-7,397)
 end
 stone(.3);g.polygon('fill',x-65,363,x+65,363,x+77,382,x-77,382)
 for i=1,3 do
  local width=162+i*14;local y=389+i*12
  stone(.10+i*.025);g.rectangle('fill',x-width/2,y,width,12,2)
  stone(.48,.6);g.line(x-width/2+2,y,x+width/2-2,y)
 end
 g.setColor(.53,.66,.76,.27);g.setLineWidth(.7)
 for side=-1,1,2 do
  g.line(x+side*77,217,x+side*108,159,x+side*118,236)
  g.line(x+side*77,217,x+side*100,185,x+side*116,212)
 end
end
function R.draw(S)
 local g=love.graphics;local w=Arena.width;local camera=S.cameraX or 0
 g.push('all');g.setShader();R.hall(false)
 g.setColor(.025,.038,.054);g.rectangle('fill',0,443,w,157)
 g.setColor(.13,.18,.23);g.setLineWidth(2);g.line(0,548,w,548)
 for i=math.floor(camera/95)-1,math.ceil((camera+w)/95)+1 do
  local x=i*95-camera
  g.setColor(.06,.09,.12);g.polygon('fill',x,552,x+87,552,x+106,584,x-14,584)
  g.setColor(.19,.25,.30,.5);g.line(x,552,x+87,552)
 end
 g.push();g.translate(-camera,0)
 for i,entry in ipairs(S.portals) do
  local x=S.position(i)
  if x>camera-480 and x<camera+w+480 then
   local c=colors[Worlds.biome(entry.world)] or colors[7];local selected=math.abs(S.x-x)<58
   if entry.type=='wasp' then
    for sister=1,3 do
     g.push();g.translate(x+(sister-2)*145,437);g.scale(.68,1);g.translate(0,-437)
     throne(0,c,selected);g.pop()
    end
   else throne(x,c,selected) end
   g.push();g.translate(x,315);R.boss(entry,0,0);g.pop()
   local name=entry.type=='skeleton_head' and 'Le Monstre d’os' or entry.name
   name=UI.ellipsize(require('localization').render(name),'body',250)
   UI.rawText(name,x-125,453,'body',selected and {1,.94,.72} or {.68,.77,.83},250,'center')
   if selected then
    g.setColor(.86,.94,1,.8);g.setLineWidth(2);g.line(x-8,491,x,483,x+8,491)
   end
  end
 end
 g.setColor(0,0,0,.6);g.ellipse('fill',S.x,S.y+24,24,8)
 g.setColor(1,1,1);Characters.draw(S.x,S.y,62,S.facing or 'right')
 g.pop()
 R.fog(true,false)
 g.setColor(.008,.013,.023,.8);g.rectangle('fill',0,584,w,16)
 g.pop()
end
return R
