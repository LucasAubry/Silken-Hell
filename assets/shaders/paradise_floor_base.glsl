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
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 pixel) {
    vec2 p=pixel/dimensions.y;
    float grain=noise(p*350.0), terrain=fbm(p*7.0);
    float marble=pow(abs(sin(p.x*8.0+p.y*5.0+fbm(p*4.0)*13.0)),18.0);
    vec3 c=mix(vec3(.78,.78,.75),vec3(.93,.92,.87),terrain);
    c=mix(c,vec3(.43,.45,.44),smoothstep(.78,.99,marble)*.14);
    c+=(grain-.5)*.012;
    float vignette=1.0-.13*length((pixel/dimensions-.5)*1.4);
    // Alpha stores the static vignette rather than opacity.
    return vec4(c,vignette);
}
