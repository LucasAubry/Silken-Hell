float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 px) {
 vec2 p=uv*2.0-1.0;
 float angle=atan(p.y,p.x),r=length(p);
 float edge=.85+.045*sin(angle*5.0+.6)+.035*sin(angle*9.0)+(noise(p*23.0)-.5)*.05;
 float alpha=1.0-smoothstep(edge-.09,edge+.025,r);
 float irregular=.035*sin(angle*5.0+.8)+.022*sin(angle*8.0);
 float d=length(p-vec2(0.0,.035))-irregular;
 float ridge=exp(-pow((d-.71)/.12,2.0));
 float light=clamp(.52+dot(normalize(p+vec2(.001)),vec2(-.24,-.40)),0.0,1.0);
 vec3 earth=mix(vec3(.22,.135,.070),vec3(.43,.285,.16),light);
 vec3 c=mix(vec3(.14,.085,.045),earth,ridge);
 // Matte clods and sediment match the underground floor, without a smooth ring.
 float clods=noise(p*19.0)*.65+noise(p*39.0)*.35;
 c*=.76+clods*.45;
 c+=vec3(.09,.065,.035)*pow(noise(p*70.0),6.0)*ridge;
 float seam=pow(abs(sin(angle*19.0+noise(p*9.0)*7.0)),18.0);
 c*=1.0-seam*ridge*.20;
 // A recessed floor sits below the mouth, leaving a visible cut of soil.
 // The offset and shrinking contour give the shaft depth even at small sizes.
 float opening=1.0-smoothstep(.575,.605,d);
 float bottom=length((p-vec2(.015,.16))*vec2(1.0,1.08))-irregular*.55;
 float depth=clamp((bottom-.27)/.39,0.0,1.0);
 float wallLight=clamp(.58-p.x*.32-p.y*.35,.18,.92);
 vec3 wall=mix(vec3(.045,.022,.011),vec3(.35,.205,.105),depth*wallLight);
 float strata=sin(bottom*68.0+noise(p*12.0)*3.0)*.5+.5;
 wall*=.80+strata*.20;
 wall+=vec3(.035,.023,.011)*(noise(p*38.0)-.5)*depth;
 // The upper lip overhangs the wall; its shadow falls into the opening.
 float overhang=exp(-pow((d-.545)/.045,2.0))*(1.0-smoothstep(-.15,.30,p.y));
 wall*=1.0-overhang*.65;
 float floorMask=1.0-smoothstep(.265,.35,bottom);
 vec3 floorColor=mix(vec3(.009,.005,.003),vec3(.027,.013,.006),smoothstep(.08,.34,bottom));
 vec3 hollow=mix(wall,floorColor,floorMask);
 c=mix(c,hollow,opening);
 return vec4(c,alpha)*tint;
}
