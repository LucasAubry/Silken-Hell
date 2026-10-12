extern vec2 floorSize;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*.52+noise(p*2.03)*.26+noise(p*4.07)*.13+noise(p*8.13)*.065;}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec2 p=uv*floorSize/105.;
 vec2 warp=vec2(fbm(p*.8),fbm(p*.8+17.));
 float banks=fbm(p+warp*2.8);
 float curls=fbm(p*3.3+warp*7.);
 float fiber=fbm(p*11.+warp*18.);
 float ridge=abs(curls-.5);
 float relief=smoothstep(.025,.17,ridge);
 vec3 base=mix(vec3(.42,.55,.59),vec3(.70,.78,.76),smoothstep(.24,.74,banks));
 base+=vec3(.07,.07,.055)*(relief-.5);
 base+=vec3(.030,.034,.028)*(fiber-.48)*2.;
 float grain=hash(floor(uv*floorSize*1.5))-.5;
 base+=grain*.010;
 return vec4(base,1.)*color;
}
