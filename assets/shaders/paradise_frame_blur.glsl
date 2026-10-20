extern vec2 stepUV;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
    // Blur premultiplied colour and alpha together to keep transparent edges clean.
    vec4 sum = Texel(tex, uv) * 0.227027;
    sum += Texel(tex, uv + stepUV * 1.384615) * 0.316216;
    sum += Texel(tex, uv - stepUV * 1.384615) * 0.316216;
    sum += Texel(tex, uv + stepUV * 3.230769) * 0.070270;
    sum += Texel(tex, uv - stepUV * 3.230769) * 0.070270;
    return sum * color;
}
