extern number time;
extern vec2 screen_size;
extern vec2 focus;
extern vec2 velocity;
extern number speed;
extern number surge_amount;
extern vec2 death_center;
extern vec2 pickup_center;
extern number death_amount;
extern number pickup_amount;
extern number death_progress;
extern number pickup_progress;
extern number intensity;
extern number death_scale;
extern number pickup_scale;
extern vec3 palette_a;
extern vec3 palette_b;
extern vec3 palette_c;
extern vec3 death_palette_a;
extern vec3 death_palette_b;
extern vec3 death_palette_c;
extern vec3 pickup_palette_a;
extern vec3 pickup_palette_b;
extern vec3 pickup_palette_c;

vec3 spectrum(float phase) {
    return prismColor(phase,palette_a,palette_b,palette_c);
}
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec2 aspect=vec2(screen_size.x/screen_size.y,1.);
    vec2 radial=(uv-focus)*aspect;
    float edge=smoothstep(.22,.72,length((uv-.5)*aspect));
    vec2 d=(uv-death_center)*aspect;
    vec2 p=(uv-pickup_center)*aspect;
    float rawDl=length(d),rawPl=length(p);
    vec2 dn=d/max(rawDl,.001),pn=p/max(rawPl,.001);
    float dl=rawDl/death_scale,pl=rawPl/pickup_scale;
    float dw=(dl-death_progress*.95)*13.;
    float echo=(dl-death_progress*1.45)*21.;
    float pw=(pl-abs(.24-pickup_progress*.7))*24.;
    float deathWave=exp(-dw*dw)+exp(-echo*echo)*.38,pickupWave=exp(-pw*pw);
    float da=death_amount*intensity;
    float pa=pickup_amount*intensity*(1.-smoothstep(.32,.48,pl));
    float rush=min(1.,speed+surge_amount*.22)*intensity*edge;
    // Movement distortion stays peripheral; impact pulses follow the event.
    vec2 warped=uv-radial/aspect*rush*.029-velocity/aspect*rush*.006;
    warped+=dn/aspect*sin(dl*32.-death_progress*12.)*deathWave*da*.025;
    warped-=pn/aspect*pickupWave*pa*.019;
    warped+=vec2(-dn.y,dn.x)/aspect*deathWave*da*.017;
    warped+=vec2(-pn.y,pn.x)/aspect*pickupWave*pa*.009;
    vec2 split=(radial*rush*.004+dn*da*(.003+deathWave*.009)+pn*pa*pickupWave*.009)/aspect;
    vec2 lo=vec2(.001),hi=vec2(.999);
    vec3 base=Texel(tex,clamp(warped,lo,hi)).rgb;
    vec3 rgb=vec3(Texel(tex,clamp(warped+split,lo,hi)).r,base.g,Texel(tex,clamp(warped-split,lo,hi)).b);
    if (da>.001) {
        float sector=floor((atan(d.y,d.x+.00001)+3.14159+death_progress*.5)/.62832)*.62832;
        vec2 facet=vec2(cos(sector),sin(sector));
        vec2 mirrored=death_center+reflect(d,facet)/aspect;
        vec3 shard=Texel(tex,clamp(mirrored,lo,hi)).rgb;
        rgb=mix(rgb,shard*prismColor(sector*.13+death_progress,death_palette_a,death_palette_b,death_palette_c),clamp(deathWave*da*.48,0.,.6));
    }
    float contour=length(Texel(tex,clamp(warped+vec2(2./screen_size.x,0.),lo,hi)).rgb-base);
    vec3 prism=spectrum(dl*2.5+pl*1.8-time*.3);
    if (da>.001) prism=prismColor(dl*2.5-time*.3,death_palette_a,death_palette_b,death_palette_c);
    else if (pa>.001) prism=prismColor(pl*1.8-time*.3,pickup_palette_a,pickup_palette_b,pickup_palette_c);
    rgb=mix(rgb,prism,clamp(contour*(da*.9+pa*.7+rush*.3),0.,.6));
    rgb*=1.-da*.22-pa*pickupWave*.15-rush*.09;
    rgb+=prismColor(dl*3.-death_progress*.8,death_palette_a,death_palette_b,death_palette_c)*deathWave*da*.2;
    rgb+=prismColor(pl*5.+pickup_progress,pickup_palette_a,pickup_palette_b,pickup_palette_c)*pickupWave*pa*.22;
    float angle=atan(radial.y,radial.x+.00001);
    float rays=pow(max(0.,sin(angle*24.+time*.7)),32.);
    rgb+=spectrum(angle*.8+time*.1)*rays*rush*.12;
    // Two faint radial echoes give speed a lens-like drag, without a history buffer.
    if (rush>.015) {
        vec2 stretch=radial/aspect*rush*.016;
        vec3 trail=(Texel(tex,clamp(warped+stretch,lo,hi)).rgb+Texel(tex,clamp(warped+stretch*2.,lo,hi)).rgb)*.5;
        rgb=mix(rgb,trail,rush*.16);
    }
    return vec4(rgb,Texel(tex,uv).a)*color;
}
