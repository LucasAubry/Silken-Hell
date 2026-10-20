extern vec2 direction;
extern float extract;
vec3 sampleGlow(Image image, vec2 uv) {
 vec3 c=Texel(image,uv).rgb;
 float brightness=max(c.r,max(c.g,c.b));
 return c*mix(1.0,smoothstep(.58,.95,brightness),extract);
}
vec4 effect(vec4 color, Image image, vec2 uv, vec2 pixel) {
 vec3 glow=sampleGlow(image,uv)*.227027;
 glow+=(sampleGlow(image,uv+direction*1.384615)+sampleGlow(image,uv-direction*1.384615))*.316216;
 glow+=(sampleGlow(image,uv+direction*3.230769)+sampleGlow(image,uv-direction*3.230769))*.070270;
 return vec4(glow,1.0);
}
