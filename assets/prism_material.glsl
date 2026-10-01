extern vec4 sprite_rect;
extern vec2 texel_step;
extern number clock;
extern number strength;
extern number scenery;
extern number premultiplied;

float heightAt(Image tex,vec2 uv) {
    vec4 p=Texel(tex,clamp(uv,sprite_rect.xy,sprite_rect.xy+sprite_rect.zw));
    return dot(p.rgb,vec3(.2126,.7152,.0722))*p.a;
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen) {
    vec4 source=Texel(tex,uv);
    vec3 original=source.rgb/max(mix(1.,source.a,premultiplied),.001);
    float light=dot(original,vec3(.2126,.7152,.0722));
    if (scenery>.5) {
        // Scenery keeps its authored colors exactly.
        return source*color;
    }
    vec2 q=(uv-sprite_rect.xy)/sprite_rect.zw-.5;
    float gx=heightAt(tex,uv+vec2(texel_step.x,0.))-heightAt(tex,uv-vec2(texel_step.x,0.));
    float gy=heightAt(tex,uv+vec2(0.,texel_step.y))-heightAt(tex,uv-vec2(0.,texel_step.y));
    vec3 normal=normalize(vec3(q.x*.55-gx*2.8,-q.y*.55-gy*2.8,.85));
    float diffuse=max(0.,dot(normal,normalize(vec3(-.4,.65,1.))));
    float band=pow(.5+.5*sin((light*2.2+q.x*.3-q.y*.45)*12.+clock*.12),12.);
    // One common RGB gain preserves hue and saturation, including neutral ink.
    // Limit the gain before clipping so bright colors cannot shift hue either.
    float shine=(band*.24+pow(diffuse,24.)*.13)*smoothstep(.035,.23,light)*strength;
    float gain=min(1.+shine,1./max(max(original.r,original.g),max(original.b,.001)));
    vec3 result=original*gain;
    return vec4(result*mix(1.,source.a,premultiplied),source.a)*color;
}
