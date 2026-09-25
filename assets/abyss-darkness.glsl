extern vec4 lights[24];
extern Image trailMask;
extern vec2 arenaSize;
extern bool useTrailMask;
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 pixel) {
    float light = 0.0;
    for (int i=0; i<24; i++) {
        float distanceToLight = length(pixel-lights[i].xy)/max(1.0,lights[i].z);
        light = max(light,(1.0-smoothstep(0.05,1.0,distanceToLight))*lights[i].w);
    }
    float reveal=useTrailMask ? clamp(Texel(trailMask,pixel/arenaSize).r,0.0,1.0) : 0.0;
    return vec4(0.0,0.002,0.008,(0.992-0.86*clamp(light,0.0,1.0))*(1.0-reveal));
}
