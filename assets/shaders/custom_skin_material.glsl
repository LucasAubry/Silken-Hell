vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec4 p=Texel(image,uv);
    vec3 pigment=p.rgb/max(p.a,.00001);
    // Keep authored glasses, silk and eye colors; soften the surface highlights.
    float light=dot(pigment,vec3(.299,.587,.114));
    vec3 ink=(pigment-vec3(.30))*1.04+vec3(.30);
    ink=mix(ink,vec3(.97,.95,.88)*light,.08*smoothstep(.4,.85,light));
    return vec4(clamp(ink,0.,1.),p.a)*color;
}
