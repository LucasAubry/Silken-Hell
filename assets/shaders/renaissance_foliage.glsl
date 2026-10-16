extern float clock;
extern vec2 dimensions;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
    vec2 position = uv * dimensions;
    // Keep the roots attached to the perimeter; tips catch more of the breeze.
    vec2 edge = min(position, dimensions - position);
    float anchored = smoothstep(0.0, 65.0, min(edge.x, edge.y));
    float breeze = sin(clock * 0.85 + position.x * 0.012 + position.y * 0.006);
    float flutter = sin(clock * 1.35 - position.x * 0.021 + position.y * 0.017);
    vec2 drift = anchored * vec2(2.4 * breeze + 0.65 * flutter, 0.85 * flutter);
    vec2 sampleUV = uv + drift / dimensions;
    return Texel(tex, sampleUV) * color;
}
