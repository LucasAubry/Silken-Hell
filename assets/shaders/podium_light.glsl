extern vec2 origin;
extern vec3 lightColor;
extern float clock;
extern float arrival;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec2 d=uv*vec2(1200.,750.)-origin;
    float radius=length(d);
    float angle=atan(d.y,d.x);
    float turn=clock*.16;
    float broad=pow(.5+.5*cos((angle-turn)*9.),12.);
    float fine=pow(.5+.5*sin((angle-turn*.7)*19.+sin(clock*.24)*.3),36.);
    float drift=.82+.18*sin(clock*.8+radius*.002);
    float rays=(broad*.25+fine*.16)*exp(-radius/1300.)*smoothstep(7.,60.,radius);
    float halo=.30*exp(-radius/220.);
    float core=.20*exp(-radius*radius/1500.);
    // A bright arrival settles gently to 78%, then keeps rotating indefinitely.
    float settle=.78+.22*exp(-max(0.,clock-.7)*1.6);
    float centreShade=.38+.62*smoothstep(16.,49.,radius);
    float alpha=(rays*drift+halo+core)*arrival*settle*centreShade;
    vec3 tint=mix(lightColor,vec3(1.,.97,.85),exp(-radius/95.)*.7);
    return vec4(tint,alpha)*color;
}
