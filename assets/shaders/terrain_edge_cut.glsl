extern Image cutMask;
extern bool edgeConnectionsOnly;
extern vec2 mapSize;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec4 edge=Texel(tex,uv)*color;
 float cut=Texel(cutMask,uv).a;
 if(edgeConnectionsOnly){
  // Keep the perimeter in front of nearby holes. A cut is allowed only where
  // the same opening reaches the outside along the nearest side of the map.
  vec2 p=uv*mapSize,side=min(p,mapSize-p);
  vec2 exitUV=side.x<side.y?vec2(uv.x<.5?0.:1.,uv.y):vec2(uv.x,uv.y<.5?0.:1.);
  cut*=Texel(cutMask,exitUV).a;
 }
 edge*=1.-cut;
 return edge;
}
