extern vec2 dimensions;
extern float clock;
extern float depth;
extern float heat;
extern float camera;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*.57+noise(p*2.13)*.28+noise(p*4.37)*.15;}
vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
 vec2 q=pixel/dimensions;
 vec2 p=(q-.5)*vec2(dimensions.x/dimensions.y,1.);
 float worldY=q.y+camera;
 float n=fbm((p+vec2(0.,depth))*7.);
 vec3 c=mix(vec3(.003,.009,.023),vec3(.012,.052,.083),n);
 float vent=exp(-pow(p.x*4.,2.))*smoothstep(-.45,.6,p.y);
 c+=vec3(.42,.065,.012)*vent*heat;
 for(int i=0;i<3;i++){
  float layer=float(i);
  vec2 stone=p+vec2(0.,depth*(.55+layer*.38));
  float boundary=.16+layer*.15+.05*sin(stone.y*4.+layer*2.)+.065*fbm(vec2(stone.y*7.,layer*4.));
  float edge=abs(stone.x)-boundary;
  float mask=smoothstep(-.006,.008,edge)*smoothstep(.56,.59,worldY);
  float grain=fbm(stone*vec2(34.,63.));
  float strata=sin(stone.y*43.+fbm(stone*9.)*7.);
  vec3 basalt=mix(vec3(.008,.021,.034),vec3(.035,.076,.092),grain)*(.65+.35*smoothstep(-.5,.7,strata));
  float cracks=pow(1.-abs(sin(stone.y*19.+noise(stone*9.)*6.)),18.);
  basalt=mix(basalt,basalt*vec3(1.8,.65,.38),heat);
  basalt+=vec3(.65,.085,.008)*cracks*heat*.48;
  basalt+=mix(vec3(.025,.13,.17),vec3(.38,.075,.015),heat)*exp(-max(edge,0.)*75.);
  c=mix(c,basalt*(1.-layer*.12),mask);
 }
 // Water sits above the entrance like a suspended meniscus, never inside the shaft.
 float water=1.-smoothstep(.577,.583,worldY);
 vec3 sea=mix(vec3(.008,.035,.065),vec3(.025,.13,.19),n);
 sea+=vec3(.01,.025,.03)*sin(q.x*20.+worldY*6.+clock*.2);
 c=mix(c,sea,water);
 float opening=1.-smoothstep(.18,.24,abs(p.x));
 float rim=exp(-abs(worldY-.58)*190.);
 c+=mix(vec3(.07,.12,.14),vec3(.15,.46,.58),opening)*rim;
 return vec4(c,1.);
}
