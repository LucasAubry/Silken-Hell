extern float clock;
extern vec2 drift;
extern vec4 puffBounds;
extern int cutCount;
extern vec3 cuts[24];
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec2 q=uv*2.-1.;
 float billow=noise(q*3.+drift+vec2(clock*.11,-clock*.08));
 float detail=noise(q*7.-drift+clock*.05);
 float edge=length(q)+(.5-billow)*.30;
 float density=(1.-smoothstep(.48,1.,edge))*(.7+billow*.2+detail*.1);
 vec2 world=puffBounds.xy+uv*puffBounds.zw;
 for(int i=0;i<24;i++){
  if(i>=cutCount)break;
  density*=smoothstep(cuts[i].z-5.,cuts[i].z+5.,distance(world,cuts[i].xy));
 }
 vec3 smoke=mix(vec3(.018,.024,.039),vec3(.068,.080,.112),billow*.7+detail*.3);
 return vec4(smoke,density*color.a);
}
