extern vec2 floorSize;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec2 p=uv*floorSize;
 // Cut slate terraces, with fine engraved seams instead of a blurred cloud sheet.
 vec2 cell=vec2(floor((p.x+floor(p.y/74.)*43.)/138.),floor(p.y/74.));
 vec2 q=vec2(mod(p.x+floor(p.y/74.)*43.,138.),mod(p.y,74.));
 float stone=hash(cell);
 float grain=noise(p*.2)*.018+noise(p*.027)*.035;
 float seam=1.-smoothstep(1.,3.,min(min(q.x,138.-q.x),min(q.y,74.-q.y)));
 vec3 rock=mix(vec3(.25,.36,.43),vec3(.36,.48,.52),stone*.65+noise(p*.004)*.35);
 rock+=grain;rock=mix(rock,vec3(.11,.23,.30),seam*.48);
 float lip=(1.-smoothstep(1.,2.,q.y))*smoothstep(3.,9.,q.x)*smoothstep(3.,9.,138.-q.x);
 rock+=vec3(.14,.18,.16)*lip;
 vec2 center=p-floorSize*.5;float r=length(center*vec2(.8,1.));
 float ring=1.-smoothstep(.6,1.6,abs(mod(r+20.,105.)-52.5));
 rock=mix(rock,vec3(.54,.62,.60),ring*.12);
 float cloud=noise(p*.006+vec2(6.,3.));
 rock+=vec3(.05,.085,.09)*smoothstep(.48,.8,cloud);
 float edge=smoothstep(0.,100.,min(min(p.x,floorSize.x-p.x),min(p.y,600.-p.y)));
 rock*=.81+.19*edge;
 return vec4(rock,1.)*color;
}
