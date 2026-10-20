extern vec2 texel;
extern number breath;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
 vec4 s=Texel(tex,uv);
 float left=Texel(tex,uv-vec2(texel.x*2.,0)).a;
 float right=Texel(tex,uv+vec2(texel.x*2.,0)).a;
 float top=Texel(tex,uv-vec2(0,texel.y*2.)).a;
 vec3 lit=s.rgb*vec3(1.08,.99,.87);
 lit+=vec3(.10,.48,.40)*(1.-left)*.65;
 lit+=vec3(.65,.34,.10)*(1.-top)*.65;
 lit+=vec3(.22,.12,.38)*(1.-right)*.4;
 return vec4(lit*breath,s.a)*color;
}
