extern number time;
extern vec2 screen_size;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 base = Texel(tex, tc);
    float noise = random(tc * screen_size + time) * 0.05; // ici tu peux tester plus fort pour vérifier l’effet
    return vec4(base.rgb + noise, base.a) * color;
}

