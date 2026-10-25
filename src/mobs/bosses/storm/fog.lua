local F={}
function F.impact(s)
 s.fogHits=(s.fogHits or 0)+1
 s.fogTarget=math.min(.72,.72*s.fogHits/math.max(1,s.wave-1))
 s.smoke=s.smoke or {};s.smoke[#s.smoke+1]={x=s.x,y=s.y,age=0}
end
function F.update(s,dt)
 for i=#(s.smoke or {}),1,-1 do
  local p=s.smoke[i];p.age=p.age+dt
  if p.age>4 then table.remove(s.smoke,i) end
 end
 local oldest=s.smoke and s.smoke[#s.smoke]
 if not oldest or oldest.age>.35 then
  s.fogAmount=math.min(s.fogTarget or 0,(s.fogAmount or 0)+dt*.55)
 end
end
function F.smokePuff(p,i)
 local t=p.age;local a=i*2.399;local travel=15*t+22*t*t
 return p.x+math.cos(a)*travel,p.y+math.sin(a)*travel*.65-18*t,
  8+(22+i%4*3)*t,math.min(1,t/.35)*.58*math.max(0,math.min(1,(4-t)/2))
end
function F.alphaAt(s,x,y)
 local function smooth(a,b,v)local t=math.max(0,math.min(1,(v-a)/(b-a)));return t*t*(3-2*t)end
 local rows=s.fogRows or 0
 local clear=rows>=5 and 1 or rows>0 and 1-smooth(rows*120-16,rows*120+16,y) or 0
 if s.cleanStage=='dash' then
  local band=1-smooth(54,78,math.abs(y-(rows+.5)*120))
  clear=math.max(clear,band*(1-smooth(-16,16,(x-s.fogFront)*s.sweepDir)))
 end
 return (s.fogAmount or 0)*(1-clear)
end
-- Each parcel starts in the fog band, gets caught by the gust, and travels
-- with the compressed cloud bank until its entire body leaves the arena.
F.parcelCount=48
function F.pushedCloud(s,index)
 if s.cleanStage~='dash' then return end
 local dir=s.sweepDir;local front=dir==1 and s.fogFront or Arena.width-s.fogFront
 local origin=(math.floor((index-1)/2)+.5)*Arena.width/24
 local caught=front-origin
 if caught<=0 then return end
 local gather=1-math.exp(-caught/24)
 local along=origin+(caught+24+index*17%70)*gather
 local x=dir==1 and along or Arena.width-along
 local y=((s.fogRows or 0)+.5)*120+(index%2==0 and 27 or -27)+math.sin(caught*.035+index*2.399)*12
 local radius=22+index%5*3+math.min(1,front/Arena.width)*10
 return x,y,radius,gather*(s.fogAmount or 0)
end
local function bindPuffs(s)
 local g=love.graphics
 F.puffShader=F.puffShader or g.newShader([[
 extern number seed;
 extern number clock;
 extern number direction;
 number hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
 number noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px){
  vec2 p=uv*2.0-1.0;
  vec2 q=p*2.1+vec2(seed,clock*.7);
  q.x-=direction*clock*.8;
  number cloud=noise(q)*.65+noise(q*2.2)*.35;
  number edge=length(p)+(.5-cloud)*.28;
  number alpha=(1.0-smoothstep(.63,1.0,edge))*.88;
  number light=clamp(.38+cloud*.48-p.y*.14,0.0,1.0);
  vec3 shade=mix(vec3(.37,.51,.62),vec3(.94,.98,1.0),light);
  return vec4(shade,alpha)*color;
 }
 ]])
 g.setShader(F.puffShader)
 F.puffShader:send('clock',s.clock);F.puffShader:send('direction',s.sweepDir or 1)
end
local function drawPushedClouds(s)
 if s.cleanStage~='dash' then return end
 local g=love.graphics;bindPuffs(s)
 for i=1,F.parcelCount do
  local x,y,r,alpha=F.pushedCloud(s,i)
  if x and x+r>=0 and x-r<=Arena.width then
   F.puffShader:send('seed',i*2.399);g.setColor(1,1,1,alpha)
   g.draw(F.pixel,x-r,y-r,0,r*2,r*2)
  end
 end
 g.setShader();g.setColor(1,1,1)
end
function F.draw(s)
 if not s.active or s.defeated or (s.fogAmount or 0)<=0 and #(s.smoke or {})==0 then return end
 local g=love.graphics
 F.shader=F.shader or g.newShader([[
 extern vec2 arenaSize;
 extern number density;
 extern number clock;
 extern number rows;
 extern number front;
 extern number direction;
 extern number sweeping;
 number hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
 number noise(vec2 p) {
  vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
  return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
 }
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px) {
  // Local arena coordinates, independent of the screen's pixel density.
  vec2 p=uv*arenaSize;
  number row=min(4.0,floor(p.y/120.0));
  number edgeNoise=(noise(p*.025+vec2(clock*.1,0.0))-.5)*12.0;
  number clear=rows>=5.0 ? 1.0 : (rows>0.0 ? 1.0-smoothstep(rows*120.0-16.0,rows*120.0+16.0,p.y+edgeNoise) : 0.0);
  if(sweeping>0.5) {
   number band=1.0-smoothstep(54.0,78.0,abs(p.y-(rows+.5)*120.0)+edgeNoise);
   clear=max(clear,band*(1.0-smoothstep(-16.0,16.0,(p.x-front)*direction+edgeNoise)));
  }
  number alpha=density*(1.0-clear);
  vec2 material=p;
  if(sweeping>0.5){
   number band=1.0-smoothstep(54.0,90.0,abs(p.y-(rows+.5)*120.0));
   number travel=clamp(direction>0.0 ? front : arenaSize.x-front,0.0,arenaSize.x);
   material.x-=direction*travel*.8*band;
  }
  vec2 q=material*.011+vec2(clock*.08,-clock*.035);
  number cloud=noise(q)*.60+noise(q*2.1+7.0)*.28+noise(q*4.0)*.12;
  vec3 shade=mix(vec3(.48,.59,.69),vec3(.86,.92,.96),cloud);
  if(row==rows && sweeping>0.5) shade+=vec3(.12)*exp(-abs(p.x-front)*.035);
  return vec4(shade,alpha)*color;
 }
 ]])
 -- A tiny white texture provides normalized coordinates over the arena rectangle.
 if not F.pixel then local data=love.image.newImageData(1,1);data:setPixel(0,0,1,1,1,1);F.pixel=g.newImage(data);data:release() end
 g.push('all');g.setShader(F.shader);g.setColor(1,1,1)
 F.shader:send('arenaSize',{Arena.width,600})
 F.shader:send('density',s.fogAmount);F.shader:send('clock',s.clock)
 F.shader:send('rows',s.fogRows or 0);F.shader:send('front',s.fogFront or 0)
 F.shader:send('direction',s.sweepDir or 1);F.shader:send('sweeping',s.cleanStage=='dash' and 1 or 0)
 g.draw(F.pixel,0,0,0,Arena.width,600)
 g.setShader()
 drawPushedClouds(s)
 if not s.cleanStage or s.cleanStage=='hold' then
  bindPuffs(s)
  for _,p in ipairs(s.smoke or {}) do for i=1,16 do
   local x,y,r,alpha=F.smokePuff(p,i)
   F.puffShader:send('seed',i*2.399);g.setColor(1,1,1,alpha)
   g.draw(F.pixel,x-r,y-r,0,r*2,r*2)
  end end
 end

 g.pop()
end
return F
