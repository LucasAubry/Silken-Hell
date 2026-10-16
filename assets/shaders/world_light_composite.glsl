extern Image lightMap;
extern vec2 lightStep;
extern float ambient;
extern float scatter;
extern float softHighlights;
extern float preserveEmbers;
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 pixel) {
    vec4 surface=Texel(texture,uv);
    if(max(surface.r,max(surface.g,surface.b))<.001) return surface*color;
    // Filter only the low resolution light map; keep the illustrated scene crisp.
    vec3 light=Texel(lightMap,uv).rgb*0.4;
    light+=Texel(lightMap,uv+vec2(lightStep.x,0.0)).rgb*0.15;
    light+=Texel(lightMap,uv-vec2(lightStep.x,0.0)).rgb*0.15;
    light+=Texel(lightMap,uv+vec2(0.0,lightStep.y)).rgb*0.15;
    light+=Texel(lightMap,uv-vec2(0.0,lightStep.y)).rgb*0.15;
    light=min(light,vec3(1.35));
    vec3 lit=surface.rgb*(ambient+light*0.85);
    vec3 gentle=surface.rgb*ambient+(vec3(1.0)-surface.rgb*ambient)*light*.48;
    lit=mix(lit,gentle,softHighlights);
    // Scattering stays local; Abyss darkness never receives an additive reveal.
    lit+=light*scatter*surface.a;
    // Emissive molten pixels keep their colour instead of clipping under bursts.
    float ember=smoothstep(.48,.9,surface.r)*smoothstep(.09,.3,surface.r-surface.b)*preserveEmbers;
    lit=mix(lit,surface.rgb,ember*.9);
    return vec4(lit,surface.a)*color;
}
