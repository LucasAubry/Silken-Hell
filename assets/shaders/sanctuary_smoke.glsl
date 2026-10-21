extern vec2 center;
extern vec2 radius;
extern float clock;
extern float opacity;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),mix(hash(i+vec2(0.,1.)),hash(i+vec2(1.)),f.x),f.y);}
vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
 vec2 q=(pixel-center)/radius;
 vec2 drift=vec2(clock*.16,clock*.30);
 float n=noise(q*3.+drift)*.6+noise(q*7.-drift)*.3+noise(q*15.+drift)*.1;
 float rim=1.-smoothstep(.40,1.,length(q)+.18*(n-.5));
 float density=clamp(rim*(.80+n*.65)*opacity,0.,.99);
 return vec4(vec3(.005,.008,.013)+n*.007,density);
}
