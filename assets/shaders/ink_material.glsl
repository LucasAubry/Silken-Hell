extern vec4 sprite_rect;
extern vec2 texel_step;
extern number strength;
extern number scenery;
extern number premultiplied;

vec4 inkSample(Image tex,vec2 uv) {
    return Texel(tex,clamp(uv,sprite_rect.xy+texel_step*.5,sprite_rect.xy+sprite_rect.zw-texel_step*.5));
}
float inkValue(vec4 p) {
    vec3 rgb=p.rgb/max(mix(1.,p.a,premultiplied),.001);
    return max(rgb.r,max(rgb.g,rgb.b));
}
vec4 inkSurface(vec4 source,Image tex,vec2 uv) {
    vec3 original=source.rgb/max(mix(1.,source.a,premultiplied),.001);
    float value=max(original.r,max(original.g,original.b));
    vec4 left=inkSample(tex,uv-vec2(texel_step.x,0.));
    vec4 right=inkSample(tex,uv+vec2(texel_step.x,0.));
    vec4 up=inkSample(tex,uv-vec2(0.,texel_step.y));
    vec4 down=inkSample(tex,uv+vec2(0.,texel_step.y));
    // Ignore transparent RGB: it must not draw a second outline inside a sprite.
    float horizontal=abs(inkValue(left)-inkValue(right))*min(left.a,right.a);
    float vertical=abs(inkValue(up)-inkValue(down))*min(up.a,down.a);
    float edge=max(horizontal,vertical);
    float inside=smoothstep(.16,.42,edge);
    float rim=(1.-min(min(left.a,right.a),min(up.a,down.a)))*smoothstep(.3,.9,source.a);
    // Flat painted shadow bands, with a narrow soft boundary to avoid shimmer.
    float bands=value*10.;
    float painted=(floor(bands)+smoothstep(.3,.7,fract(bands)))/10.;
    float amount=mix(1.,.38,scenery)*strength;
    float tone=mix(value,painted,.48*amount*smoothstep(.035,.16,value));
    // Draw contours inside the existing silhouette: never grow or replace alpha.
    float contour=max(inside*.20,rim*.42)*amount;
    tone*=1.-contour;
    // A single RGB multiplier retains every authored hue and saturation.
    float gain=min(tone/max(value,.001),1./max(value,.001));
    return vec4(original*gain*mix(1.,source.a,premultiplied),source.a);
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen) {
    return inkSurface(Texel(tex,uv),tex,uv)*color;
}
