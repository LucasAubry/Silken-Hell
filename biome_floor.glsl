extern number biome;
extern number clock;
extern vec2 dimensions;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) {
 float v=0.0,a=.5;
 for(int i=0;i<4;i++) { v+=a*noise(p);p=p*2.03+vec2(7.3,2.7);a*=.5; }
 return v;
}
vec2 cells(vec2 p) {
 vec2 base=floor(p),f=fract(p); float first=9.0,second=9.0;
 for(int y=-1;y<=1;y++) for(int x=-1;x<=1;x++) {
  vec2 g=vec2(float(x),float(y));vec2 id=base+g;
  vec2 delta=g+vec2(hash(id),hash(id+vec2(41,9)))-f;
  float d=dot(delta,delta);
  if(d<first) {second=first;first=d;} else second=min(second,d);
 }
 return vec2(sqrt(first),sqrt(second)-sqrt(first));
}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 pixel) {
 vec2 p=pixel/dimensions.y;
 float grain=noise(p*350.0), terrain=fbm(p*7.0);
 vec3 c;
 if(biome==4.0 || biome==7.0) {
  vec2 drift=vec2(clock*.017,-clock*.012);
  vec2 water=p*7.0+vec2(fbm(p*3.0+drift),fbm(p*3.0-drift))*1.4;
  float edge=cells(water+drift).y;
  float caustic=pow(1.0-smoothstep(.0,.10,edge),2.0);
  float ripples=sin(p.y*39.0+fbm(p*4.0)*9.0+clock*.6)*.5+.5;
  c=mix(vec3(.018,.14,.21),vec3(.04,.34,.39),terrain);
  c+=vec3(.13,.34,.30)*caustic*.32+vec3(.015,.025,.022)*ripples;
  if(biome==7.0) c=mix(vec3(.009,.018,.035),vec3(.035,.085,.12),terrain)+vec3(.035,.07,.09)*caustic*.17;
 } else if(biome==5.0) {
  vec2 q=p*11.0+vec2(terrain,fbm(p*8.0+17.0))*.8;
  vec2 rock=cells(q);
  float cracks=1.0-smoothstep(.012,.04,rock.y);
  c=mix(vec3(.16,.079,.036),vec3(.36,.22,.105),terrain);
  c*=1.0-cracks*.19;
  c+=(grain-.5)*.065;
  float pebble=1.0-smoothstep(.075,.15,cells(p*33.0).x);
  c=mix(c,vec3(.40,.29,.18),pebble*.4);
  float roots=abs(sin(p.y*14.0+fbm(vec2(p.x*4.0,p.y*.9))*16.0));
  c=mix(c,vec3(.11,.053,.024), (1.0-smoothstep(.01,.06,roots))*.4);
 } else if(biome==3.0) {
  vec2 q=(pixel/dimensions-.5)*vec2(dimensions.x/dimensions.y,1.0);
  float r=length(q), a=atan(q.y,q.x);
  float cloud=fbm(q*5.0+vec2(clock*.014,-clock*.01));
  float vein=pow(abs(sin(q.x*9.0+q.y*5.0+cloud*12.0)),22.0);
  c=mix(vec3(.018,.012,.021),vec3(.20,.027,.047),cloud);
  c+=vec3(.28,.025,.035)*vein;
  float halo=exp(-abs(r-.29-sin(a*6.0+clock*.3)*.006)*180.0);
  float outer=exp(-abs(r-.41)*240.0);
  c+=vec3(.74,.63,.63)*halo*.28+vec3(.7,.06,.13)*outer*.3;
  float wings=exp(-pow((abs(q.x)-.33)*5.0,2.0)-pow((q.y+.05+abs(q.x)*.32)*7.0,2.0));
  float feathers=pow(max(0.0,sin(abs(q.x)*75.0+q.y*22.0+cloud*2.0)),7.0);
  c+=vec3(.73,.69,.68)*wings*feathers*.19;
  float shafts=pow(max(0.0,sin(a*17.0+clock*.035)),22.0)*exp(-r*3.0);
  c+=vec3(.8,.25,.3)*shafts*.16;
 } else if(biome==2.0 || biome==8.0) {
  float fissure=1.0-smoothstep(.009,.045,cells(p*8.0+terrain).y);
  c=mix(vec3(.055,.028,.030),vec3(.14,.075,.062),terrain)+(grain-.5)*.025;
  if(biome==8.0) {
    c=mix(c,vec3(.085,.075,.085),.3);
    c+=vec3(.62,.65,.70)*fissure*(.65+.10*sin(clock*.6+p.x*4.0));
    c+=vec3(.11,.12,.15)*pow(max(0.0,sin(p.x*5.0+terrain*1.5)),12.0);
  } else c+=vec3(.34,.055,.007)*fissure*(.65+.15*sin(clock*.8+p.x*4.0));
 } else {
  float marble=pow(abs(sin(p.x*8.0+p.y*5.0+fbm(p*4.0)*13.0)),18.0);
  c=mix(vec3(.77,.78,.73),vec3(.96,.93,.82),terrain);
  c=mix(c,vec3(.61,.53,.32),marble*.13);
  c+=vec3(.05,.045,.025)*pow(noise(p*8.0+clock*.009),3.0);
 }
 float vignette=1.0-.13*length((pixel/dimensions-.5)*1.4);
 return vec4(c*vignette,1.0)*tint;
}
