extern float clock;
extern vec2 origin;
extern vec2 scale;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec2 p=(pixel-origin)/scale*.035;
 float flow=noise(p+vec2(clock*.12,-clock*.08));
 float ridges=abs(sin(p.x*1.7+p.y*.6+flow*7.));
 float heat=smoothstep(.3,.92,ridges);
 vec3 c=mix(vec3(.40,.035,.008),vec3(1.,.29,.025),flow);
 c=mix(c,vec3(1.,.73,.16),pow(heat,5.)*.75);
 return vec4(c,1.)*color;
}
