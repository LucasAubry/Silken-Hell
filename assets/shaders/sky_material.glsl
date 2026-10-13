extern float material_kind;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    vec4 source=Texel(tex,uv);
    float value=dot(source.rgb,vec3(.299,.587,.114));
    vec3 slate=vec3(.13,.22,.30);
    vec3 pearl=vec3(.91,.95,.96);
    // Match cloud traps and portals to the same storm-cloud ramp as the floor.
    if (material_kind>4.5) value=mix(.35,.94,value);
    vec3 rgb=mix(slate,vec3(.49,.62,.70),smoothstep(.04,.55,value));
    rgb=mix(rgb,pearl,smoothstep(.55,1.,value));
    // Beaks keep a restrained amber accent; reflected feathers use their own shader.
    if (material_kind>2.5 && material_kind<3.5) {
        float warm=smoothstep(.08,.25,source.r-source.b)*smoothstep(.06,.18,source.g-source.b);
        rgb=mix(rgb,mix(vec3(.49,.34,.17),vec3(.88,.75,.44),value),warm);
    }
    return vec4(rgb,source.a)*color;
}
