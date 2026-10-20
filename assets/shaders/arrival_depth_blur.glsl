extern vec2 stepUV;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 pixel) {
 vec4 sum=Texel(image,uv)*.2270270270;
 sum+=(Texel(image,clamp(uv+stepUV*.3846153846,0.,1.))
      +Texel(image,clamp(uv-stepUV*.3846153846,0.,1.)))*.3162162162;
 sum+=(Texel(image,clamp(uv+stepUV*.8076923077,0.,1.))
      +Texel(image,clamp(uv-stepUV*.8076923077,0.,1.)))*.0702702703;
 return color*sum;
}
