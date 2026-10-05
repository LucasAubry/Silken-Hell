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
 if p.type=='storm' then return 270 end
 if p.type=='merle' then return 220 end
 if p.type=='wasp' then return 190 end
 if p.type=='hedgehog' then return 250 end
 if p.type=='octopus' then return 360 end
 if p.type=='skeleton_head' then return 190,230 end
 return 100
end
local function sprite(p,x,y)
 local g=love.graphics;local size,height=R.dimensions(p)
 if p.type=='final_spider' then g.setColor(1,1,1);require('final_art').spider('queen',x,y,110,0);require('final_art').clutch(x,y,110,24);return end
 if p.type=='merle' then require('mobs.bosses.raven.egg').draw(x,y,100,0);return end
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
  for i=8,1,-1 do local xx=x+150-i*48;local yy=y
   g.setColor(.66,.72,.77);Art.draw('skeleton_spine',xx,yy,58,0,35)
   Art.draw('skeleton_rib',xx,yy-43,24,0,86);Art.draw('skeleton_rib',xx,yy+43,24,math.pi,86)
  end
  g.setColor(.66,.72,.77);Art.draw('skeleton_tail',x-300,y,110,0,145)
  sprite(p,x+200,y);g.pop()
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
function R.draw(S)
 local g=love.graphics;local w=Arena.width;local hero=S.perPage==1;local p=S.portals[1];local tint=S.hardcore and {1,.18,.12} or colors[p and Worlds.biome(p.world) or 7] or colors[7]
 g.push('all');g.setShader();g.setColor(.009,.014,.022);g.rectangle('fill',0,0,w,600)
 R.arena(S.hardcore)
 local count=hero and 1 or #S.portals
 for i=1,count do
  local entry=S.portals[i];local x,y=S.position(i);local by=hero and 245 or y-62
  local c=S.hardcore and tint or colors[Worlds.biome(entry.world)] or tint
  g.setBlendMode('add')
  for layer=12,1,-1 do
   g.setColor(c[1],c[2],c[3],.007);g.ellipse('fill',x,by,50+layer*(hero and 16 or 6),45+layer*(hero and 13 or 5))
   if hero then g.setColor(c[1],c[2],c[3],.007);g.polygon('fill',x-18-layer*2,0,x+18+layer*2,0,x+100+layer*9,410,x-100-layer*9,410) end
  end
  g.setBlendMode('alpha')
  if hero then
   g.setColor(.035,.045,.055);g.ellipse('fill',x,400,220,47)
   g.setColor(c[1],c[2],c[3],.32);g.ellipse('line',x,400,215,44)
  else
   g.setColor(0,0,0,.45);g.ellipse('fill',x,by+27,29,9)
   g.setColor(c[1],c[2],c[3],.08);g.ellipse('fill',x,y,44,21)
  end
  if hero then
   g.push();g.translate(x,by);g.scale(.75,.75);R.boss(entry,0,0);g.pop()
  else sprite(entry,x,by) end
  UI.text(entry.type=='skeleton_head' and 'Le Monstre d’os' or entry.name,x-(hero and 260 or 125),hero and 435 or y+30,hero and 'medium' or 'small',{c[1],c[2],c[3]},hero and 520 or 250,'center')
  local near=(S.x-x)^2+(S.y+22-y)^2<90^2
  g.setColor(c[1],c[2],c[3],near and .85 or .4);g.setLineWidth(2)
  g.ellipse('line',x,y,38,17);g.ellipse('line',x,y,44,21)
  for j=1,8 do local a=j*math.pi/4+UI.clock*.12;g.circle('fill',x+math.cos(a)*41,y+math.sin(a)*19,1.5) end
  if S.charging==i then g.push();g.translate(x,y);g.scale(1,17/38);g.setColor(1,.94,.65);g.setLineWidth(4);g.arc('line','open',0,0,38,-math.pi/2,-math.pi/2+math.max(.001,(S.charge or 0)/1.4)*math.pi*2);g.pop() end
 end
 -- Floating dust catches the light; the foreground mist stays below faces.
 for i=1,55 do local x=(i*139.7+math.sin(UI.clock*.3+i)*15)%w;local y=(i*83-UI.clock*(3+i%5))%570
  g.setColor(tint[1],tint[2],tint[3],.13+.16*(.5+.5*math.sin(UI.clock+i)));g.circle('fill',x,y,i%5==0 and 1.8 or .8)
 end
 R.fog(true,S.hardcore)
 g.setColor(.008,.012,.02,.65);g.rectangle('fill',0,0,24,600);g.rectangle('fill',w-24,0,24,600)
 g.setColor(tint[1],tint[2],tint[3],.7);g.setLineWidth(2)
 if S.page>1 then g.line(43,450,32,462,43,474) end
 if S.page<S.pages then g.line(w-43,450,w-32,462,w-43,474) end
 g.setColor(0,0,0,.6);g.ellipse('fill',S.x,S.y+22,22,9)
 for i=3,1,-1 do g.setColor(.6,.78,1,.023);g.ellipse('fill',S.x,S.y+10,22+i*10,12+i*5) end
 g.setColor(1,1,1);Characters.draw(S.x,S.y,62,S.facing or 'down');g.pop()
end
return R
