extern vec2 origin;
extern vec2 floorSize;
extern Image cloudFloor;
extern number reach;
extern number fade;
extern number seed;
extern number age;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
 vec2 world=uv*floorSize;
 float cloud=noise(world*.027+seed);
 vec2 p=world-origin+vec2(cloud-.5,noise(world*.032+19.)-.5)*18.;
 float d=10000.;
 for(int i=0;i<3;i++) {
  float k=float(i),a=seed*.77+k*2.1+sin(seed+k*3.)*.35;
  vec2 direction=vec2(cos(a),sin(a));
  float along=dot(p,direction),side=dot(p,vec2(-direction.y,direction.x));
  float bend=sin(along*.022+k*2.+seed)*13.+sin(along*.057+k)*5.;
  float branch=max(0.,along-90.-k*19.);
  float cross=abs(side-bend);
  if(i==1) cross=min(cross,abs(side-bend-branch*.32));
  float endcap=max(max(-along,along-reach),0.);
  d=min(d,length(vec2(cross,endcap)));
 }
 // Broad, irregular scattering through the cloud material, without a drawn core.
 float density=dot(Texel(cloudFloor,uv).rgb,vec3(.299,.587,.114));
 float width=mix(65.,230.,cloud);
 float scattered=exp(-d*d/width)*.19+exp(-d*d/(width*3.))* .085;
 float transmission=mix(.55,1.15,smoothstep(.35,.8,density));
 float billow=.72+.28*sin(cloud*9.+density*13.+age*5.+seed);
 return vec4(vec3(1.,.81,.29)*scattered*transmission*billow*fade,1.)*color;
}
