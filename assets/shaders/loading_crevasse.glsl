extern number time;
extern number foregroundOnly;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float rock(vec2 p) { return noise(p)*.55+noise(p*2.13)*.27+noise(p*4.7)*.12+noise(p*10.1)*.06; }
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
 // A fixed virtual pixel grid gives the stone the game's sprite texture.
 vec2 p=floor(uv*vec2(900,560))/vec2(900,560);
 float teal=exp(-length((p-vec2(.19,.35))*vec2(5.,2.)));
 float purple=exp(-length((p-vec2(.94,.43))*vec2(6.,3.)));
 float amber=exp(-length((p-vec2(.055,.23))*vec2(13.,6.)));
 float mist=rock(p*vec2(5,3)+vec2(time*.012,0));
 vec3 c=vec3(.013,.038,.065)+vec3(.025,.29,.27)*teal+vec3(.20,.07,.29)*purple;
 c+=mist*vec3(.018,.055,.065);
 float shafts=pow(noise(vec2(p.x*27.+p.y*.8,time*.025)),3.);
 c+=vec3(.02,.16,.14)*teal*shafts;
 // Irregular far pinnacles, progressively darker toward the viewer.
 for(int layer=0;layer<4;layer++) {
  float l=float(layer);
  float ridge=.30+l*.14+rock(vec2(p.x*(9.+l*2.),l+10.))*.38;
  float tooth=noise(vec2(p.x*80.,l))*.025;
  if(p.y>ridge+tooth) {
   vec3 stone=vec3(.009,.025,.043)+teal*vec3(.005,.065,.064)+purple*vec3(.033,.018,.065);
   float facet=rock(p*vec2(35,9)+l*11.);
   c=mix(c,stone*(.7+facet*.65),.55+l*.09);
  }
 }
 float foreground=0.;
 // Foreground crags: fractured organic strata, no masonry grid.
 for(int layer=0;layer<3;layer++) {
  float l=float(layer);
  float side=p.x<.5 ? p.x : 1.-p.x;
  float seed=p.x<.5 ? 0. : 31.;
  float edge=.06+(rock(vec2(p.y*6.,seed+l*4.))-.3)*.31-l*.026;
  edge+=pow(abs(p.y-.48)*1.9,3.)*.15;
  float roof=.018+pow(rock(vec2(p.x*12.,l+21.)),3.)*.25-l*.015;
  float base=.96-pow(rock(vec2(p.x*8.,l+43.)),3.)*.35+l*.025;
  if(side<edge || p.y<roof || p.y>base) {
   foreground=1.;
   float facets=rock(p*vec2(42,28)+vec2(l*7,0));
   float stratum=noise(vec2(p.x*60.+p.y*31.,p.y*18.));
   float face=floor(facets*7.)/7.;
   vec3 stone=mix(vec3(.009,.012,.022),vec3(.09,.065,.085),face)*(1.-l*.19);
   float lip=exp(-abs(side-edge)*100.)+exp(-abs(p.y-base)*100.)*.4;
   vec3 light=teal*vec3(.04,.55,.43)+purple*vec3(.40,.14,.60)+amber*vec3(1.5,.76,.22);
   stone+=light*(pow(face,2.)*1.6+lip*.8)*(1.-l*.22);
   stone*=.5+.5*smoothstep(.23,.48,stratum);
   c=stone;
  }
 }
 // Shafts of colored haze spill between the rocks.
 c+=vec3(.008,.065,.059)*teal*pow(noise(vec2(p.x*38.+p.y*.7,2.)),5.);
 c*=1.-smoothstep(.35,.78,length((p-.5)*vec2(.85,1.)))*.6;
 return vec4(c,foregroundOnly>.5 ? foreground : 1.)*color;
}
