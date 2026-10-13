extern float clock;
extern vec2 dimensions;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p){
 float v=0.0,a=.5;
 for(int i=0;i<4;i++){v+=a*noise(p);p=p*2.03+7.1;a*=.5;}
 return v;
}
float caustic(vec2 p){
 vec2 base=floor(p),f=fract(p);float first=9.0,second=9.0;
 for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
  vec2 g=vec2(float(x),float(y)),id=base+g;
  vec2 delta=g+.5+.35*sin(vec2(hash(id),hash(id+31.0))*6.28+clock*.32)-f;
  float d=dot(delta,delta);
  if(d<first){second=first;first=d;}else second=min(second,d);
 }
 return 1.0-smoothstep(.012,.065,sqrt(second)-sqrt(first));
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec2 p=pixel/dimensions.y,screen=pixel/dimensions;
 float terrain=fbm(p*3.2),detail=fbm(p*16.0);
 float channel=sin(p.x*3.8+p.y*2.6+terrain*4.0)*.5+.5;
 float sand=smoothstep(.33,.77,channel)*smoothstep(.20,.66,terrain);
 vec3 deep=mix(vec3(.014,.045,.105),vec3(.025,.20,.25),terrain);
 vec3 shelf=mix(vec3(.045,.25,.29),vec3(.15,.39,.40),detail);
 vec3 c=mix(deep,shelf,sand*.85);
 // Fine rippled sand under long translucent currents, rather than a tiled pool.
 float ripple=sin(p.y*105.0+terrain*28.0+sin(p.x*7.0)*3.0);
 c+=vec3(.022,.050,.046)*ripple*sand;
 vec2 flow=p*6.5+vec2(sin(p.y*3.0+clock*.08),cos(p.x*3.0-clock*.09))*.55;
 float lace=pow(caustic(flow),1.5)*smoothstep(.18,.80,noise(flow*2.0+clock*.035));
 c+=vec3(.045,.20,.23)*lace*(.23+sand*.32)*(1.0-screen.y*.40);
 float edge=smoothstep(.24,.66,length((screen-.5)*vec2(1.1,.9)));
 c=mix(c,c*vec3(.55,.61,.80),edge*.65);
 c+=(noise(p*350.0)-.5)*.008;
 return vec4(c,1.0)*color;
}
