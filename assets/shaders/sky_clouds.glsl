// Shared by the playable Sky biome and the Paradise-to-Sky cinematic.
float skyHash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float skyNoise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(skyHash(i),skyHash(i+vec2(1,0)),f.x),mix(skyHash(i+vec2(0,1)),skyHash(i+vec2(1,1)),f.x),f.y);}
vec3 skyCloudColor(vec2 pixel,vec2 dimensions,float clock,float approach){
 vec2 p=(pixel-dimensions*.5)/dimensions.y*(5.-approach*3.)+vec2(clock*.075,-clock*.18);
 float cloud=skyNoise(p)*.57+skyNoise(p*2.1)*.28+skyNoise(p*4.3)*.15;
 vec3 blue=mix(vec3(.09,.19,.32),vec3(.38,.58,.74),pixel.y/dimensions.y);
 return mix(blue,vec3(.87,.94,1.),smoothstep(.36,.78,cloud)*.85);
}
