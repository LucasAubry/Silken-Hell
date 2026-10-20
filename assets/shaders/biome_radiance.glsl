extern float clock;
extern float intensity;
extern float biome;
extern vec2 arenaSize;
extern int blockerCount;
extern vec4 blockers[24];
extern vec2 rotations[24];
vec2 localPoint(vec2 p,vec2 r) { return vec2(p.x*r.x+p.y*r.y,-p.x*r.y+p.y*r.x); }
float sunVisibility(vec2 point,vec2 origin) {
 for(int i=0;i<24;i++) {
  if(i>=blockerCount) break;
  vec2 target=localPoint(point-blockers[i].xy,rotations[i]);
  vec2 start=localPoint(origin-blockers[i].xy,rotations[i]);
  vec2 size=blockers[i].zw;
  if(all(lessThan(abs(target),size+vec2(1.5)))) continue;
  vec2 ray=target-start;
  if(abs(ray.x)<.0001) ray.x=.0001;
  if(abs(ray.y)<.0001) ray.y=.0001;
  vec2 a=(-size-start)/ray,b=(size-start)/ray;
  vec2 nearSide=min(a,b),farSide=max(a,b);
  if(max(max(nearSide.x,nearSide.y),0.0)<min(min(farSide.x,farSide.y),1.0)) return .035;
 }
 return 1.0;
}
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel) {
 vec2 p=pixel/love_ScreenSize.xy;
 vec2 q=p*vec2(arenaSize.x/600.0,1.0);
 vec3 light=vec3(0.0);
 if(biome==1.0) {
  // Paradise alone keeps long, warm sun shafts.
  float rays=0.0;
  for(int i=0;i<4;i++) {
   float k=float(i),center=-.13+k*.31+p.y*.27+sin(clock*.12+k*3.0)*.018;
   float d=(p.x-center)/(.019+p.y*.043);
   rays+=(exp(-d*d*.32)*.32+exp(-d*d*3.0)*.68)*(1.0-smoothstep(.35,1.45,p.y));
  }
  float visible=sunVisibility(p*arenaSize,vec2((p.x-p.y*.27)*arenaSize.x,-40));
  light=vec3(1.0,.82,.50)*rays*1.6*visible;
 } else if(biome==2.0) {
  // Hell: uneven ember glow rises from the edges, never sunlight stripes.
  float edge=min(min(p.x,1.0-p.x),min(p.y,1.0-p.y));
  float heat=noise(q*vec2(9,7)-vec2(0,clock*.32));
  float flicker=.8+.13*sin(clock*3.1)+.07*sin(clock*7.7+q.x*9.0);
  light=vec3(1.0,.20,.025)*exp(-edge*15.0)*(.18+heat*heat*.65)*flicker;
 } else if(biome==4.0) {
  // Ocean: travelling cellular caustics and broad blue water swells.
  vec2 warped=q*9.0+vec2(sin(q.y*12.0-clock*.5),cos(q.x*10.0+clock*.4))*.4;
  float a=sin(warped.x*2.4+warped.y*.8+clock*.4);
  float b=sin(warped.y*2.8-warped.x*.6-clock*.3);
  float caustic=pow(max(0.0,1.0-abs(a+b)*.55),14.0);
  float visible=sunVisibility(p*arenaSize,vec2(p.x*arenaSize.x,-40));
  light=(vec3(.08,.60,.78)*caustic*.8+vec3(.025,.14,.23)*noise(q*4.0+clock*.06))*visible;
 } else if(biome==5.0) {
  // Earth: isolated patches filtered through foliage, no continuous shafts.
  float canopy=noise(q*8.0+vec2(clock*.025,sin(clock*.1)*.1));
  float patches=smoothstep(.48,.83,canopy)*(.45+.55*noise(q*19.0));
  float visible=sunVisibility(p*arenaSize,vec2((p.x-.12)*arenaSize.x,-40));
  light=vec3(.92,.68,.29)*patches*.95*visible;
 } else if(biome==6.0) {
  // Sky: wide moving breaks in the clouds, with cool feathered edges.
  float opening=pow(noise(q*3.1+vec2(clock*.035,-clock*.018)),3.0);
  float silver=smoothstep(.42,.68,noise(q*5.3+vec2(clock*.023,0)));
  float visible=sunVisibility(p*arenaSize,vec2(p.x*arenaSize.x,-40));
  float sun=0.0;
  for(int i=0;i<3;i++) {
   float center=.13+float(i)*.34+p.y*.20+sin(clock*.09+float(i))*.025;
   float d=(p.x-center)/(.028+p.y*.04);
   sun+=exp(-d*d)*(.75-.25*p.y);
  }
  light=(vec3(.61,.82,1.0)*(opening*.9+silver*.15)+vec3(1.0,.86,.57)*sun*1.4)*visible;
 } else if(biome==3.0) {
  // Renaissance: small living green-gold pools among the webs.
  for(int i=0;i<5;i++) {
   float k=float(i);vec2 site=vec2(.12+fract(k*.37)*.76,.16+fract(k*.43)*.68);
   site+=vec2(sin(clock*.23+k*2.0),cos(clock*.19+k))*.025;
   float glow=exp(-dot((p-site)*vec2(1.4,1.0),(p-site)*vec2(1.4,1.0))*75.0);
   light+=vec3(.52,.74,.20)*glow*(.24+.12*sin(clock*1.2+k));
  }
 } else if(biome==8.0) {
  // Sanctuary: a quiet violet halo around the throne.
  vec2 d=(p-vec2(.5,.22))*vec2(1.6,1.0);
  light=vec3(.40,.26,.85)*exp(-dot(d,d)*6.0)*(.30+.055*sin(clock*1.1));
 }
 return vec4(light*intensity,1.0);
}
