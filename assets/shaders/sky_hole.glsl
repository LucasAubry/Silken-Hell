extern Image floorImage;
extern vec2 floorSize;
extern vec2 worldOrigin;
extern vec2 worldSize;
extern vec2 sampleStep;
float field(Image tex,vec2 uv){return (Texel(tex,uv).r-.5)*128.;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);}
vec4 effect(vec4 color,Image mask,vec2 uv,vec2 pixel){
 vec2 p=worldOrigin+uv*worldSize;
 float d=field(mask,uv);
 vec2 normal=normalize(vec2(field(mask,uv+vec2(sampleStep.x,0))-field(mask,uv-vec2(sampleStep.x,0)),field(mask,uv+vec2(0,sampleStep.y))-field(mask,uv-vec2(0,sampleStep.y)))+vec2(.001));
 float puff=noise(p*.095)*.7+noise(p*.21)*.3;
 float lip=d+(puff-.5)*4.;
 // Take the rim directly from the current moving cloud floor: the same cloud
 // continues to its torn edge, with shadowed vertical layers below it.
 vec3 surface=Texel(floorImage,(p-normal*8.)/floorSize).rgb;
 float light=clamp(.5+dot(normal,vec2(.4,.8))*.5,0.,1.);
 vec3 rim=surface*(.78+light*.25)+vec3(.04,.05,.055)*exp(-pow((lip+2.)/4.,2.))*light;
 vec3 wall=surface*vec3(.23,.31,.44);
 vec3 deep=vec3(.007,.018,.047)+vec3(.014,.028,.048)*noise(p*.03+17.);
 vec3 c=mix(rim,wall,smoothstep(0.,6.,d));
 c=mix(c,deep,smoothstep(7.,23.,d));
 float alpha=smoothstep(-11.,-5.,lip);
 return vec4(c,alpha)*color;
}
