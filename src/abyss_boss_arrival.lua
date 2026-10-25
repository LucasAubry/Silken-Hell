-- Three authored arenas form one continuous travelling shot. All actors here
-- are visual proxies: their motion never changes the recorded boss encounter.
local B={lead=6.85,duration=10,impact=5.2,noScreenParticles=true}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
local function copy(value)
 if type(value)~='table' then return value end
 local out={};for k,v in pairs(value) do out[k]=copy(v) end;return out
end
function B.prepare()
 local json=require('json')
 local ok,data=pcall(json.decode,love.filesystem.read('custom_levels.json') or '{}')
 local authored=ok and require('abyss_sequence').migrate(data).levels or {}
 local layouts=LevelLayouts.read() or {};B.maps={};B.width=Arena.width
 for level=7,9 do
  local layout=copy(layouts['7:'..level] or authored and authored['7:'..level] or {width=960,entities={}})
  local ratio=B.width/(layout.width or 960)
  for _,e in ipairs(layout.entities) do e.x=e.x*ratio end
  layout.width=B.width;B.maps[level]=layout
 end
 local gate,tear
 for _,e in ipairs(B.maps[9].entities) do
  if e.kind=='abyss_gate' then gate=e elseif e.kind=='tear' and not tear then tear=e end
 end
 B.gate=gate or {x=105,y=300,w=math.min(540,B.width*.58),h=648}
 B.tear=tear or {x=B.gate.x+B.gate.w*.18,y=B.gate.y+50}
 B.tailLeft=B.width
 for _,e in ipairs(B.maps[8].entities) do
  if e.kind=='abyss_part' then B.tailLeft=math.min(B.tailLeft,B.width+e.x-(e.w or 100)/2) end
 end
 B.travel=3*B.width+100-B.tailLeft
 B.actor={walkMoving=false}
end
function B.current()
 local a=require('mobs.bosses.abyss.arrival').current
 if not (a and a.arrival and a.arrival.cinematic) then return end
 B.age=a.arrival.elapsed;return B
end
function B.pose(t)
 local width=B.width or Arena.width
 local departure=ease((t-5.4)/3.75)
 return {camera=2*width*ease((t-.15)/4.5),closed=t>=B.impact,
  swallow=ease((t-4.15)/.95),departure=departure,offset=(B.travel or width*2.3)*departure,
  wake=ease((t-5.4)/.45)}
end
local function bounce(x,limit)
 local u=(x-32)%(2*(limit-64));return 32+(u<limit-64 and u or 2*(limit-64)-u)
end
function B.mobPose(e,index,t,width)
 local theta=index*2.399;local speed=(e.speed or 50)*(e.type=='light_jelly' and .65 or .48)
 local dx,dy=math.cos(theta)*speed,math.sin(theta)*speed
 local x=bounce(e.x+dx*t,width);local y=bounce(e.y+dy*t,600)
 local nx=bounce(e.x+dx*(t+.02),width);local ny=bounce(e.y+dy*(t+.02),600)
 return {type=e.type,x=x,y=y,age=t+index*.37,angle=math.atan2(ny-y,nx-x),dir=Art.direction(nx-x,ny-y,'right')}
end
local function bone(e,offset,t,p)
 local wave=math.sin((t-5.4)*4.8-e.x*.006)*p.wake*7
 love.graphics.setColor(.62,.73,.80)
 Art.draw(e.type,e.x+offset,e.y+wave,e.w or 100,(e.rotation or 0)*math.pi/180,e.h or 100)
end
local function head(t,p)
 local g=love.graphics;local gate=B.gate
 local key=p.closed and 'skeleton_head' or 'skeleton_open'
 local spot=Art.images[key].glow or {u=.5,v=.5}
 local openSpot=Art.images.skeleton_open.glow or {u=.5,v=.5}
 -- Identical size and eye-aligned jaw closure to the playable level-nine gate.
 local x=gate.x+p.offset+gate.w*(openSpot.u-spot.u)
 local y=gate.y+gate.h*(openSpot.v-spot.v)
 g.setColor(.63,.73,.79);Art.draw(key,x,y,gate.w,0,gate.h)
 local ex,ey=x+gate.w*(spot.u-.5),y+gate.h*(spot.v-.5)
 g.setColor(.003,.008,.014,.95);g.ellipse('fill',ex,ey,gate.w*.025,gate.h*.027)
 B.eye={x=2*B.width+ex-p.camera,y=ey,r=gate.w*.025}
 if not p.closed then
  local tx,ty=B.tear.x,B.tear.y
  require('tear_fx').draw(tx,ty,Worlds.color(7).tear,t)
  local px=tx+225*(1-p.swallow);local py=ty-38*(1-p.swallow)
  B.actor.walkMoving=p.swallow>0 and p.swallow<1;B.actor.walkPhase=t*8
  g.setColor(1,1,1);Characters.draw(px,py,Characters.playerWidth,'left',B.actor,7)
  local bubble=require('breathing_bubble');local hx,hy,r=bubble.headPosition(px,py,Characters.playerWidth,'left')
  if not require('integrated_skins').bubble(Characters.selected()) then bubble.drawAt(hx,hy,r,t,false,nil,nil,1,'left') end
  bubble.drawLantern(hx,hy,r,t,nil,1,'left')
  B.lights[#B.lights+1]={2*B.width+px-p.camera,py,125}
 end
end
local function lighting()
 B.shader=B.shader or love.graphics.newShader([[
  extern vec2 dimensions;extern vec3 lights[16];extern int lightCount;
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel){
   vec4 texel=Texel(image,uv);vec2 p=uv*dimensions;float light=.12;
   for(int i=0;i<16;i++){
    if(i>=lightCount)break;
    float d=length((p-lights[i].xy)/lights[i].z);
    light=max(light,.12+.69*exp(-d*d*2.4));
   }
   float edge=smoothstep(.0,.12,uv.y)*(1.-smoothstep(.88,1.,uv.y));
   return vec4(texel.rgb*vec3(.76,.88,1.)*light*(.68+.32*edge),texel.a)*color;
  }
 ]])
 return B.shader
end
function B.draw(canvas,w,h)
 if not B.maps or B.width~=Arena.width then B.prepare() end
 local g=love.graphics;local t=B.age or 0;local p=B.pose(t);local width=B.width
 local scale,x,y=App.viewport(w,h)
 g.push('all');g.origin();g.setShader()
 do
  if not B.layer or B.layer:getWidth()~=width then
   if B.layer then B.layer:release() end
   B.layer=g.newCanvas(width,600,{dpiscale=1})
  end
  local target=g.getCanvas();g.setCanvas(B.layer);g.clear(.001,.004,.012);g.origin()
  B.lights={};local candidates={}
  for level=7,9 do
   local origin=(level-7)*width
   g.push();g.translate(origin-p.camera,0)
   -- No separating walls: the three real layouts share a continuous sea floor.
   require('biome_floor').draw(7,width,600,t)
   for i,e in ipairs(B.maps[level].entities) do
    if e.kind=='mob' and (e.type=='lanternfish' or e.type=='abyss_fish' or e.type=='light_jelly') then
     local m=B.mobPose(e,i,t,width);MobBehaviors[e.type].draw(m)
     if e.type=='lanternfish' or e.type=='light_jelly' then
      local lx=origin+m.x-p.camera
      if lx>-120 and lx<width+120 then candidates[#candidates+1]={lx,m.y,e.type=='lanternfish' and 110 or 88} end
     end
    elseif e.kind=='tear' and level~=9 then require('tear_fx').draw(e.x,e.y,Worlds.color(7).tear,t)
    elseif e.kind=='wall' then
     g.setColor(.15,.23,.28);g.rectangle('fill',e.x-(e.w or 40)/2,e.y-(e.h or 40)/2,e.w or 40,e.h or 40)
    end
   end
   g.pop()
  end
  local function clipArena(level)
   local left=math.max(0,(level-7)*width-p.camera)
   local right=math.min(width,(level-6)*width-p.camera)
   g.setScissor(left,0,math.max(0,right-left),600)
  end
  -- Keep the original cropped edges while travelling; release the moving body
  -- from its old arena bounds once it swims across the level-nine map.
  for level=7,8 do
   g.push();g.translate((level-7)*width-p.camera,0)
   if level==7 or p.offset==0 then clipArena(level) end
   for _,e in ipairs(B.maps[level].entities) do
    if e.kind=='abyss_part' then bone(e,level==8 and p.offset or 0,t,level==8 and p or {wake=0}) end
   end
   g.setScissor();g.pop()
  end
  g.push();g.translate(2*width-p.camera,0)
  if p.offset==0 then clipArena(9) end
  head(t,p);g.setScissor();g.pop()
  for _,l in ipairs(candidates) do if #B.lights<16 then B.lights[#B.lights+1]=l end end
  -- Sparse nearby plankton reveals the movement without exposing the whole body.
  for i=1,95 do
   local px=(i*97.3-t*12-p.camera*.8)%width;local py=(i*71.7-t*(5+i%3))%600
   g.setColor(.18,.45,.60,.24);g.circle('fill',px,py,.7+i%2*.45)
  end
  g.setCanvas(target);g.origin()
  local shader=lighting();shader:send('dimensions',{width,600});shader:send('lightCount',#B.lights)
  local lights={};for i=1,16 do lights[i]=B.lights[i] or {-1000,-1000,1} end
  shader:send('lights',unpack(lights));g.setShader(shader);g.setColor(1,1,1);g.draw(B.layer,x,y,0,scale,scale);g.setShader()
  -- Emissive eyes remain readable through the deep-sea shade.
  g.push('all');g.translate(x,y);g.scale(scale);g.setBlendMode('add')
  local eye=B.eye;local bite=ease((t-B.impact)/.16)
  if eye then
   for i=8,1,-1 do
    g.setColor(.28+.72*bite,.45*(1-bite),.65*(1-bite),.035)
    g.ellipse('fill',eye.x,eye.y,eye.r*(1+i*.36),eye.r*(1+i*.36)*1.25)
   end
   g.setColor(1,.5*(1-bite),.65*(1-bite),.65+.35*bite)
   g.ellipse('fill',eye.x,eye.y,eye.r*.38,eye.r*.65)
  end

  g.pop()
  g.setColor(.001,.003,.008,1-ease(t/.2));g.rectangle('fill',0,0,w,h)
 end
 g.setColor(0,0,0,ease((t-8.7)/.65));g.rectangle('fill',0,0,w,h)
 -- Hold black after the full body leaves the shot. The real arrival
 -- finishes behind this shot, so its player-spitting animation stays hidden.
 g.pop()
end
return B
