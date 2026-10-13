extern vec2 arenaSize;
extern vec4 source;
extern vec3 lightColor;
extern int blockerCount;
extern vec4 blockers[24];
extern vec2 rotations[24];

vec2 localPoint(vec2 p, vec2 rotation) {
    return vec2(p.x*rotation.x+p.y*rotation.y,-p.x*rotation.y+p.y*rotation.x);
}
float visibility(vec2 point) {
    for (int i=0;i<24;i++) {
        if (i>=blockerCount) break;
        vec2 origin=localPoint(source.xy-blockers[i].xy,rotations[i]);
        vec2 target=localPoint(point-blockers[i].xy,rotations[i]);
        vec2 size=blockers[i].zw;
        // Illuminate the wall face itself and allow a source embedded in a wall.
        if (all(lessThan(abs(target),size+vec2(1.5))) || all(lessThan(abs(origin),size))) continue;
        vec2 ray=target-origin;
        if (abs(ray.x)<0.0001) ray.x=ray.x<0.0 ? -0.0001 : 0.0001;
        if (abs(ray.y)<0.0001) ray.y=ray.y<0.0 ? -0.0001 : 0.0001;
        vec2 a=(-size-origin)/ray;
        vec2 b=(size-origin)/ray;
        vec2 nearSide=min(a,b),farSide=max(a,b);
        float enter=max(nearSide.x,nearSide.y);
        float leave=min(farSide.x,farSide.y);
        if (max(enter,0.0)<min(leave,1.0)) return 0.06;
    }
    return 1.0;
}
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 pixel) {
    vec2 point=pixel*arenaSize/love_ScreenSize.xy;
    float distanceToLight=length(point-source.xy)/source.z;
    if (distanceToLight>=1.0) discard;
    float halo=1.0-smoothstep(0.0,1.0,distanceToLight);
    float core=exp(-distanceToLight*distanceToLight*32.0);
    float energy=(halo*halo*0.72+core*0.28)*source.w*visibility(point);
    return vec4(lightColor*energy,1.0);
}
