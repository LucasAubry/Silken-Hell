extern vec2 texel;
extern float strength;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
 vec4 source=Texel(image,uv);vec3 bloom=vec3(0.0);
 bloom+=max(Texel(image,uv+texel*vec2(2.,0.)).rgb-.65,0.0);
 bloom+=max(Texel(image,uv-texel*vec2(2.,0.)).rgb-.65,0.0);
 bloom+=max(Texel(image,uv+texel*vec2(0.,2.)).rgb-.65,0.0);
 bloom+=max(Texel(image,uv-texel*vec2(0.,2.)).rgb-.65,0.0);
 float l=dot(source.rgb,vec3(.2126,.7152,.0722));
 vec3 polished=mix(vec3(l),source.rgb,1.08)+bloom*.12;
 return vec4(mix(source.rgb,polished,strength),source.a)*color;
}
