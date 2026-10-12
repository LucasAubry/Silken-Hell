extern vec2 direction;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
 // Separable Gaussian, baked only when the level's floor is prepared.
 vec4 c=Texel(tex,uv)*.227027;
 c+=(Texel(tex,uv+direction*1.384615)+Texel(tex,uv-direction*1.384615))*.316216;
 c+=(Texel(tex,uv+direction*3.230769)+Texel(tex,uv-direction*3.230769))*.070270;
 return c*color;
}
