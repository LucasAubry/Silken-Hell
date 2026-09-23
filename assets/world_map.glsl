extern float clock;
extern float mapHeight;
extern float scroll;
extern float viewTop;
extern vec3 stops[8];
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
 float depth=clamp((uv.y*mapHeight-viewTop+scroll-170.)/210.,0.,7.);
 vec3 tint=stops[0];
 for (int i=0;i<7;i++) {
  float t=smoothstep(float(i),float(i+1),depth);
  tint=mix(tint,stops[i+1],t);
 }
 float mist=sin(uv.y*4.+sin(uv.x*3.+clock*.06))*.5+.5;
 float light=exp(-length((uv-vec2(.5,.4))*vec2(2.8,1.2))*2.);
 vec3 c=tint*(.38+light*.28)+vec3(.012,.014,.018)+mist*.012;
 return vec4(c,1.)*color;
}
