extern vec2 dimensions;
extern Image shape;
extern float stage;
extern float jump;
vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
 vec2 texel=1./dimensions;
 if(stage<.5){
  float inside=step(.5,Texel(shape,uv).r);
  float boundary=0.;
  boundary+=abs(inside-step(.5,Texel(shape,uv+vec2(texel.x,0.)).r));
  boundary+=abs(inside-step(.5,Texel(shape,uv-vec2(texel.x,0.)).r));
  boundary+=abs(inside-step(.5,Texel(shape,uv+vec2(0.,texel.y)).r));
  boundary+=abs(inside-step(.5,Texel(shape,uv-vec2(0.,texel.y)).r));
  return vec4(uv,step(.5,boundary),1.);
 }
 vec4 best=Texel(image,uv);
 if(stage<1.5){
  float distance=best.b>.5 ? length((best.rg-uv)*dimensions) : 10000.;
  for(int y=-1;y<=1;y++){for(int x=-1;x<=1;x++){
   vec2 at=uv+vec2(float(x),float(y))*texel*jump;
   if(at.x>=0.&&at.x<=1.&&at.y>=0.&&at.y<=1.){
    vec4 candidate=Texel(image,at);
    float d=length((candidate.rg-uv)*dimensions);
    if(candidate.b>.5&&d<distance){best=candidate;distance=d;}
   }
  }}
  return best;
 }
 float distance=best.b>.5 ? length((best.rg-uv)*dimensions)+.5 : 64.;
 float sign=Texel(shape,uv).r>=.5 ? 1. : -1.;
 return vec4(clamp(.5+sign*distance/128.,0.,1.),0.,0.,1.);
}
