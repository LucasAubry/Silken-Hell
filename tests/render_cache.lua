local T={}
-- Frozen reference from bd93baa: the optimisation must retain its light output.
local originalAtmosphere=[=[
extern number clock;
extern number biome;
extern number transmission;
extern number levelSeed;
extern number depth;
extern vec2 dimensions;
extern vec3 lightTint;
extern vec4 localLights[8];
vec4 effect(vec4 color,Image texture,vec2 uv,vec2 pixel) {
    pixel *= dimensions.y/love_ScreenSize.y;
    vec2 p=pixel/dimensions;
    float shafts=0.0;
    float patches=0.0;
    for(int i=0;i<4;i++) {
        float k=float(i);
        float origin=.04+k*.26+sin(levelSeed+k*2.7)*.055;
        float center=origin+p.y*.16+sin(clock*.12+k*2.0)*.012;
        float width=.019+p.y*.055;
        float ray=exp(-pow((p.x-center)/width,2.0));
        float ribs=.76+.24*sin(p.x*290.0-p.y*38.0+k+clock*.16);
        shafts+=ray*ribs*(.85-p.y*.36);
        vec2 site=vec2(origin+.07,.22+fract(sin(levelSeed+k*13.0)*137.0)*.6);
        vec2 delta=(p-site)*vec2(dimensions.x/dimensions.y,1.0);
        patches+=exp(-dot(delta,delta)*(biome==5.0?70.0:24.0));
    }
    float local=0.0;
    for(int i=0;i<8;i++) {
        float d=length(pixel-localLights[i].xy)/max(1.0,localLights[i].z);
        local+=max(0.0,1.0-d)*max(0.0,1.0-d)*localLights[i].w;
    }
    float rays=shafts*transmission;
    float haze=.5+.5*sin(p.x*12.0+sin(p.y*8.0+clock*.13)+clock*.09);
    patches+=haze*.055;
    if(biome==1.0 || biome==6.0) rays*=1.12;

    if(biome==4.0) rays*=1.35;
    if(biome==5.0) { rays*=.55;patches=haze*.035; } // Narrow overhead shafts; keep the surrounding earth dark.
    if(biome==2.0) rays=patches*.18; // Ember light rises from the floor in Hell.
    float lit=clamp(rays*.7+patches*(biome==5.0?.95:.35)*transmission+local,0.0,1.0);
    float shade=biome==5.0?.20:biome==4.0?.12:biome==2.0?.22:.13;
    shade+=(1.0-transmission)*.16+depth*.045;
    float edge=length((p-.5)*vec2(1.0,.8));
    shade+=smoothstep(.3,.7,edge)*.09;
    float caustic=0.0;
    if(biome==4.0) {
        float wave=sin(p.x*59.0+p.y*26.0+sin(p.y*39.0-clock*.6)*1.8+clock*.4);
        caustic=pow(abs(wave),24.0)*patches*.07;
    }
    vec3 shadow=biome==4.0?vec3(.0,.025,.07):vec3(.017,.009,.02);
    float blend=smoothstep(.03,biome==5.0?.5:.8,lit);
    vec3 tint=mix(shadow,lightTint,blend);
    float alpha=mix(shade,.19,blend)+caustic;
    return vec4(tint,alpha)*color;
}
]=]

local function compare(expected,actual,label)
 local w,h=expected:getDimensions();local aw,ah=actual:getDimensions()
 assert(w==aw and h==ah,label..': dimensions changed')
 local maximum=0
 for y=0,h-1 do for x=0,w-1 do
  local r,g,b,a=expected:getPixel(x,y);local nr,ng,nb,na=actual:getPixel(x,y)
  local delta=math.max(math.abs(r-nr),math.abs(g-ng),math.abs(b-nb),math.abs(a-na))
  if delta>maximum then maximum=delta end
  assert(delta<=1/255+.00001,string.format('%s changed at %d,%d by %.6f',label,x,y,delta))
 end end
 expected:release();actual:release()
 return maximum
end

function T.run()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 local g=love.graphics;local B=BiomeFloor;local material=require('prism_material')
 local enabled=material.enabled;material.enabled=false
 local quality=Graphics.quality;Graphics.quality=2
 local oldCanvas=g.getCanvas();g.push('all');g.origin();g.setScissor();g.setShader();g.setColor(1,1,1)
 local function drawFloor(target,width,height,time,world)
  g.setCanvas(target);g.origin();g.setScissor();g.setShader();g.setBlendMode('alpha');g.setColor(1,1,1)
  B.draw(world or 1,width,height,time)
  return B.cache
 end
 local floorError=0
 for _,density in ipairs({1,2}) do
  local width,height=480,300
  local target=g.newCanvas(width,height,{dpiscale=density})
  for _,time in ipairs({0,.517,3,25}) do
   local cache=drawFloor(target,width,height,time)
   assert(cache.h==height*density,'Paradise must keep native display density')
   assert(cache.tick==math.floor(time*Graphics.backgroundHz()),'Background cadence changed')
   if B.paradiseSupported then assert(cache.paradise and cache.paradise:getFormat()=='rgba16f','Missing high precision static floor') end
   local raw=g.newCanvas(cache.w,cache.h)
   g.setCanvas(raw);g.origin();g.setBlendMode('alpha');g.clear();g.setColor(1,1,1)
   B.shader:send('biome',1);B.shader:send('clock',cache.tick/Graphics.backgroundHz())
   B.shader:send('dimensions',{cache.w,cache.h});g.setShader(B.shader);g.rectangle('fill',0,0,cache.w,cache.h);g.setShader()
   g.setCanvas(target)
   floorError=math.max(floorError,compare(raw:newImageData(),cache.canvas:newImageData(),'Paradise density '..density..' time '..time))
   raw:release()
  end
  g.setCanvas(oldCanvas);target:release()
 end
 -- Two aspect ratios remain resident, including their static marble resources.
 local firstTarget=g.newCanvas(480,300);local secondTarget=g.newCanvas(640,300)
 local first=drawFloor(firstTarget,480,300,1)
 local second=drawFloor(secondTarget,640,300,1)
 local image,shader,canvas=g.newImage,g.newShader,g.newCanvas
 local uploads,compiles,allocations=0,0,0
 g.newImage=function(...)uploads=uploads+1;return image(...)end
 g.newShader=function(...)compiles=compiles+1;return shader(...)end
 g.newCanvas=function(...)allocations=allocations+1;return canvas(...)end
 for i=1,24 do
  assert(drawFloor(firstTarget,480,300,i/120)==first,'First aspect ratio evicted unnecessarily')
  assert(drawFloor(secondTarget,640,300,i/120)==second,'Second aspect ratio evicted unnecessarily')
 end
 g.newImage=image;g.newShader=shader;g.newCanvas=canvas
 assert(uploads==0 and compiles==0 and allocations==0,'Warm rendering must not upload, compile or allocate')
 assert(#B.surfaces==2,'Floor resources must remain bounded to two dimensions')
 drawFloor(firstTarget,480,300,10)
 local pixels=first.canvas:newImageData()
 drawFloor(firstTarget,480,300,10+1/240)
 assert(compare(pixels,first.canvas:newImageData(),'Same background tick')==0,'Sub-tick rendering must reuse the floor')
 local thirdTarget=g.newCanvas(800,300)
 drawFloor(thirdTarget,800,300,10)
 assert(#B.surfaces==2,'Eviction exceeded the two-surface limit')
 assert(not pcall(function()return second.canvas:getWidth()end),'Evicted floor GPU surface was not released')
 if second.paradise then assert(not pcall(function()return second.paradise:getWidth()end),'Evicted marble GPU surface was not released') end
 -- Cached marble must survive other biome renders on the same dimensions.
 drawFloor(firstTarget,480,300,3)
 local cave=drawFloor(firstTarget,480,300,3,5)
 local cavePixels=cave.canvas:newImageData()
 drawFloor(firstTarget,480,300,50,5)
 assert(compare(cavePixels,cave.canvas:newImageData(),'Static cave')==0,'Static cave unexpectedly animated')
 local resumed=drawFloor(firstTarget,480,300,3)
 assert(resumed.world==1 and resumed.tick==180,'Biome return did not invalidate the final floor')
 g.setCanvas(oldCanvas);firstTarget:release();secondTarget:release();thirdTarget:release()

 local legacy=g.newShader(originalAtmosphere);local optimised=g.newShader('assets/shaders/atmosphere.glsl')
 local atmosphereError=0
 local lightCases={{world=1,count=0},{world=2,count=0},{world=2,count=8},{world=4,count=3},
  {world=5,count=0},{world=5,count=8},{world=6,count=0},{world=6,count=8}}
 local function atmosphere(shader,world,count,density)
  local target=g.newCanvas(320,200,{dpiscale=density})
  g.setCanvas(target);g.origin();g.setScissor();g.setBlendMode('replace','premultiplied');g.clear();g.setColor(1,1,1)
  local settings=Atmosphere.settings(world,8);local lights={}
  for i=1,8 do lights[i]=i<=count and {73+i*89,43+i*59,40+i*13,.35+i*.06} or {0,0,1,0} end
  shader:send('clock',3.25);shader:send('biome',world);shader:send('transmission',settings.transmission)
  shader:send('levelSeed',settings.seed);shader:send('depth',settings.depth);shader:send('dimensions',{960,600})
  shader:send('lightTint',{.64,.82,1});shader:send('localLights',unpack(lights))
  g.setShader(shader);g.rectangle('fill',0,0,320,200);g.setShader()
  g.setCanvas(oldCanvas);local data=target:newImageData();target:release()
  return data
 end
 for _,case in ipairs(lightCases) do
  for _,density in ipairs({1,2}) do
   atmosphereError=math.max(atmosphereError,compare(atmosphere(legacy,case.world,case.count,density),
    atmosphere(optimised,case.world,case.count,density),'Atmosphere '..case.world..' lights '..case.count..' density '..density))
  end
 end
 legacy:release();optimised:release();g.setCanvas(oldCanvas);g.pop()
 Graphics.quality=quality;material.enabled=enabled
 print(string.format('PASS render cache: same native resolution/cadence; floor max error %.6f, atmosphere %.6f; no warm uploads/compiles/allocations; two bounded caches, GPU resources released, static cave unchanged',floorError,atmosphereError))
 love.event.quit()
end
return T

