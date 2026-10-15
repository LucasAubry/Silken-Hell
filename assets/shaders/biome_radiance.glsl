extern float clock;
extern float biome;
extern vec2 arenaSize;
// Slow, irregular shafts: color and rhythm belong to each environment.
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
 vec2 p=pixel/love_ScreenSize.xy;
 if(biome==2.0) p.y=1.0-p.y;
 float rays=0.0;
 for(int i=0;i<4;i++) {
  float k=float(i);
  float start=-.13+k*.31+sin(k*7.1)*.045;
  float slope=biome==3.0 ? -.23 : .27;
  float center=start+p.y*slope+sin(clock*.12+k*3.0)*.018;
  float width=.012+p.y*.057;
  float distance=(p.x-center)/width;
  float broad=exp(-distance*distance*.32);
  float narrow=exp(-distance*distance*3.0);
  float bands=.78+.22*sin(p.x*120.0-p.y*26.0+clock*.22+k);
  float canopy=biome==3.0 ? .52+.48*pow(sin(p.y*12.0+p.x*8.0+clock*.2),2.0) : 1.0;
  rays+=(broad*.32+narrow*.68)*bands*canopy*(1.0-smoothstep(.12,1.15,p.y));
 }
 vec3 tint=vec3(1.0,.74,.32);
 float strength=.48;
 if(biome==1.0) { tint=vec3(1.0,.82,.50);strength=.62; }
 if(biome==2.0) { tint=vec3(1.0,.22,.035);strength=.25; }
 if(biome==3.0) { tint=vec3(.81,.91,.43);strength=.54; }
 if(biome==4.0) { tint=vec3(.18,.82,1.0);strength=.70; }
 if(biome==5.0) { tint=vec3(1.0,.62,.25);strength=.72; }
 if(biome==6.0) { tint=vec3(.68,.86,1.0);strength=.42; }
 if(biome==7.0) { tint=vec3(.13,.40,1.0);strength=.16; }
 if(biome==8.0) { tint=vec3(.47,.39,1.0);strength=.34; }
 vec3 light=tint*rays*strength;
 if(biome==4.0) {
  vec2 q=p*vec2(arenaSize.x/600.0,1.0);
  float wave=sin(q.x*31.0+q.y*21.0+sin(q.y*15.0-clock*.42)*2.0+clock*.3);
  float crossing=sin(q.x*19.0-q.y*29.0+sin(q.x*17.0+clock*.3)*1.5);
  float caustic=pow(1.0-abs(wave*.55+crossing*.45),18.0);
  light+=vec3(.12,.50,.58)*caustic*.22;
 }
 return vec4(light,1.0);
}
