local C={}
function C.make(world)
 local g=love.graphics
 C.atlas=C.atlas or g.newImage('assets/icons/biome-backgrounds.png')
 C.spider=C.spider or g.newImage('assets/skins/soie/down.png');C.spider:setFilter('nearest','nearest')
 C.round=C.round or g.newShader([[
 vec4 effect(vec4 color,Image image,vec2 uv,vec2 px) {
  vec2 q=abs(uv-vec2(.5))-vec2(.32);
  float d=length(max(q,vec2(0)))+min(max(q.x,q.y),0.)-.18;
  vec4 p=Texel(image,uv)*color;p.a*=1.-smoothstep(-.002,.002,d);return p;
 }]])
 local canvas=g.newCanvas(512,512);local rounded=g.newCanvas(512,512)
 local old=g.getCanvas();g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.setShader();g.clear();g.setColor(1,1,1)
 local w,h=C.atlas:getDimensions();local tw,th=w/4,h/2;local tile=math.max(1,math.min(7,world))-1
 local quad=g.newQuad(tile%4*tw,math.floor(tile/4)*th,tw,th,w,h)
 g.draw(C.atlas,quad,0,0,0,512/tw,512/th)
 local sw,sh=C.spider:getDimensions();local scale=440/sw
 -- Use the unmodified in-game sprite at its original proportions.
 g.setColor(0,0,0,.42);g.draw(C.spider,256,279,0,scale*1.04,scale*1.04,sw/2,sh/2)
 g.setColor(1,1,1);g.draw(C.spider,256,267,0,scale,scale,sw/2,sh/2)
 g.setCanvas(rounded);g.clear();g.setShader(C.round);g.setBlendMode('alpha','premultiplied');g.draw(canvas)
 g.setCanvas(old);g.pop()
 local data=rounded:newImageData();canvas:release();rounded:release();quad:release();return data
end
return C
