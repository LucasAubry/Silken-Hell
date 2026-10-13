extern float clock;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
 float light=0.;
 for(int i=0;i<4;i++) {
  float k=float(i);float start=.09+k*.26;
  float top=.04+mod(k*1.7,1.)*.25;
  float depth=uv.y-top;
  float width=.008+max(depth,0.)*.08;
  float center=start+depth*.25;
  float ray=exp(-pow((uv.x-center)/width,2.));
  float fade=smoothstep(0.,.05,depth)*(1.-smoothstep(.2,.65,depth));
  float dust=.82+.18*sin(uv.y*58.+uv.x*21.-clock*.7+k);
  light+=ray*fade*dust*(.26+.024*sin(clock*.6+k));
 }
 return vec4(1.,.77,.39,light)*color;
}
