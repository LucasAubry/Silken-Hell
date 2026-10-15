extern float material;
extern float biome;
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
float crustEdge(vec2 p){
 vec2 cell=floor(p),f=fract(p);float first=9.,second=9.;
 for(int y=-1;y<=1;y++) for(int x=-1;x<=1;x++){
  vec2 offset=vec2(float(x),float(y)),id=cell+offset;
  vec2 delta=offset+vec2(hash(id),hash(id+vec2(37.,19.)))-f;
  float distance=dot(delta,delta);
  if(distance<first){second=first;first=distance;}else second=min(second,distance);
 }
 return sqrt(second)-sqrt(first);
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec2 p=worldOrigin+uv*worldSize;
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
 // Cut edges use the material of the surrounding biome.
 vec3 low=vec3(.085,.043,.033),high=vec3(.29,.16,.105);
 if(biome==5.) {low=vec3(.14,.085,.045);high=vec3(.43,.285,.16);}
 else if(biome==3.) {low=vec3(.065,.145,.10);high=vec3(.30,.40,.17);}
 else if(biome==6.) {low=vec3(.15,.25,.37);high=vec3(.51,.66,.76);}
 else if(biome==1.) {low=vec3(.38,.33,.25);high=vec3(.77,.68,.53);}
 else if(biome==4.) {low=vec3(.025,.13,.17);high=vec3(.12,.33,.33);}
 else if(biome==7.) {low=vec3(.014,.025,.045);high=vec3(.07,.12,.17);}
 vec3 bank=mix(low,high,light)*(.77+stone*.22+grain*.14);
 vec3 c;
 if(material<.5){
  alpha=smoothstep(-10.,-6.,edge);
  float strata=.87+.13*sin(d*1.8+noise(p*.15)*3.);
  c=mix(bank*strata,vec3(.006,.006,.008),smoothstep(-1.,14.,d));
 }else{
  alpha=smoothstep(-9.,-6.,edge);
  // The surrounding ground darkens into a charred, recessed shoreline.
  c=mix(bank,vec3(.055,.022,.016),smoothstep(-6.,0.,edge)*.80);
  // Broken volcanic plates drift over irregular channels of molten rock.
  // Their granular surfaces echo the fractured biome floor.
  vec2 q=p*.035,drift=vec2(clock*.009,-clock*.012);
  vec2 warp=vec2(noise(q*.75+drift),noise(q*.75+17.-drift));
  vec2 flow=q+warp*.75+drift;
  float gap=crustEdge(flow);
  float heat=noise(q*1.4+warp+drift*2.);
  float channel=1.-smoothstep(.035,.20+heat*.10,gap);
  float core=(1.-smoothstep(.008,.060,gap))*(.56+heat*.44);
  float pooling=smoothstep(.62,.82,noise(flow*.8+31.));
  channel=max(channel,pooling);
  vec3 cooled=mix(vec3(.055,.027,.022),vec3(.20,.085,.044),stone);
  cooled*=.72+grain*.50;
  cooled+=vec3(.10,.023,.003)*pow(1.-smoothstep(.08,.38,gap),2.);
  vec3 molten=mix(vec3(.72,.08,.006),vec3(1.,.40,.025),heat);
  molten=mix(molten,vec3(1.,.80,.22),core);
  molten*=.91+.09*noise(q*7.+drift*3.);
  vec3 melt=mix(cooled,molten,channel);
  c+=vec3(.28,.055,.003)*exp(-abs(edge+1.)*.38);
  c=mix(c,melt,smoothstep(0.,2.5,edge));
 }
 return vec4(c,alpha)*color;
}
