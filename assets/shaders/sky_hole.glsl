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
 float puff=noise(p*.055)*.65+noise(p*.14)*.35;
 float lip=d+(puff-.5)*9.;
 // Take the rim directly from the current moving cloud floor: the same cloud
 // continues to its torn edge, with shadowed vertical layers below it.
 vec3 surface=Texel(floorImage,(p-normal*8.)/floorSize).rgb;
 float light=clamp(.5+dot(normal,vec2(.4,.8))*.5,0.,1.);
 vec3 cloud=surface*.65+vec3(.33,.43,.53);
 float scallop=.5+.5*sin(p.x*.11+p.y*.09+noise(p*.07)*4.0);
 vec3 rim=cloud*(.75+light*.32)+vec3(.15,.19,.22)*exp(-pow((lip+3.)/3.5,2.))*light;
 vec3 wall=mix(vec3(.13,.23,.36),cloud*.44,scallop*.35);
 vec3 deep=vec3(.004,.012,.027)+vec3(.008,.014,.022)*noise(p*.024+17.);
 vec3 c=mix(rim,wall,smoothstep(-1.,8.,lip));
 c=mix(c,deep,smoothstep(2.,12.,d));
 // A second soft cloud shelf conveys depth without a flat black oval.
 float shelf=exp(-pow((d-14.-scallop*3.)/3.5,2.));
 c+=vec3(.025,.04,.06)*shelf*light;
 float alpha=smoothstep(-11.,-5.,lip);
 return vec4(c,alpha)*color;
}
