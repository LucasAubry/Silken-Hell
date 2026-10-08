extern vec2 viewport;
extern float clock;
extern float ignition;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 pixel) {
    vec2 edge=min(uv,1.-uv)*viewport;
    float d=min(edge.x,edge.y);
    float scale=min(viewport.x/1200.,viewport.y/750.);
    float pulse=.86+.14*sin(clock*2.2);
    float glow=exp(-d/max(1.,24.*scale));
    float rim=1.-smoothstep(1.*scale,4.*scale,d);
    vec3 red=mix(vec3(.60,.005,.035),vec3(1.,.16,.09),rim);
    // Two fronts start at the top/bottom centers and meet on both sides.
    float route=abs(uv.x-.5)*viewport.x;
    if(edge.x<edge.y) route=viewport.x*.5+min(uv.y,1.-uv.y)*viewport.y;
    float front=ignition*(viewport.x+viewport.y)*.5;
    float lit=ignition>=1. ? 1. : 1.-smoothstep(front-12.*scale,front+12.*scale,route);
    float spark=ignition>=1. ? 0. : exp(-abs(route-front)/max(1.,9.*scale));
    red=mix(red,vec3(1.,.52,.25),spark*.7);
    return vec4(red,clamp(glow*.64*pulse+rim*.48+spark*glow*.2,0.,.97)*lit);
}
