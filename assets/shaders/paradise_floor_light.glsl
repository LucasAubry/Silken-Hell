extern number clock;
extern vec2 dimensions;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 pixel) {
    vec4 base=Texel(tex,uv);
    vec2 p=pixel/dimensions.y;
    vec3 c=base.rgb+vec3(.027,.024,.018)*pow(noise(p*8.0+clock*.009),3.0);
    return vec4(c*base.a,1.0)*tint;
}
