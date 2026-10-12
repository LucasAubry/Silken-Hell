extern vec3 bodyColor;
extern bool sideView;
extern bool frontView;
extern bool brownSkin;
extern bool locked;
extern bool paletteSkin;
extern vec3 markingColor;
extern vec3 irisColor;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec4 p=Texel(image,uv);
    // Mipmaps average the clean transparent pixels as premultiplied color.
    // Recover the pigment before recoloring; preserve coverage at the edge.
    p.rgb/=max(p.a,.00001);
    // All three PNGs contain their own markings; palette variants recolor the material.
    // Classify gold by chroma, including its pale highlights. Multiplicative
    // thresholds rejected bright yellow pixels and punched skin-colored speckles
    // into the emblem, especially on saturated red and blue skins.
    float gold=smoothstep(.08,.14,p.r-p.b)*smoothstep(.04,.065,p.g-p.b);
    vec3 rgb=mix(p.rgb*bodyColor,p.rgb,gold);
    if (paletteSkin) {
        // Change only the material: silhouette, engraved marks and shading are authored.
        rgb=mix(p.rgb*bodyColor,markingColor*max(p.r,max(p.g,p.b)),gold);
    }
    if (brownSkin) rgb=dot(p.rgb,vec3(.299,.587,.114))*vec3(.36,.22,.136);

    // Preserve the entire eye material (pupil, iris, catchlight), not isolated
    // white pixels. UVs cover only the eyes in the shared, authored PNGs.
    bool eyes=(frontView && uv.y>.515 && uv.y<.685 &&
        ((uv.x>.345 && uv.x<.458) || (uv.x>.542 && uv.x<.655)))
        || (sideView && uv.x>.168 && uv.x<.274 && uv.y>.485 && uv.y<.641);
    if (eyes) {
        // Restrict the material to blue pixels and neutral highlights; leave
        // the warm-white body around the eye in the skin's own palette.
        float blue=smoothstep(.025,.08,p.b-p.r);
        float white=smoothstep(.85,.94,min(p.r,min(p.g,p.b)))
            *step(p.r-.015,p.b)*step(p.g-.015,p.b);
        vec3 eye=p.rgb;
        if (paletteSkin) {
            float iris=smoothstep(.08,.18,p.b-p.r)*smoothstep(.16,.30,p.b);
            eye=mix(vec3(min(p.r,p.g)),irisColor*p.b,iris);
            eye=mix(eye,p.rgb,white);
        }
        if (brownSkin) {
            // Continuous blue-to-amber mapping avoids threshold speckles.
            float iris=smoothstep(.08,.18,p.b-p.r)*smoothstep(.16,.30,p.b);
            vec3 amber=vec3(p.b,.15*p.b+.70*p.g,.03*p.b);
            vec3 pupil=vec3(min(p.r,p.g));
            eye=mix(p.rgb,mix(pupil,amber,iris),blue);
        }
        rgb=mix(rgb,eye,max(blue,white));
    }
    if (locked) rgb=vec3(0.);
    return vec4(rgb,p.a)*color;
}
