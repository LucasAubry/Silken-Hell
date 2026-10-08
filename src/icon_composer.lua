-- Both desktop apps share the same frame, silhouette, size and skin shader.
local C={spiderSize=384}
local function sprite()
 if not C.spider then
  local art=require('art');art.add('app_icon_spider','assets/skins/commun/down.png')
  C.spider=art.images.app_icon_spider
 end
 return C.spider
end
function C.drawSpider(x,y,size)
 local g=love.graphics;local a=sprite();local scale=size/math.max(a.w,a.h)
 C.skin=C.skin or g.newShader('assets/shaders/player_skin.glsl')
 C.skin:send('bodyColor',{.61,.33,.14});C.skin:send('sideView',false);C.skin:send('frontView',true)
 C.skin:send('brownSkin',true);C.skin:send('locked',false)
 g.push('all');g.setShader(C.skin);g.setColor(1,1,1)
 g.draw(a.image,a.quad,x,y,0,scale,scale,a.w/2,a.h/2);g.pop()
end
local function editorBackground()
 local g=love.graphics
 g.setColor(.018,.065,.115);g.rectangle('fill',0,0,512,512)
 for i=16,1,-1 do g.setColor(.035,.22,.35,.025);g.ellipse('fill',256,235,45+i*17,30+i*17) end
 g.setLineWidth(1);g.setColor(.18,.67,.85,.22)
 for n=0,16 do local p=32+n*28;g.line(p,32,p,480);g.line(32,p,480,p) end
 for _,p in ipairs({{75,140,86},{349,137,84},{75,401,95}}) do
  g.setColor(.04,.26,.39);g.rectangle('fill',p[1],p[2],p[3],14)
  g.setColor(.29,.81,.92,.85);g.setLineWidth(3);g.line(p[1],p[2]+14,p[1],p[2],p[1]+p[3],p[2],p[1]+p[3],p[2]+14)
 end
 g.setColor(.23,.8,.95,.65);g.setLineWidth(2)
 for _,p in ipairs({{120,90},{380,90},{230,428}}) do g.line(p[1]-5,p[2],p[1]+5,p[2]);g.line(p[1],p[2]-5,p[1],p[2]+5) end
end
local function pencil()
 local g=love.graphics;g.push('all');g.translate(393,370);g.rotate(math.pi/4)
 local outline={-21,-91,21,-91,21,44,0,88,-21,44}
 g.setColor(.12,.8,1,.3);g.setLineWidth(9);g.polygon('line',outline)
 g.setColor(.025,.035,.055);g.polygon('fill',outline)
 g.setColor(.99,.62,.08);g.rectangle('fill',-16,-43,32,83)
 g.setColor(1,.83,.34);g.rectangle('fill',-12,-43,10,83)
 g.setColor(.77,.35,.04);g.rectangle('fill',9,-43,7,83)
 g.setColor(.96,.31,.11);g.rectangle('fill',-16,-86,32,27,4)
 g.setColor(1,.55,.23);g.rectangle('fill',-12,-82,9,19,2)
 g.setColor(.61,.69,.75);g.rectangle('fill',-16,-59,32,16)
 g.setColor(.92,.94,.95);g.rectangle('fill',-12,-56,9,10)
 g.setColor(.90,.70,.42);g.polygon('fill',-16,40,16,40,0,77)
 g.setColor(1,.86,.57);g.polygon('fill',-16,40,-2,40,0,77)
 g.setColor(.045,.055,.065);g.polygon('fill',-5,65,5,65,0,79)
 g.pop()
end
function C.make(world,editor,size)
 local g=love.graphics;size=size or 512
 C.atlas=C.atlas or require('art_filter').image('assets/icons/biome-backgrounds.png')
 C.round=C.round or g.newShader([[
 vec4 effect(vec4 color,Image image,vec2 uv,vec2 px) {
  vec2 q=abs(uv-vec2(.5))-vec2(.2875);
  float d=length(max(q,vec2(0)))+min(max(q.x,q.y),0.)-.15;
  float coverage=1.-smoothstep(-.001,.001,d);
  vec4 p=Texel(image,uv)*color;return vec4(coverage>0. ? p.rgb : vec3(0.),p.a*coverage);
 }]])
 local canvas=g.newCanvas(size,size);local rounded=g.newCanvas(size,size)
 local old=g.getCanvas();g.push('all');g.setCanvas(canvas);g.origin();g.scale(size/512);g.setScissor();g.setShader();g.setBlendMode('alpha');g.clear(.015,.03,.05,1);g.setColor(1,1,1)
 if editor then editorBackground() else
  local w,h=C.atlas:getDimensions();local tw,th=w/4,h/2;local tile=math.max(1,math.min(7,world or 1))-1
  local quad=g.newQuad(tile%4*tw,math.floor(tile/4)*th,tw,th,w,h)
  g.draw(C.atlas,quad,32,32,0,448/tw,448/th);quad:release()
 end
 local a=sprite();local scale=C.spiderSize/math.max(a.w,a.h)
 g.setColor(0,0,0,.45);g.draw(a.image,a.quad,256,272,0,scale*1.035,scale*1.035,a.w/2,a.h/2)
 C.drawSpider(256,260,C.spiderSize)
 if editor then pencil() end
 g.setColor(editor and {.3,.82,1,.7} or {1,.92,.7,.45});g.setLineWidth(2)
 g.rectangle('line',33,33,446,446,76,76)
 g.setCanvas(rounded);g.origin();g.clear();g.setColor(1,1,1);g.setShader(C.round);g.setBlendMode('replace');g.draw(canvas)
 g.setCanvas(old);g.pop()
 local data=rounded:newImageData();canvas:release();rounded:release();return data
end
return C
