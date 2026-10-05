extern number time;
extern vec2 screen_size;

float random(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233))) *
        43758.5453123);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    float shift = 0.004 * sin(time * 10.0);

    // Aberration chromatique
    vec2 rCoord = tc + vec2(shift, 0.0);
    vec2 gCoord = tc;
    vec2 bCoord = tc - vec2(shift, 0.0);

    float r = Texel(tex, rCoord).r;
    float g = Texel(tex, gCoord).g;
    float b = Texel(tex, bCoord).b;

    // Grain animé
    float grain = random(tc * screen_size + time) * 0.1;

    // Distorsion centrale
    vec2 center = vec2(0.5, 0.5);
    vec2 toCenter = tc - center;
    float dist = length(toCenter);
    float strength = 0.02;
    vec2 distorted = tc + normalize(toCenter) * sin(dist * 15.0 - time * 5.0) * strength * dist;

    vec4 distortedColor = vec4(
        Texel(tex, distorted + vec2(shift, 0.0)).r,
        Texel(tex, distorted).g,
        Texel(tex, distorted - vec2(shift, 0.0)).b,
        1.0
    );

    return vec4(distortedColor.rgb + grain, 1.0) * color;
}

