extern float radius;
extern float startAngle;
extern float arc;
extern float thickness;
extern float size;
vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
 vec2 p=(uv-.5)*size;
 float angle=mod(atan(p.y,p.x)-startAngle+12.5663706144,6.2831853072);
 float distance=abs(length(p)-radius);
 if(arc<6.2831853072 && angle>arc){
  vec2 a=vec2(cos(startAngle),sin(startAngle))*radius;
  vec2 b=vec2(cos(startAngle+arc),sin(startAngle+arc))*radius;
  distance=min(length(p-a),length(p-b));
 }
 return vec4(clamp(.5+(thickness-distance)/128.,0.,1.),0.,0.,1.);
}
