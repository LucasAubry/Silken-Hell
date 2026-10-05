extern float strength;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
 vec4 source=Texel(image,uv);
 float luminance=dot(source.rgb,vec3(.2126,.7152,.0722));
 // Crisp colors without sampling adjacent pixels or spreading highlights.
 vec3 vivid=mix(vec3(luminance),source.rgb,1.10);
 vec3 contrast=(vivid-vec3(.5))*1.09+vec3(.5);
 return vec4(clamp(mix(source.rgb,contrast,strength),0.,1.),source.a)*color;
}
