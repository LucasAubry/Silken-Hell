extern number time;
extern number biome;
extern vec3 deep;
extern vec3 fog;
extern vec3 accent;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
    vec2 p=uv*2.0-1.0; p.x*=1.6;
    float r=length(p*vec2(.8,1.0)); float a=atan(p.y,p.x);
    float bend=sin(r*12.0-time*.35+sin(a*3.0))*.035;
    float mist=sin(p.x*4.0+sin(p.y*5.0+time*.18))*sin(p.y*4.0-time*.12+bend*15.0);
    vec3 c=deep*.15+fog*(mist*.5+.5)*.35;
    if (biome==1.0 || biome==6.0 || biome==3.0) {
        float halo=exp(-abs(r-.52-bend)*60.0);
        float rays=pow(max(0.0,sin(a*22.0+time*.045)),14.0)*exp(-r*1.8);
        c+=accent*(halo*.65+rays*.3);
        if (biome==3.0) {
            c+=vec3(.8,.75,.76)*halo*.4;
            float wings=exp(-pow((abs(p.x)-.6)*3.0,2.0)-pow((p.y+.2+abs(p.x)*.25)*4.0,2.0));
            c+=vec3(.7,.6,.63)*wings*pow(max(0.0,sin(abs(p.x)*35.0+p.y*18.0+time*.1)),7.0)*.23;
        }
        if (biome==6.0) c+=vec3(.23,.28,.33)*smoothstep(-.2,.8,mist);
    } else if (biome==4.0 || biome==7.0) {
        float wave=sin(p.y*18.0+sin(p.x*6.0+time*.4)*2.0-time*.6);
        c+=accent*pow(max(0.0,wave),10.0)*.12;
        if (biome==7.0) c*=.27;
    } else if (biome==5.0) {
        float cracks=abs(sin(p.x*7.0+sin(p.y*4.0))*sin(p.y*9.0+p.x));
        c*=.4+smoothstep(.02,.15,cracks)*.9;
        c+=accent*exp(-r*2.0)*.15;
    } else {
        float flame=sin(p.x*12.0+sin(p.y*4.0-time)*2.0);
        c+=accent*pow(max(0.0,flame),8.0)*(.1+uv.y*.25);
    }
    c*=1.0-smoothstep(.7,1.8,r)*.4;
    return vec4(c,1.0)*color;
}
