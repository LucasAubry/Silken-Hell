extern float clock;
extern vec2 dimensions;
extern vec2 traveler;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen) {
 vec2 p=screen/dimensions;
 vec2 drift=vec2(clock*.024,-clock*.012);
 float n=noise(p*vec2(5,9)+drift)*.6+noise(p*vec2(11,19)-drift*1.4)*.28+noise(p*vec2(23,37)+drift)*.12;
 float pockets=smoothstep(.48,.76,noise(p*vec2(3,4)+vec2(-clock*.009,0)));
 float ribbons=smoothstep(.38,.72,n)*pockets;
 float clear=smoothstep(25.0,115.0,distance(screen,traveler));
 return vec4(.27,.31,.30,ribbons*(.11+.13*p.y)*(.45+.55*clear));
}
