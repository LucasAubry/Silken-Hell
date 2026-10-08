extern float clock;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec2 d=(uv-.5)*2.;
    float radius=length(d);
    float angle=atan(d.y,d.x)-clock*.12;
    float broad=pow(.5+.5*cos(angle*9.),5.);
    float fine=pow(.5+.5*sin(angle*17.+clock*.55),14.);
    float edge=(1.-smoothstep(.12,1.,radius))*exp(-radius*1.3);
    float rays=(broad*.14+fine*.045)*smoothstep(.06,.21,radius);
    float halo=.10*exp(-radius*5.);
    float pulse=.94+.06*sin(clock*.9);
    vec3 gold=mix(vec3(.94,.68,.28),vec3(1.,.89,.61),exp(-radius*6.));
    return vec4(gold,(rays+halo)*edge*pulse)*color;
}
