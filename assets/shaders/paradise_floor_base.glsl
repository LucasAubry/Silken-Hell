extern vec2 dimensions;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) {
    float v=0.0,a=.5;
    for(int i=0;i<4;i++) { v+=a*noise(p);p=p*2.03+vec2(7.3,2.7);a*=.5; }
    return v;
}
vec3 champagneMarble(vec2 p) {
    float field=fbm(p*3.5);
    float stone=fbm(p*14.0);
    vec2 center=vec2(dimensions.x/dimensions.y*.5,.5);
    float distanceToCenter=length((p-center)*vec2(.72,1.0));
    float edge=smoothstep(.14,.68,distanceToCenter);
    vec3 ivory=mix(vec3(.69,.75,.76),vec3(.90,.89,.79),field);
    vec3 dusk=mix(vec3(.24,.34,.46),vec3(.46,.52,.62),stone);
    vec3 c=mix(ivory,dusk,edge*.70);
    float vein=abs(sin(p.x*7.0-p.y*4.0+fbm(p*3.0)*10.0));
    float gold=pow(1.0-vein,38.0)*smoothstep(.40,.66,field);
    c=mix(c,vec3(.82,.67,.36),gold*.28);
    c+=(stone-.5)*.035+(noise(p*350.0)-.5)*.009;
    return c;
}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 pixel) {
    vec2 p=pixel/dimensions.y;
    // Keep this static material in sync with biome_floor.glsl's fallback.
    vec3 c=champagneMarble(p);
    float vignette=1.0-.13*length((pixel/dimensions-.5)*1.4);
    // Alpha stores the static vignette rather than opacity.
    return vec4(c,vignette);
}
