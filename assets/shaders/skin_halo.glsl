extern float clock;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec2 p=(uv-.5)*2.;
    float r=length(p);
    // Carry the light around the ellipse, keeping its plane above the head.
    // A shared angular phase gives the wisps a clear, continuous orbit.
    float angle=atan(p.y,p.x)-clock*.85;
    float drift=angle*3.;
    float curl=sin(drift);
    float folds=sin(angle*5.+.7);
    float edge=.64+.035*curl+.018*folds;
    // Overlapping soft light patches retain the halo's shape without a wire
    // outline. Smoothstep falloffs avoid costly exponential smoke layers.
    float thickness=max(.18+.045*folds,fwidth(r)*.8);
    float ribbon=1.-smoothstep(0.,thickness,abs(r-edge));
    float veil=1.-smoothstep(.025,.24,abs(r-edge-.035*curl));
    float patches=.5+.5*sin(angle*2.+curl*.8);
    float wisp=1.-smoothstep(0.,.095,abs(r-edge-.095-.028*folds));
    float fade=1.-smoothstep(.84,1.,r);
    float core=1.-smoothstep(.025,.09,abs(r-edge));
    float light=clamp(core*.72+ribbon*(.32+.48*patches)+veil*.30+wisp*patches*.22,0.,1.)*fade;
    return vec4(1.,.10,.055,light)*color;
}
