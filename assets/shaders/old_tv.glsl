extern vec2 screenSize;
extern float clock;

float grain(vec2 p) {
    return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}

vec4 effect(vec4 color,Image image,vec2 uv,vec2 screen) {
    vec2 pixel=uv*screenSize;
    // Stable fine scanlines, independent of the game's camera and pixel art.
    float rows=min(screenSize.y/3.,480.);
    float scan=pow(.5+.5*cos(uv.y*rows*6.283185),4.);
    vec2 edge=abs(uv-.5)*2.;
    float vignette=smoothstep(.35,1.35,length(edge));
    float noise=grain(floor(pixel/2.)+floor(clock*12.));
    float dust=(noise-.5)*.025;
    float shade=.018+.085*scan+.16*vignette+max(0.,-dust);
    // A faint warm phosphor tint and sparse bright grain keep blacks deep.
    vec3 tint=vec3(.055,.040,.025)+max(0.,dust)*1.5;
    return vec4(tint,shade)*color;
}
