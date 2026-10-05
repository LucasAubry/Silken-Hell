-- PNG entrance phase: bosses are hidden and inert until their final frame has played.
local F={events={},seen={},known={},sheets={}}
local sizes={merle=290,wasp=370,hedgehog=310,octopus=460,storm=330,skeleton_fish=340,final_spider=290}
-- Each PNG contains 16 painted frames, laid out left-to-right in a 4x4 atlas.
function F.load()
 local g=love.graphics
 for kind in pairs(sizes) do
  if not F.sheets[kind] then
   local path='assets/effects/boss-arrivals/'..kind..'.png'
   local image=g.newImage(path,{mipmaps=false});image:setFilter('linear','linear')
   require('prism_material').register(image,path)
   local w,h=image:getDimensions();local cw,ch=w/4,h/4;local frames={}
   for i=0,15 do frames[i+1]=g.newQuad(i%4*cw,math.floor(i/4)*ch,cw,ch,w,h) end
   F.sheets[kind]={image=image,frames=frames,w=cw,h=ch}
   if Art.onLoad then Art.onLoad() end
  end
 end
end
function F.frame(event)
 return math.max(1,math.min(16,math.floor(event.age/event.duration*16)+1))
end
function F.clearSession() F.seen={};F.reset() end
function F.reset() if Replay and Replay.ghost then return end;F.events={};F.known={} end
local function position(b)
 local p=b.head or b.origin or b
 if not p.x and b.bees and b.bees[1] then p=b.bees[1] end
 return p.x or Arena.width*.5,p.y or 220
end
function F.observe(kind,b,key)
 if not b or not b.active or b.defeated or b.boss==false or F.known[b] then return end
 F.known[b]=true
 local id=tostring(Campaign.world)..':'..tostring(player.level)..':'..key
 local retry=F.seen[id];F.seen[id]=true
 local x,y=position(b)
 if kind=='skeleton_fish' then x=math.max(135,math.min(Arena.width-135,x));y=math.max(130,math.min(470,y)) end
 F.events[#F.events+1]={kind=kind,boss=b,name=b.name,x=x,y=y,age=0,duration=retry and .55 or 1.55,retry=retry}
end
function F.scan()
 if Replay and Replay.ghost then return end
 F.observe('merle',Raven,'merle');F.observe('wasp',Wasp,'wasp')
 F.observe('hedgehog',Hedgehog,'hedgehog');F.observe('octopus',Octopus,'octopus')
 F.observe('storm',Storm,'storm')
 if Abyss.boss then F.observe('skeleton_fish',Abyss,'abyss') end
 F.observe('final_spider',require('final_spider'),'queen')
 for i,item in ipairs(Bosses.items) do F.observe(item.kind,item.boss,'custom'..i..item.kind) end
end
function F.update(dt)
 if Replay and Replay.ghost then return end
 for i=#F.events,1,-1 do
  local e=F.events[i];e.age=e.age+dt
  if e.age>=e.duration or e.boss.defeated or not e.boss.active then table.remove(F.events,i) end
 end
 F.scan()
end
function F.waiting(boss)
 if Replay and (Replay.ghost or (Replay.playing and Replay.compatibility)) then return false end
 for _,e in ipairs(F.events) do
  if e.boss==boss and e.age<e.duration and boss.active and not boss.defeated then return true end
 end
 return false
end
function F.draw(over)
 if not Graphics.effects then return end
 local g=love.graphics;g.push('all');g.setShader();g.setBlendMode('alpha')
 for _,e in ipairs(F.events) do
  -- The abyss effect is emissive and must survive its darkness pass.
  if over==(e.kind=='skeleton_fish') then
   local sheet=assert(F.sheets[e.kind],'Boss arrival textures must be preloaded: '..e.kind)
   local t=e.age/e.duration
   local alpha=math.min(1,t/.055)*math.min(1,(1-t)/.15)
   local size=sizes[e.kind]*(e.retry and .7 or 1)
   g.setColor(1,1,1,alpha)
   g.draw(sheet.image,sheet.frames[F.frame(e)],e.x,e.y,0,size/sheet.w,size/sheet.h,sheet.w/2,sheet.h/2)
  end
 end
 g.pop()
end
return F
