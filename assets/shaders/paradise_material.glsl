extern vec4 sprite_rect;
extern vec2 texel_step;
extern number material_kind;

vec4 nearby(Image tex,vec2 uv) {
    return Texel(tex,clamp(uv,sprite_rect.xy+texel_step*.5,sprite_rect.xy+sprite_rect.zw-texel_step*.5));
}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 pixel) {
    vec4 source=Texel(tex,uv);
    vec3 rgb=source.rgb;
    float light=dot(rgb,vec3(.299,.587,.114));
    float chroma=max(rgb.r,max(rgb.g,rgb.b))-min(rgb.r,min(rgb.g,rgb.b));
    // Keep the painted shading and warm ink. Flattening it into a new palette
    // erased the feather layers, stone bevels and the metal rims at game size.
    float value=light;
    vec3 result=(rgb-vec3(.38))*1.10+vec3(.38);
    result+=vec3(.040,.014,-.012)*smoothstep(.10,.72,value);
    float green=smoothstep(.0,.06,rgb.g-rgb.r)*(1.-smoothstep(.0,.09,rgb.b-rgb.g));
    vec3 sage=mix(vec3(.12,.17,.075),vec3(.78,.80,.47),smoothstep(.04,.88,value));
    result=mix(result,sage,green*.24);
    if(material_kind>0.5 && material_kind<1.5) {
        // Original repeating stone blocks, now warm ivory with dark fine joints.
        vec3 shade=mix(vec3(.115,.085,.055),vec3(.65,.53,.37),smoothstep(.025,.50,value));
        result=mix(shade,vec3(1.,.93,.78),smoothstep(.42,.98,value));
    } else if(material_kind>1.5 && material_kind<2.5) {
        result=mix(rgb,mix(vec3(.12,.085,.05),vec3(.85,.67,.39),smoothstep(.015,.85,value)),.58);
    } else if(material_kind>2.5 && material_kind<3.5) {
        // Black feathers retain their dark readable silhouette and amber details.
        float cool=smoothstep(.005,.07,rgb.b-rgb.r);
        result=mix(result,mix(vec3(.035,.075,.085),vec3(.47,.64,.60),value),cool*.65);
    } else if(material_kind>3.5) {
        result=rgb;
    }
    vec4 left=nearby(tex,uv-vec2(texel_step.x,0.));
    vec4 right=nearby(tex,uv+vec2(texel_step.x,0.));
    vec4 up=nearby(tex,uv-vec2(0.,texel_step.y));
    vec4 down=nearby(tex,uv+vec2(0.,texel_step.y));
    float edge=(1.-min(min(left.a,right.a),min(up.a,down.a)))*smoothstep(.25,.9,source.a);
    float face=smoothstep(.15,.55,value);
    float raised=(dot(up.rgb-left.rgb,vec3(.299,.587,.114)))*.06;
    result+=vec3(.95,.82,.53)*raised*face;
    result=mix(result,vec3(.16,.105,.055),edge*.14);
    return vec4(clamp(result,0.,1.),source.a)*tint;
}
