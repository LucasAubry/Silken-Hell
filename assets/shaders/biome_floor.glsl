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
vec3 champagneMarble(vec2 p) {
    // Original marble contours from the reference, gently lifted toward ivory.
    float terrain=fbm(p*7.0);
    float marble=pow(abs(sin(p.x*8.0+p.y*5.0+fbm(p*4.0)*13.0)),18.0);
    vec3 c=mix(vec3(.735,.653,.528),vec3(.940,.870,.736),terrain);
    float veins=smoothstep(.78,.99,marble);
    c=mix(c,vec3(.97,.947,.888),veins*.34);
    c+=(noise(p*350.0)-.5)*.012;
    return c;
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
float cloudPuffs(vec2 p) {
 vec2 base=floor(p),f=fract(p);
 float mass=0.0;
 // Overlapping rounded lobes, with no stretched grass-like grain.
 for(int y=-1;y<=1;y++) for(int x=-1;x<=1;x++) {
  vec2 cell=vec2(float(x),float(y)),id=base+cell;
  vec2 center=vec2(.22)+vec2(hash(id),hash(id+vec2(31,73)))*.56;
  vec2 d=(cell+center-f)*vec2(1.0,1.18);
  float radius=.30+hash(id+vec2(14,5))*.20;
  mass+=exp(-dot(d,d)/(radius*radius))*(.75+hash(id+19.)*.35);
 }
 return mass;
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
  c=mix(vec3(.025,.21,.29),vec3(.065,.43,.47),terrain);
  c+=vec3(.13,.34,.30)*caustic*.58+vec3(.015,.025,.022)*ripples;
  if(biome==4.0) {
   float shaft=pow(max(0.0,sin(p.x*8.0+p.y*1.7+sin(clock*.12)*.4)),12.0);
   float glimmer=pow(max(0.0,sin(p.x*27.0-p.y*18.0+clock*.45)),20.0)*caustic;
   c+=vec3(.065,.14,.13)*shaft*(1.0-pixel.y/dimensions.y*.55)+vec3(.14,.22,.18)*glimmer*.3;
  }
  if(biome==7.0) c=mix(vec3(.009,.018,.035),vec3(.035,.085,.12),terrain)+vec3(.035,.07,.09)*caustic*.17;
 } else if(biome==6.0) {
  // Soft cloud banks drift across blue gaps; rounded tops catch pearly light.
  vec2 drift=vec2(clock*.009,-clock*.003);
  vec2 sky=p*3.8+drift;
  float mass=cloudPuffs(sky)+cloudPuffs(sky*1.85+vec2(7.4,3.1))*.24;
  float cloud=smoothstep(.23,.86,mass);
  float top=clamp((cloudPuffs(sky+vec2(-.07,.13))-cloudPuffs(sky-vec2(-.07,.13)))*1.8+.5,0.0,1.0);
  vec3 air=mix(vec3(.10,.23,.38),vec3(.24,.42,.59),terrain);
  vec3 vapor=mix(vec3(.37,.53,.68),vec3(.78,.87,.93),top);
  vapor+=vec3(.025,.030,.035)*(noise(sky*7.0)-.5);
  c=mix(air,vapor,cloud);
 } else if(biome==3.0 || biome==5.0) {
  vec2 flow=p+vec2(fbm(p*2.0),fbm(p*2.0+19.0))*.36;
  float pigment=fbm(flow*18.0)-.5;
  float meadow=fbm(p*4.5);
  // Mossy greens, cool forest shadows and a yellow-green clearing.
  vec2 position=pixel/dimensions;
  float clearing=exp(-dot((position-vec2(.52,.46))*vec2(2.4,2.0),
                         (position-vec2(.52,.46))*vec2(2.4,2.0)));
  float canopy=smoothstep(.25,.76,meadow);
  c=mix(vec3(.065,.145,.15),vec3(.30,.43,.18),canopy);
  c=mix(c,vec3(.56,.66,.28),clearing*(.24+canopy*.48));
  float tufts=pow(noise(flow*vec2(110.0,55.0)),4.0);
  c+=vec3(.075,.085,.025)*tufts;
  c+=vec3(.045,.055,.025)*pigment;
  if(biome==5.0) {
   // Renaissance's exact painted pattern, recolored in warm earth browns.
   c=mix(vec3(.10,.055,.035),vec3(.32,.18,.09),canopy);
   c=mix(c,vec3(.58,.40,.23),clearing*(.24+canopy*.48));
   c+=vec3(.075,.050,.025)*tufts;
   c+=vec3(.055,.035,.020)*pigment;
  }
 } else if(biome==2.0) {
  // Renaissance's soft pigment washes, with scorched islands instead of moss.
  vec2 ground=p+vec2(8.7,3.2);
  vec2 flow=ground+vec2(fbm(ground*2.0),fbm(ground*2.0+19.0))*.36;
  float pigment=fbm(flow*18.0)-.5;
  float scorch=smoothstep(.25,.76,fbm(ground*4.5));
  vec2 position=pixel/dimensions;
  vec2 warm=(position-vec2(.38,.40))*vec2(2.8,2.3);
  vec2 reflected=(position-vec2(.76,.72))*vec2(3.8,3.1);
  float emberLight=exp(-dot(warm,warm))*.78+exp(-dot(reflected,reflected))*.42;
  c=mix(vec3(.075,.033,.038),vec3(.38,.095,.065),scorch);
  c=mix(c,vec3(.62,.19,.095),emberLight*(.24+scorch*.48));
  // Broken soot flecks and matte ash replace the meadow's directional grass.
  float cinders=pow(noise(flow*vec2(76.0,83.0)),4.0);
  float ash=smoothstep(.54,.76,fbm(flow*11.0));
  c=mix(c,vec3(.24,.16,.145),ash*.20);
  c+=vec3(.065,.027,.018)*cinders;
  c+=vec3(.055,.027,.022)*pigment;
 } else if(biome==8.0) {
  float fissure=1.0-smoothstep(.009,.045,cells(p*8.0+terrain).y);
  c=mix(vec3(.055,.028,.030),vec3(.14,.075,.062),terrain)+(grain-.5)*.025;
  c=mix(c,vec3(.085,.075,.085),.3);
  c+=vec3(.62,.65,.70)*fissure*(.65+.10*sin(clock*.6+p.x*4.0));
  c+=vec3(.11,.12,.15)*pow(max(0.0,sin(p.x*5.0+terrain*1.5)),12.0);
 } else if(biome==1.0) {
  c=champagneMarble(p);
  c+=vec3(.027,.024,.018)*pow(noise(p*8.0+clock*.009),3.0);
 } else {
  float marble=pow(abs(sin(p.x*8.0+p.y*5.0+fbm(p*4.0)*13.0)),18.0);
  // Preserve the marble pattern, with matte ivory washes and fine graphite veins.
  c=mix(vec3(.78,.78,.75),vec3(.93,.92,.87),terrain);
  c=mix(c,vec3(.43,.45,.44),smoothstep(.78,.99,marble)*.14);
  c+=(grain-.5)*.012;
  c+=vec3(.025,.024,.02)*pow(noise(p*8.0+clock*.009),3.0);
 }
 float vignette=1.0-.13*length((pixel/dimensions-.5)*1.4);
 return vec4(c*vignette,1.0)*tint;
}
