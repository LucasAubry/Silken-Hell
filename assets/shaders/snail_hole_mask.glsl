extern vec4 ends;
extern float radius;
vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
 vec2 segment=ends.zw-ends.xy;
 float along=clamp(dot(pixel-ends.xy,segment)/max(dot(segment,segment),.0001),0.,1.);
 float distance=radius-length(pixel-ends.xy-segment*along);
 return vec4(clamp(.5+distance/128.,0.,1.),0.,0.,1.);
}
