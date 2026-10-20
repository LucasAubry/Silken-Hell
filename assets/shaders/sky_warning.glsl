extern float clock;
extern float charge;
extern vec2 drift;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec2 q=(floor(uv*72.)+.5)/72.*2.-1.;
 float n=noise(q*4.+drift+clock*.12);
 float d=length(q*vec2(1.,1.04))+(n-.5)*.22;
 float shadow=1.-smoothstep(.61,.98,d);
 float billow=noise(q*8.-clock*.14+drift);
 vec3 grey=mix(vec3(.055,.075,.13),vec3(.24,.29,.36),billow*.6);
 float pulse=.5+.5*sin(clock*(8.+charge*9.));
 float edge=(1.-smoothstep(.022,.08,abs(d-.68)))*(.25+.75*smoothstep(.2,.8,charge))*(.6+.4*billow);
 vec3 ink=mix(grey,vec3(.42,.7,.95),edge*.8);
 return vec4(ink,min(1.,shadow*(.52+charge*.26)+edge*(.12+pulse*.18)));
}
