vec4 effect(vec4 color, Image texture, vec2 uv, vec2 pixel) {
    float radius = length(uv * 2.0 - 1.0);
    float halo = pow(max(0.0, 1.0 - radius * radius), 3.0);
    float core = exp(-radius * radius * 24.0);
    vec3 lightColor = mix(vec3(0.10, 0.46, 1.0), vec3(0.48, 0.88, 1.0), core);
    return vec4(lightColor * color.rgb, halo * color.a);
}
