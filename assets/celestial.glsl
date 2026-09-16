extern number time;
extern number inferno;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
    vec2 p=uv*2.0-1.0; p.x*=1.6;
    float r=length(p*vec2(0.8,1.0));
    float a=atan(p.y,p.x);
    float bend=sin(r*12.0-time*0.35+sin(a*3.0))*0.035;
    float mist=sin(p.x*4.0+sin(p.y*5.0+time*0.18))*sin(p.y*4.0-time*0.12+bend*15.0);
    float halo=exp(-abs(r-0.52-bend)*60.0);
    float ring=exp(-abs(r-0.59+bend*0.3)*100.0);
    float rays=pow(max(0.0,sin(a*22.0+time*0.045)),14.0)*exp(-r*1.8);
    float aurora=exp(-abs(p.y+0.4+sin(p.x*2.0+time*0.15)*0.12)*8.0);
    vec3 dark=mix(vec3(0.035,0.075,0.105),vec3(0.08,0.018,0.035),inferno);
    vec3 gold=mix(vec3(1.0,0.83,0.47),vec3(1.0,0.26,0.08),inferno);
    vec3 fog=mix(vec3(0.17,0.36,0.39),vec3(0.34,0.065,0.035),inferno);
    vec3 c=dark+fog*(mist*0.5+0.5)*0.5;
    c+=gold*(halo*0.65+ring*0.28+rays*0.3);
    c+=fog*exp(-r*2.0)*0.55+gold*aurora*0.065;
    c*=1.0-smoothstep(0.7,1.8,r)*0.4;
    return vec4(c,1.0)*color;
}
