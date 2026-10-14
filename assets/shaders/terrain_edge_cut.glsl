extern Image cutMask;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec4 edge=Texel(tex,uv)*color;
 edge.a*=1.-Texel(cutMask,uv).a;
 return edge;
}
