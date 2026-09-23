extern number clock;
extern number biome;
extern number transmission;
extern number levelSeed;
extern number depth;
extern vec2 dimensions;
extern vec3 lightTint;
extern vec4 localLights[8];
vec4 effect(vec4 color,Image texture,vec2 uv,vec2 pixel) {
    vec2 p=pixel/dimensions;
    float shafts=0.0;
    float patches=0.0;
    for(int i=0;i<4;i++) {
        float k=float(i);
        float origin=.04+k*.26+sin(levelSeed+k*2.7)*.055;
        float center=origin+p.y*.16+sin(clock*.12+k*2.0)*.012;
        float width=.019+p.y*.055;
        float ray=exp(-pow((p.x-center)/width,2.0));
        float ribs=.76+.24*sin(p.x*290.0-p.y*38.0+k+clock*.16);
        shafts+=ray*ribs*(.85-p.y*.36);
        vec2 site=vec2(origin+.07,.22+fract(sin(levelSeed+k*13.0)*137.0)*.6);
        vec2 delta=(p-site)*vec2(dimensions.x/dimensions.y,1.0);
        patches+=exp(-dot(delta,delta)*(biome==5.0?70.0:24.0));
    }
    float local=0.0;
    for(int i=0;i<8;i++) {
        float d=length(pixel-localLights[i].xy)/max(1.0,localLights[i].z);
        local+=max(0.0,1.0-d)*max(0.0,1.0-d)*localLights[i].w;
    }
    float rays=shafts*transmission;
    float haze=.5+.5*sin(p.x*12.0+sin(p.y*8.0+clock*.13)+clock*.09);
    patches+=haze*.055;
    if(biome==1.0 || biome==6.0) rays*=1.12;

    if(biome==4.0) rays*=1.35;
    if(biome==5.0) { rays*=.55;patches=haze*.035; } // Narrow overhead shafts; keep the surrounding earth dark.
    if(biome==2.0) rays=patches*.18; // Ember light rises from the floor in Hell.
    float lit=clamp(rays*.7+patches*(biome==5.0?.95:.35)*transmission+local,0.0,1.0);
    float shade=biome==5.0?.20:biome==4.0?.12:biome==2.0?.22:.13;
    shade+=(1.0-transmission)*.16+depth*.045;
    float edge=length((p-.5)*vec2(1.0,.8));
    shade+=smoothstep(.3,.7,edge)*.09;
    float caustic=0.0;
    if(biome==4.0) {
        float wave=sin(p.x*59.0+p.y*26.0+sin(p.y*39.0-clock*.6)*1.8+clock*.4);
        caustic=pow(abs(wave),24.0)*patches*.07;
    }
    vec3 shadow=biome==4.0?vec3(.0,.025,.07):vec3(.017,.009,.02);
    float blend=smoothstep(.03,biome==5.0?.5:.8,lit);
    vec3 tint=mix(shadow,lightTint,blend);
    float alpha=mix(shade,.19,blend)+caustic;
    return vec4(tint,alpha)*color;
}
