// Steel-blue backs, silver scales and slate fins; preserve teeth and dark outlines.
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec4 t=Texel(tex,uv);
 float hi=max(t.r,max(t.g,t.b)),lo=min(t.r,min(t.g,t.b));
 float chroma=smoothstep(.045,.16,hi-lo);
 float value=dot(t.rgb,vec3(.299,.587,.114));
 vec3 silver=mix(vec3(.045,.075,.11),vec3(.78,.86,.88),pow(value,.85));
 return vec4(mix(t.rgb,silver,chroma),t.a)*color;
}
