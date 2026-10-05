extern vec3 bodyColor;
extern vec3 eyeColor;
extern bool sideView;
extern bool brownSkin;
extern bool locked;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec4 p=Texel(image,uv);
    vec3 rgb=p.rgb;
    if (sideView) {
        // Preserve the original brown profile exactly for Soie.
        if (!brownSkin) {
            float value=clamp(p.r/0.62,0.,1.);
            float eye=step(.65,p.r)*step(p.b*1.9+.08,p.g)*step(p.g*1.25,p.r);
            rgb=mix(bodyColor*value,eyeColor*max(p.r,p.g),eye);
            if (min(p.r,min(p.g,p.b))>.8) rgb=p.rgb;
        }
    } else {
        float eye=step(p.r*1.5+.05,p.b)*step(.2,p.b);
        float gold=step(p.b*1.5+.1,p.r)*step(p.b*1.2+.05,p.g);
        rgb=mix(p.rgb*bodyColor,p.rgb,gold);
        rgb=mix(rgb,eyeColor*max(p.b,p.g),eye);
    }
    if (locked) rgb=vec3(dot(rgb,vec3(.299,.587,.114))*.65);
    return vec4(rgb,p.a)*color;
}
