-- Use the gameplay floors themselves so cinematic palettes and textures match the level.
local S={floors={}}
function S.floor(world,w,h,alpha)
 local g=love.graphics;local cache=S.floors[world]
 if not cache or cache.w~=w or cache.h~=h then
  if cache then cache.canvas:release() end
  cache={w=w,h=h,canvas=g.newCanvas(w,h,{dpiscale=1})};S.floors[world]=cache
  local previous=g.getCanvas();g.push('all');g.setCanvas(cache.canvas);g.origin();g.setScissor();g.clear()
  require('biome_floor').draw(world,w,h,0)
  g.setCanvas(previous);g.pop()
 end
 g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied')
 local a=alpha or 1;g.setColor(a,a,a,a)
 -- Keep the sky's gameplay texture, but crop its arena border during flight.
 local zoom=world==6 and 1.16 or 1
 g.draw(cache.canvas,w*(1-zoom)/2,h*(1-zoom)/2,0,zoom,zoom);g.pop()
end
-- Cinematic landscapes share the palette, with their own drifting depth and lighting.
function S.backdrop(world,w,h,time,alpha,depth)
 local g=love.graphics
 if world==6 then require('sky_arrival').drawAtmosphere(w,h,time*.25,0,alpha);return end
 S.landscape=S.landscape or g.newShader([[
  extern vec2 dimensions;extern float clock;extern float world;extern float opacity;extern float depth;
  float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
  float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
  float fbm(vec2 p){return noise(p)*.57+noise(p*2.1)*.28+noise(p*4.3)*.15;}
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
   vec2 q=pixel/dimensions;vec2 p=(pixel-dimensions*.5)/dimensions.y;
   vec2 drift=vec2(clock*.025,depth*.55-clock*.009);
   float n=fbm(p*5.+drift+vec2(4.,9.));vec3 c;
   if(world<4.5){
    float waves=fbm(p*8.+drift*1.8+vec2(sin(q.y*5.+clock*.3)*.12,0.));
    float rays=pow(max(0.,sin(q.x*18.+q.y*2.+clock*.16)),12.)*(1.-q.y*.65);
    c=mix(vec3(.025,.15,.23),vec3(.075,.37,.41),n);
    c+=vec3(.075,.15,.13)*rays+vec3(.025,.065,.055)*smoothstep(.48,.62,waves);
   }else{
    vec2 stone=p+vec2(0.,depth*.55);
    float sediment=fbm(stone*vec2(18.,8.));
    float grain=noise(stone*240.);
    float strata=sin(stone.y*90.+fbm(stone*7.)*13.);
    float ridge=pow(1.-abs(strata),5.);
    float moss=smoothstep(.52,.75,fbm(stone*15.+vec2(7.,3.)));
    c=mix(vec3(.075,.065,.045),vec3(.39,.245,.115),sediment);
    c=mix(c,vec3(.16,.29,.12),moss*.65);
    c+=vec3(.11,.065,.025)*ridge+(grain-.5)*.045;
    float glow=pow(max(0.,sin(stone.x*21.+stone.y*9.)),30.)*smoothstep(.67,.83,noise(stone*32.));
    c+=vec3(.12,.40,.30)*glow*(.8+.2*sin(clock*1.2));
    float side=smoothstep(.23,.8,abs(p.x));c*=1.-side*.35;
   }
   return vec4(c,opacity);
  }
 ]])
 S.landscape:send('dimensions',{w,h});S.landscape:send('clock',time);S.landscape:send('world',world)
 S.landscape:send('opacity',alpha or 1);S.landscape:send('depth',depth or 0)
 g.setColor(1,1,1);g.setShader(S.landscape);g.rectangle('fill',0,0,w,h);g.setShader()
end
-- Continuous eroded walls: ledges, overhangs and mineral seams instead of stacked stones.
function S.grotto(w,h,time,camera,alpha,abyss)
 local g=love.graphics
 S.grottoShader=S.grottoShader or g.newShader([[
 extern vec2 dimensions;extern float clock;extern float camera;extern float opacity;extern float abyss;
 float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
 float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
 float fbm(vec2 p){return noise(p)*.6+noise(p*2.1)*.27+noise(p*4.4)*.13;}
 vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
  vec2 q=pixel/dimensions+vec2(clock*.045*abyss,camera);
  float ceiling=.025+.095*fbm(vec2(q.x*9.,2.));
  for(int i=0;i<6;i++){
   float k=float(i);float x=.04+k*.19;
   ceiling+=exp(-pow((q.x-x)*65.,2.))*(.025+.04*hash(vec2(k,7.)));
  }
  float top=.55+sin(q.x/.47*9.)*.004;
  float edge=.47+.035*sin((q.y-.55)*18.)+.018*fbm(q*27.);
  float ledge=min(q.y-top,edge-q.x);
  float wall=.025+.035*fbm(vec2(q.y*9.,4.))-q.x;
  float distance=max(max(ceiling-q.y,wall),ledge);
  if(abyss>.5) distance=max(ceiling-q.y,q.y-(.94-.05*fbm(vec2(q.x*8.,9.))));
  float mask=smoothstep(-.002,.002,distance);
  float strata=sin(q.y*120.+fbm(q*vec2(11.,6.))*10.);
  float grain=fbm(q*vec2(50.,95.));
  float seam=pow(1.-abs(strata),12.);
  vec3 rock=mix(vec3(.095,.073,.055),vec3(.40,.29,.17),grain);
  rock*=.68+.32*smoothstep(-.3,.6,strata);
  rock+=vec3(.12,.08,.035)*seam;
  float moss=smoothstep(.57,.78,fbm(q*20.))*exp(-max(0.,distance)*22.);
  rock=mix(rock,vec3(.20,.32,.13),moss*.7);
  float rim=exp(-max(0.,distance)*110.);
  rock+=vec3(.19,.14,.075)*rim;
  float wet=smoothstep(.62,.85,grain)*pow(max(0.,sin(q.x*38.+q.y*6.+clock*.3)),14.);
  rock+=vec3(.055,.12,.12)*wet;
  rock=mix(rock,rock*vec3(.35,.66,.92),abyss);
  return vec4(rock,mask*opacity);
 }
 ]])
 S.grottoShader:send('dimensions',{w,h});S.grottoShader:send('clock',time);S.grottoShader:send('camera',camera or 0)
 S.grottoShader:send('opacity',alpha);S.grottoShader:send('abyss',abyss and 1 or 0)
 g.push('all');g.setShader(S.grottoShader);g.setColor(1,1,1);g.rectangle('fill',0,0,w,h);g.pop()
end
-- Soft depth veil, shared by all cinematic handoffs; no cut or black frame.
function S.mist(w,h,time,strength,water)
 if strength<=0 then return end
 local g=love.graphics
 S.veil=S.veil or g.newShader(love.filesystem.read('assets/shaders/sky_clouds.glsl')..[[
  extern vec2 dimensions;extern float clock;extern float strength;extern float water;
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
   vec2 p=(pixel-dimensions*.5)/dimensions.y;
   float n=skyNoise(p*3.+vec2(clock*.10,-clock*.12))*.65+skyNoise(p*7.+vec2(-clock*.08,clock*.05))*.35;
   float veil=smoothstep(.23,.76,n);
   vec3 tint=mix(vec3(.57,.51,.38),vec3(.32,.66,.74),water);
   return vec4(tint,veil*strength);
  }
 ]])
 g.push('all');g.setShader(S.veil)
 S.veil:send('dimensions',{w,h});S.veil:send('clock',time);S.veil:send('strength',strength);S.veil:send('water',water or 0)
 g.setColor(1,1,1);g.rectangle('fill',0,0,w,h);g.pop()
end
-- A stationary destination and its creatures are revealed separately under the same fog.
function S.reveal(canvas,environment,w,h,mapAlpha,actorsAlpha,shader,offsetX)
 if mapAlpha<=0 then return end
 local g=love.graphics;local scale,x,y=App.viewport(w,h)
 g.push('all');g.translate(offsetX or 0,0);g.setShader(shader);g.setBlendMode('alpha','premultiplied')
 g.setColor(mapAlpha,mapAlpha,mapAlpha,mapAlpha);g.draw(environment or canvas,x,y,0,scale,scale)
 if actorsAlpha>0 then
  g.setColor(actorsAlpha,actorsAlpha,actorsAlpha,actorsAlpha);g.draw(canvas,x,y,0,scale,scale)
 end
 g.pop()
end
local function grainShader()
 S.grain=S.grain or love.graphics.newShader([[
  extern float wood;
  float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
  float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
   vec2 p=floor(pixel/2.);float n=noise(p*mix(vec2(.04,.06),vec2(.13,.009),wood));
   float fine=noise(p*.7);float grooves=smoothstep(.35,.46,n);
   float value=.60+.55*n+.20*fine;
   value*=.60+.40*grooves;
   return vec4(color.rgb*value,color.a);
  }
 ]])
 return S.grain
end
function S.material(wood)
 local shader=grainShader();shader:send('wood',wood and 1 or 0);love.graphics.setShader(shader)
end
function S.rock(x,y,r,seed,alpha)
 local g=love.graphics;local points={}
 for i=0,47 do
  local a=i*math.pi/24;local radius=r*(.90+.055*math.sin(seed*5+a*3)+.035*math.sin(a*5+seed))
  points[#points+1]=x+math.cos(a)*radius;points[#points+1]=y+math.sin(a)*radius*.72
 end
 S.material(false);g.setColor(.37,.27,.15,alpha);g.polygon('fill',points);g.setShader()
 -- Fine mineral seams and patches of moss break up the rounded rock surface.
 for j=1,4 do
  local line={}
  for i=0,16 do
   local u=i/16;line[#line+1]=x-r*.65+u*r*1.3
   line[#line+1]=y+r*((j-2.5)*.22+math.sin(u*5+seed+j)*.045)
  end
  g.setColor(.61,.41,.20,(alpha or 1)*.30);g.setLineWidth(1);g.line(line)
 end
 for i=1,9 do
  local u=(i*.618+seed*.13)%1
  g.setColor(.22,.38,.13,(alpha or 1)*.65)
  g.ellipse('fill',x+(u-.5)*r*1.4,y-r*.38+math.sin(i+seed)*r*.1,r*.10,r*.045,20)
 end
end
function S.caveEdges(w,h,t,depth,alpha)
 if alpha<=0 then return end
 local g=love.graphics
 for side=-1,1,2 do
  for i=-1,8 do
   local ry=(i*.18-depth*.38)*h
   local rx=(side<0 and -.025 or 1.025)*w+math.sin(i*1.7)*w*.025
   S.rock(rx,ry,w*(.105+.015*math.sin(i)),i+5,alpha)
   local mx=rx-side*w*.09
   S.mushroom(mx,ry+h*.015,w*.014,alpha)
  end
 end
 for i=1,26 do
  local x=w*(.07+((i*.618)%1)*.86)+math.sin(t*.7+i)*5
  local y=h*((i*.173-t*.018+depth*.2)%1)
  local pulse=.5+.5*math.sin(t*1.4+i*2)
  g.setColor(.40,.85,.52,alpha*.07*pulse);g.circle('fill',x,y,7)
  g.setColor(.65,.94,.47,alpha*.65*pulse);g.circle('fill',x,y,1.4)
 end
end
function S.mushroom(x,y,size,alpha)
 local g=love.graphics
 g.setColor(.55,.43,.23,alpha);g.rectangle('fill',x-size*.11,y,size*.22,size*.6)
 g.setColor(.68,.29,.10,alpha);g.ellipse('fill',x,y,size*.65,size*.30,28)
 g.setColor(.88,.65,.32,alpha*.8)
 for i=1,4 do g.circle('fill',x+(i-2.5)*size*.23,y+math.sin(i*3)*size*.09,size*.06) end
end
return S
