extern float material;
extern float clock;
extern vec2 worldOrigin;
extern vec2 worldSize;
extern vec2 sampleStep;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float field(Image tex,vec2 uv){return (Texel(tex,uv).r-.5)*128.;}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec2 p=floor((worldOrigin+uv*worldSize)*.8)/.8;
 // Smooth tiny hand tremors; displacement is limited to the decorative lip.
 float d=field(tex,uv)*.5;
 d+=(field(tex,uv+vec2(sampleStep.x,0))+field(tex,uv-vec2(sampleStep.x,0))
    +field(tex,uv+vec2(0,sampleStep.y))+field(tex,uv-vec2(0,sampleStep.y)))*.125;
 float grain=noise(p*.37),stone=noise(p*.10);
 float edge=d+(noise(p*.13)-.5)*2.;
 float alpha=smoothstep(-9.,-6.5,edge);
 vec2 normal=normalize(vec2(field(tex,uv+vec2(sampleStep.x,0))-field(tex,uv-vec2(sampleStep.x,0)),
                            field(tex,uv+vec2(0,sampleStep.y))-field(tex,uv-vec2(0,sampleStep.y)))+vec2(.001));
 float light=clamp(.5+dot(normal,vec2(.4,.8))*.5,0.,1.);
 vec3 c;
 if(material<.5){
  // A neutral rock lip for authored holes, independent of biome artwork.
  alpha=smoothstep(-10.,-6.,edge);
  vec3 rim=mix(vec3(.12,.105,.085),vec3(.42,.36,.27),light)*(.8+grain*.2);
  c=mix(rim,vec3(.006,.008,.012),smoothstep(-1.,12.,d));
 }else{
  // Crisp charcoal banks and a limited ember palette match the pixel sprites.
  alpha=smoothstep(-7.5,-6.7,edge);
  float rimLight=floor(light*3.)/3.;
  c=mix(vec3(.045,.020,.018),vec3(.24,.10,.055),rimLight);
  if(edge>-2.){
   vec2 q=p*.016+vec2(clock*.013,-clock*.018);
   vec2 warp=vec2(noise(q)+noise(q*2.03+7.3)*.5,
                  noise(q+vec2(13.2,7.8))+noise(q*2.03+19.)*.5);
   float strata=q.y*5.8+q.x*2.3+warp.x*9.0+warp.y*4.0;
   float fold=.5+.5*sin(strata);
   float ribbon=smoothstep(.48,.53,fold);
   float hot=smoothstep(.91,.94,fold);
   float crust=smoothstep(.55,.59,noise(q*3.+warp))*(1.-ribbon);
   vec3 melt=mix(vec3(.64,.075,.025),vec3(.94,.24,.035),ribbon);
   melt=mix(melt,vec3(1.,.61,.12),hot*.80);
   melt=mix(melt,vec3(.19,.055,.025),crust*.85);
   // Keep a narrow ink edge instead of the old broad blurred shoreline.
   float bank=smoothstep(.0,1.4,edge);
   c=mix(c,melt,bank);
  }
 }
 return vec4(c,alpha)*color;
}
