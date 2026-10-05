-- Victory interlude. Keep the real actors on screen until their silk has snapped.
local L={events={},duration=1.95}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function L.busy() return not (Replay and Replay.ghost) and #L.events>0 end
function L.reset()
 if Replay and Replay.ghost then return end
 for _,e in ipairs(L.events) do e.boss.liberating=nil end
 L.events={}
end
function L.start(boss,kind,complete)
 if boss.liberating or boss.defeated then return end
 -- Compatibility playback follows the timing of the recorded, older game.
 if Replay and (Replay.ghost or Replay.playing and Replay.compatibility) then complete();return end
 boss.defeated=true;boss.liberating=true;boss.flash=0
 local e={boss=boss,kind=kind,complete=complete,age=0,threads={},width=Arena.width}
 local seen={}
 local function attach(actor,x,y,offset)
  if seen[actor] or not x or not y then return end
  seen[actor]=true
  x=clamp(x,28,Arena.width-28);y=clamp(y-(offset or 14),38,565)
  local i=#e.threads+1
  e.threads[i]={x=x,y=y,cut=math.max(18,y-45),snap=.82+(i-1)%7*.025,seed=i*2.399}
 end
 if kind=='storm' then
  boss.x=clamp(boss.x,90,Arena.width-90);boss.y=clamp(boss.y,120,500)
  boss.hidden=false;boss.phase='liberation';boss.previousDir=nil
 end
 if kind=='wasp' then
  for _,b in ipairs(boss.bees) do attach(b,b.x,b.y,27) end
 elseif kind=='skeleton_fish' then
  local p=boss.head or boss.origin;attach(boss,p and p.x,p and p.y,36)
 else
  attach(boss,boss.x,boss.y,({merle=64,storm=55,hedgehog=36,octopus=65,final_spider=25})[kind])
 end
 local function actors(list)
  for _,m in ipairs(list or {}) do
   if m.type~='piege' and m.type~='scie' and not m.ground and not m.dead then
    -- Captive burrowers come to the surface for their release.
    if m.type=='mole' then m.age=3 elseif m.type=='worm' then m.age=2 end
    attach(m,m.x,m.y,math.min(30,(m.hitBox_height or 36)*.45))
   end
  end
 end
 actors(mobs);actors(Realms.larvae)
 for _,key in ipairs({'minions','chicks','freedChicks','crabs','babies','corpses','octopuses'}) do actors(boss[key]) end
 -- Remove attack projectiles while preserving bodies and their existing PNGs.
 for _,key in ipairs({'projectiles','strikes','trails','eruptions','webs','threads','beam','beams','pressure','mines'}) do
  if boss[key] then
   if key=='beam' or key=='pressure' then boss[key]=nil else boss[key]={} end
  end
 end
 if kind=='octopus' then boss.blots={};boss.inkPools={};boss.tether=nil end
 objet.larme.taken=true
 L.events[#L.events+1]=e
end
function L.update(dt)
 if not L.busy() then return end
 objet.larme.taken=true
 for i=#L.events,1,-1 do
  local e=L.events[i];e.age=e.age+dt
  if e.age>=L.duration then
   table.remove(L.events,i);e.boss.liberating=nil;e.complete()
  end
 end
 if L.busy() then objet.larme.taken=true else Aftermath.update(0) end
end
local function strand(x,y,xx,yy,alpha,seed,time)
 local g=love.graphics;local dx,dy=xx-x,yy-y;local length=math.sqrt(dx*dx+dy*dy)
 if length<1 or alpha<=0 then return end
 g.setColor(.92,.91,.83,alpha)
 Art.draw('silk_strand',(x+xx)/2,(y+yy)/2,3.4,math.atan2(dy,dx)-math.pi/2,length)
 -- Two fine fibres keep the long PNG legible against both sky and darkness.
 g.setLineWidth(.65);g.setColor(1,.98,.9,alpha*.8)
 local points={}
 for j=0,8 do local t=j/8;local bend=math.sin(t*math.pi)*math.sin(seed+t*9+time*5)*1.3
  points[#points+1]=x+dx*t+bend;points[#points+1]=y+dy*t
 end
 g.line(points)
end
function L.draw()
 if not L.busy() then return end
 local g=love.graphics;local c=Worlds.color(Campaign.biome).tear
 g.push('all');g.setShader();g.setBlendMode('alpha');g.setScissor()
 for _,e in ipairs(L.events) do
  g.push();g.scale(Arena.width/e.width,1)
  for _,s in ipairs(e.threads) do
   local t=e.age;local broken=t-s.snap
   if broken<0 then
    local grow=clamp(t/.38,0,1);grow=1-(1-grow)^3
    strand(s.x,s.y*(1-grow),s.x,s.y,clamp(t/.15,0,1),s.seed,t)
    if Graphics.effects then
     local y=s.y*(1-clamp((t-.2)/.6,0,1))
     g.setBlendMode('add');g.setColor(.85,.83,.7,.35);g.circle('fill',s.x,y,2.5);g.setBlendMode('alpha')
    end
   else
    local p=clamp(broken/.7,0,1);local alpha=1-p
    strand(s.x,0,s.x+math.sin(p*9+s.seed)*10*p,s.cut*(1-p)^2,alpha,s.seed,t)
    local endY=s.cut+(s.y-s.cut)*math.sqrt(p)
    strand(s.x+math.sin(p*8+s.seed)*14*p,endY,s.x,s.y,alpha,s.seed,t)
    if Graphics.effects then
     g.setBlendMode('add')
     local flash=math.max(0,1-broken/.26)
     for ring=4,1,-1 do
      g.setColor(c[1],c[2],c[3],flash*.07);g.circle('fill',s.x,s.cut,ring*6)
     end
     g.setColor(1,.98,.85,flash);g.setLineWidth(1.2)
     g.line(s.x-11*flash,s.cut,s.x+11*flash,s.cut);g.line(s.x,s.cut-17*flash,s.x,s.cut+17*flash)
     for j=1,14 do
      local a=j*2.399+s.seed;local speed=22+(j%5)*13
      local x=s.x+math.cos(a)*speed*broken;local y=s.cut+math.sin(a)*speed*broken+broken*broken*25
      local life=math.max(0,1-broken/(.5+j%4*.12))
      g.setColor(.65+c[1]*.35,.65+c[2]*.35,.6+c[3]*.4,life*.85)
      g.circle('fill',x,y,j%3==0 and 1.5 or .85)
     end
     g.setBlendMode('alpha')
    end
   end
  end
  g.pop()
 end
 g.pop()
end
return L
