extern vec2 stepUV;
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 px){
 vec4 c=Texel(tex,uv)*.227027;
 c+=(Texel(tex,uv+stepUV*1.384615)+Texel(tex,uv-stepUV*1.384615))*.316216;
 c+=(Texel(tex,uv+stepUV*3.230769)+Texel(tex,uv-stepUV*3.230769))*.070270;
 return c*tint;
}
