// Same smooth three-color loop as prism_palette.sample, in cycles.
vec3 prismColor(float phase, vec3 a, vec3 b, vec3 c) {
    float q=fract(phase)*3.;
    float t=smoothstep(0.,1.,fract(q));
    if (q<1.) return mix(a,b,t);
    if (q<2.) return mix(b,c,t);
    return mix(c,a,t);
}
