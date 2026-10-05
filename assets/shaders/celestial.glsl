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
    if (biome==1.0) c=deep*.36+fog*(mist*.5+.5)*.25;
    if (biome==1.0 || biome==3.0) {
        float halo=exp(-abs(r-.52-bend)*60.0);
        float rays=pow(max(0.0,sin(a*22.0+time*.045)),14.0)*exp(-r*1.8);
        c+=accent*(halo*.65+rays*.3);
        if (biome==3.0) {
            c+=vec3(.8,.75,.76)*halo*.4;
            float wings=exp(-pow((abs(p.x)-.6)*3.0,2.0)-pow((p.y+.2+abs(p.x)*.25)*4.0,2.0));
            c+=vec3(.7,.6,.63)*wings*pow(max(0.0,sin(abs(p.x)*35.0+p.y*18.0+time*.1)),7.0)*.23;
        }
        if (biome==1.0) {
            float cloud=smoothstep(.0,.95,mist)*(.4+.6*uv.y);
            c+=vec3(.99,.89,.71)*cloud*.20;
            c+=vec3(.99,.90,.75)*exp(-r*2.8)*.08;
        }
        if (biome==6.0) c+=vec3(.23,.28,.33)*smoothstep(-.2,.8,mist);
    } else if (biome==6.0) {
        // Open sky currents: elongated, drifting spirals instead of a circular halo.
        vec2 wind=vec2(p.x*.72,p.y*1.4+sin(p.x*1.7+time*.12)*.22);
        float flow=wind.y+sin(wind.x*3.2-time*.16)*.25;
        float ribbons=pow(max(0.0,cos(flow*13.0+wind.x*2.0)),20.0);
        float spiral=atan(wind.y+.3,wind.x-.6)+length(wind-vec2(.6,-.3))*5.0-time*.14;
        float curls=pow(max(0.0,cos(spiral*3.0)),24.0)*exp(-length(wind-vec2(.6,-.3))*1.5);
        float cloud=smoothstep(-.25,.85,sin(flow*5.0)+sin(wind.x*4.0-time*.09)*.3);
        c=deep*.24+fog*cloud*.22;
        c+=accent*(ribbons*.18+curls*.28)+vec3(.79,.90,1.0)*cloud*.09;
    } else if (biome==8.0) {
        float gate=exp(-abs(length(p*vec2(.8,1.15))-.58)*55.0);
        float arc=pow(max(0.0,cos(a*12.0+time*.06)),24.0)*exp(-abs(r-.74)*35.0);
        float veil=sin(p.y*5.0-time*.15+sin(p.x*3.0))*0.5+0.5;
        c+=vec3(.4,.25,.7)*gate*.7+vec3(.85,.72,1.0)*arc*.25+fog*veil*.08;
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
