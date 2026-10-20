extern float clock;
extern vec2 dimensions;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec2 drift=vec2(sin(uv.y*22.0+clock*.75),cos(uv.x*18.0-clock*.55));
 vec2 edge=min(uv*dimensions,(1.0-uv)*dimensions);
 float anchored=smoothstep(0.0,38.0,min(edge.x,edge.y));
 vec2 sampleUV=uv+drift*vec2(5.0,3.0)*anchored/dimensions;
 return Texel(tex,sampleUV)*color;
}
