extern vec4 bounds;
extern bool bodyLayer;
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
    vec2 localUV=(uv-bounds.xy)/bounds.zw-vec2(.5);
    float body=1.0-smoothstep(.215,.225,length(localUV));
    vec4 pixel=Texel(texture,uv)*color;
    pixel.a*=bodyLayer ? body : 1.0-body;
    return pixel;
}
