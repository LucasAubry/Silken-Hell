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
  // Crimson molten folds share the ground's flowing strata and charcoal lip.
  c=mix(vec3(.060,.012,.025),vec3(.29,.045,.060),light)*(.8+stone*.3);
  if(edge>-2.){
   vec2 q=p*.016+vec2(clock*.013,-clock*.018);
   vec2 warp=vec2(noise(q)+noise(q*2.03+7.3)*.5,
                  noise(q+vec2(13.2,7.8))+noise(q*2.03+19.)*.5);
   float strata=q.y*5.8+q.x*2.3+warp.x*9.0+warp.y*4.0;
   float fold=.5+.5*sin(strata);
   float ribbon=pow(fold,3.0);
   float heat=noise(q*2.+warp);
   vec3 crust=mix(vec3(.32,.018,.035),vec3(.67,.055,.060),heat);
   vec3 melt=mix(vec3(.88,.075,.055),vec3(1.,.32,.19),ribbon);
   float bank=smoothstep(-2.,6.,edge);
   float shore=exp(-max(0.,edge)*.25)*.30;
   c=mix(c,mix(crust,melt,clamp(.30+ribbon*.70+shore,0.,1.)),bank);
   c+=vec3(.065,.020,.012)*cos(strata)*ribbon*bank;
   c+=vec3(.018,.007,.009)*(grain-.5)*bank;
  }
 }
 return vec4(c,alpha)*color;
}
