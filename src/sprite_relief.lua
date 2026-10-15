-- Shallow extrusion and a lit height field; source sprites and hitboxes stay intact.
local R={}
function R.bind(frame,earth,redEyes)
 local g=love.graphics
 R.shader=R.shader or g.newShader([[
 extern vec4 bounds;extern vec2 stepUV;extern vec2 lamp;extern float earth;extern float redEyes;
 vec4 sampleAt(Image tex,vec2 uv){
  if(any(lessThan(uv,bounds.xy))||any(greaterThan(uv,bounds.xy+bounds.zw)))return vec4(0.);
  return Texel(tex,uv);
 }
 float heightAt(Image tex,vec2 uv){vec4 p=sampleAt(tex,uv);return p.a*(.65+dot(p.rgb,vec3(.2126,.7152,.0722))*.35);}
 vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 px){
  vec4 p=sampleAt(tex,uv);
  vec2 slope=vec2(heightAt(tex,uv-vec2(stepUV.x,0.))-heightAt(tex,uv+vec2(stepUV.x,0.)),
                  heightAt(tex,uv-vec2(0.,stepUV.y))-heightAt(tex,uv+vec2(0.,stepUV.y)));
  vec3 normal=normalize(vec3(slope*2.5,1.));
  float lit=dot(normal,normalize(vec3(lamp,.9)));
  float luminance=dot(p.rgb,vec3(.299,.587,.114));
  float iris=smoothstep(.25,.45,p.g)*smoothstep(.15,.35,p.r-p.b)*(1.-smoothstep(.22,.4,p.b));
  p.rgb=mix(p.rgb,vec3(max(p.r,p.g),.015,.025),iris*redEyes);
  vec3 base=mix(p.rgb,mix(vec3(.075,.029,.009),vec3(.76,.47,.22),luminance),earth);
  vec2 at=(uv-bounds.xy)/bounds.zw;
  float dome=clamp(1.-length((at-vec2(.42,.38))*1.3),0.,1.);
  vec3 rgb=base*(.76+lit*.34+dome*.12)+vec3(.12,.10,.075)*pow(max(0.,lit),10.);
  return vec4(rgb,p.a)*tint;
 }]])
 local x,y,w,h=frame.quad:getViewport();local iw,ih=frame.image:getDimensions()
 R.shader:send('bounds',{x/iw,y/ih,w/iw,h/ih})
 R.shader:send('stepUV',{math.max(1,w/90)/iw,math.max(1,h/90)/ih})
 R.shader:send('lamp',R.lamp or {-.5,-.75});R.shader:send('earth',earth and 1 or 0);R.shader:send('redEyes',redEyes and 1 or 0)
 g.setShader(R.shader)
end
function R.draw(frame,x,y,width,angle,height,depth,earth,pose,redEyes)
 local g=love.graphics;angle=angle or 0;height=height or width*frame.h/frame.w
 depth=depth or math.max(2,math.min(6,width*.065))
 local sx,sy=width/frame.w,height/frame.h
 local function paint(xx,yy)
  if pose then pose(xx,yy)
  else g.draw(frame.image,frame.quad,xx,yy,angle,sx,sy,frame.w/2,frame.h/2) end
 end
 local r,gg,b,a=g.getColor()
 g.push('all')
 R.silhouette=R.silhouette or g.newShader([[vec4 effect(vec4 c,Image t,vec2 uv,vec2 p){return vec4(c.rgb,Texel(t,uv).a*c.a);}]])
 g.setShader(R.silhouette)
 g.setColor(.015,.012,.012,a*.26);paint(x+depth*.8,y+depth+3)
 for i=math.ceil(depth),1,-1 do
  local light=.10+(1-i/depth)*.07
  g.setColor(light,light*.82,light*.68,a)
  paint(x+i*.25,y+i)
 end
 -- Counter-rotate the light so spinning blades keep a stable world light.
 R.lamp={-.5*math.cos(angle)-.75*math.sin(angle),.5*math.sin(angle)-.75*math.cos(angle)}
 R.bind(frame,earth,redEyes);R.lamp=nil;g.setColor(r,gg,b,a)
 paint(x,y)
 g.pop()
end
return R
