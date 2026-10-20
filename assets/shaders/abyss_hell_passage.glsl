extern vec2 dimensions;
extern float clock;
extern float waterline;
extern float opening;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*.57+noise(p*2.13)*.28+noise(p*4.37)*.15;}
vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
 vec2 q=pixel/dimensions;
 vec2 stone=vec2(q.x,q.y-waterline);
 float n=fbm(stone*vec2(14.,21.));
 float water=smoothstep(waterline-.004,waterline+.004,q.y);
 float vent=exp(-pow((q.x-.32)*9.,2.));
 vec3 sea=mix(vec3(.003,.015,.035),vec3(.018,.12,.16),n);
 sea+=vec3(.04,.12,.13)*vent*(.7+.3*sin(q.y*13.+clock*2.));
 float wall=smoothstep(.13,.20,abs(q.x-.32)+.02*sin(stone.y*15.)+.025*n);
 vec3 basalt=mix(vec3(.009,.018,.026),vec3(.07,.12,.13),n);
 float cracks=pow(1.-abs(sin(stone.y*25.+fbm(stone*7.)*7.)),20.);
 basalt+=vec3(.24,.045,.008)*cracks*(1.-water);
 vec3 c=mix(basalt,sea,water*(1.-wall*.8));
 float cover=max(water,wall*(1.-opening));
 float rim=exp(-abs(q.y-waterline)*220.);
 c+=vec3(.12,.32,.35)*rim;
 cover=max(cover,rim);
 return vec4(c,cover);
}
