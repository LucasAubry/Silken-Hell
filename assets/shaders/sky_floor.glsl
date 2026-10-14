extern vec2 floorSize;
extern bool bossArena;
// The same continuous, softly grained material as Paradise, shaped into cloud banks.
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p){
 float value=0.,amplitude=.5;
 for(int i=0;i<4;i++){value+=amplitude*noise(p);p=p*2.03+vec2(7.3,2.7);amplitude*=.5;}
 return value;
}
float cloudField(vec2 p){
 vec2 drift=vec2(noise(p*1.7),noise(p*1.7+19.));
 return fbm(p*4.5+drift*1.7);
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec2 p=uv*floorSize/600.;
 float field=cloudField(p);
 float mass=smoothstep(.24,.68,field);
 float light=cloudField(p+vec2(-.018,-.026))-field;
 vec3 sky=mix(vec3(.43,.56,.65),vec3(.60,.71,.78),fbm(p*2.));
 vec3 cloud=mix(vec3(.66,.76,.81),vec3(.91,.94,.94),mass);
 // Rounded illuminated rims and blue undersides replace the marble veins.
 float rim=exp(-pow((field-.44)/.095,2.));
 cloud+=vec3(.75,.79,.80)*clamp(light*2.8,-.08,.08);
 cloud+=vec3(.07,.075,.065)*rim*smoothstep(-.012,.025,light);
 vec3 base=mix(sky,cloud,smoothstep(.27,.47,field));
 if(bossArena) {
  // Crisp cloud shelves make the combat floor readable without a soft veil.
  base=mix(vec3(.43,.56,.65),vec3(.62,.73,.80),smoothstep(.337,.343,field));
  base=mix(base,vec3(.76,.84,.88),smoothstep(.437,.443,field));
  base=mix(base,vec3(.89,.93,.94),smoothstep(.537,.543,field));
 }
 base+=(noise(p*350.)-.5)*.012;
 float vignette=1.-.10*length((uv-.5)*1.4);
 return vec4(base*vignette,1.)*color;
}
