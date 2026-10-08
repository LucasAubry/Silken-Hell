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
 if p.type=='octopus' then return 360 end
 if p.type=='skeleton_head' then return 180,219 end
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
  for i=9,1,-1 do local xx=x+350-(65+i*62);local yy=y
   g.setColor(.66,.72,.77);Art.draw('skeleton_spine',xx,yy,68,0,34)
   Art.draw('skeleton_rib',xx,yy-45,24,0,80);Art.draw('skeleton_rib',xx,yy+45,24,math.pi,80)
  end
  g.setColor(.66,.72,.77);Art.draw('skeleton_tail',x-365,y,110,0,120)
  sprite(p,x+350,y);g.pop()
 else sprite(p,x,y) end
end
function R.arena(demon)
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
local function throne(x,c,selected)
 local g=love.graphics
 g.setBlendMode('add')
 for i=7,1,-1 do
  g.setColor(c[1],c[2],c[3],selected and .023 or .01)
  g.ellipse('fill',x,280,55+i*12,100+i*12)
 end
 g.setBlendMode('alpha')
 -- A pointed stone back, carved ribs, raised arms and three broad steps.
 g.setColor(.055,.085,.12);g.polygon('fill',x-72,405,x-78,215,x-36,155,x,106,x+36,155,x+78,215,x+72,405)
 g.setColor(.23,.32,.40);g.setLineWidth(4);g.line(x-72,405,x-78,215,x-36,155,x,106,x+36,155,x+78,215,x+72,405)
 g.setColor(.016,.025,.045);g.polygon('fill',x-55,364,x-56,228,x,152,x+56,228,x+55,364)
 g.setColor(c[1],c[2],c[3],selected and .8 or .3);g.setLineWidth(1.5)
 g.line(x-45,334,x-45,233,x,171,x+45,233,x+45,334)
 for side=-1,1,2 do
  local sx=x+side*78
  g.setColor(.09,.13,.17);g.rectangle('fill',sx-11,288,22,115,4)
  g.setColor(.28,.37,.43);g.polygon('fill',sx-15,288,sx,267,sx+15,288,sx,301)
  g.setColor(.13,.18,.23);g.rectangle('fill',sx-18,342,36,13,3)
  g.setColor(.22,.3,.36);g.line(sx-7,309,sx-7,397)
 end
 g.setColor(.14,.19,.24);g.polygon('fill',x-65,363,x+65,363,x+77,382,x-77,382)
 for i=1,3 do
  local width=162+i*14;local y=389+i*12
  g.setColor(.055+i*.015,.078+i*.018,.11+i*.02);g.rectangle('fill',x-width/2,y,width,12,2)
  g.setColor(.25,.33,.39,.6);g.line(x-width/2+2,y,x+width/2-2,y)
 end
 g.setColor(.53,.66,.76,.27);g.setLineWidth(.7)
 for side=-1,1,2 do
  g.line(x+side*77,217,x+side*108,159,x+side*118,236)
  g.line(x+side*77,217,x+side*100,185,x+side*116,212)
 end
end
function R.draw(S)
 local g=love.graphics;local w=Arena.width;local camera=S.cameraX or 0
 g.push('all');g.setShader();R.arena(false)
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
   throne(x,c,selected)
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
