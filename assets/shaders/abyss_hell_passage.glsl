extern vec2 dimensions;
extern vec2 lamp;
extern float clock;
extern float depth;
extern float heat;
extern float water;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*.57+noise(p*2.13)*.28+noise(p*4.37)*.15;}
vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
 vec2 q=pixel/dimensions;
 vec2 p=(pixel-dimensions*.5)/dimensions.y;
 vec2 rock=p+vec2(0.,depth*1.35);
 float n=fbm(rock*7.);
 float channel=exp(-p.x*p.x*18.);
 // Cold blue depth remains visible behind the red light from the vent below.
 vec3 c=mix(vec3(.003,.009,.023),vec3(.012,.052,.083),n);
 float vent=exp(-pow(p.x*4.,2.))*smoothstep(-.45,.6,p.y);
 c+=vec3(.42,.065,.012)*vent*(.10+heat*.9);
 c=mix(c,c+vec3(.08,.017,.008)*n,heat);
 // Three irregular silhouettes scroll at different depths, like an actual descent.
 for(int i=0;i<3;i++){
  float layer=float(i);
  vec2 stone=p+vec2(0.,depth*(.55+layer*.38));
  float boundary=.16+layer*.15+.05*sin(stone.y*4.+layer*2.)+.065*fbm(vec2(stone.y*7.,layer*4.));
  float edge=abs(stone.x)-boundary;
  float mask=smoothstep(-.006,.008,edge);
  float strata=sin(stone.y*43.+fbm(stone*9.)*7.);
  float grain=fbm(stone*vec2(34.,63.));
  vec3 basalt=mix(vec3(.008,.021,.034),vec3(.035,.076,.092),grain);
  basalt*=.65+.35*smoothstep(-.5,.7,strata);
  float cracks=pow(1.-abs(sin(stone.y*19.+noise(stone*9.)*6.)),18.);
  float hot=heat*smoothstep(-.6,.4,p.y+heat*.5);
  basalt=mix(basalt,basalt*vec3(1.8,.65,.38),hot);
  basalt+=vec3(.65,.085,.008)*cracks*hot*.48;
  float rim=exp(-max(edge,0.)*75.);
  basalt+=mix(vec3(.025,.13,.17),vec3(.38,.075,.015),hot)*rim*(.5+.5*grain);
  c=mix(c,basalt*(1.-layer*.12),mask);
 }
 // The same helmet light reveals the nearby wet rock during the underwater part.
 vec2 delta=(q-lamp)*vec2(dimensions.x/dimensions.y,1.);
 float glow=exp(-dot(delta,delta)*17.)*water;
 c+=vec3(.025,.105,.135)*glow*(.4+n*.6);
 float rays=pow(max(0.,sin(q.x*25.+q.y*4.+clock*.12)),16.);
 c+=vec3(.012,.035,.045)*rays*(1.-q.y)*water;
 c*=1.-smoothstep(.3,1.,length(p))*.4;
 return vec4(c,1.);
}
