-- The three sisters rise from the same arena in which the fight will begin.
-- Visual actors use no gameplay state or random-number draws.
local B={duration=8.5,impact=5.3}
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function B.reset(options)
 B.active=false;B.age=0;B.bees={};require('boss_arrival_backdrop').clear(B)
 if Campaign.world~=2 or player.level~=10 or options and options.retry or App.sessionLayout or App.workshopMap or Secret.duel then return end
 if not App.historyPreview and (App.preview or App.practice or App.singleLevel or App.hardcore) then return end
 local boss=Wasp.active and Wasp or nil
 for _,item in ipairs(Bosses.items) do if item.kind=='wasp' then boss=item.boss;break end end
 if not boss then return end
 B.boss=boss;boss.syncAnchor()
 for i,bee in ipairs(boss.bees) do B.bees[i]={x=bee.x,y=bee.y,id=i} end
 B.active=true
end
function B.current()return B.active and B or nil end
function B.update(dt)
 if not B.active then return false end
 B.age=B.age+dt
 if B.age>=B.duration then
  B.active=false
  if not (App.historyPreview or Replay.playing or Replay.ghost or App.preview or App.practice or App.singleLevel or App.hardcore or App.sessionLayout) then
   Profile.transitionsSeen=Profile.transitionsSeen or {}
   if not Profile.transitionsSeen.boss_hell then Profile.transitionsSeen.boss_hell=true;Profile.save() end
  end
 end
 return true
end
function B.pose(i,t)
 local bee=B.bees[i];local launch=1.8+(i-1)*.85
 local rise=ease((t-launch)/1.2)
 local x=Arena.width/2+(i-2)*Arena.width*.27;local y=360+(i==2 and 60 or -10)-rise*150
 local exit=5.15+(i-1)*.09;local back=6.3+(i-1)*.07
 local off=i==1 and -140 or i==3 and Arena.width+140 or x
 local offY=i==2 and -150 or y-70
 local dir='down'
 if t>=back then
  local u=math.min(1,(t-back)/.28)
  x=bee.x;y=-150+(bee.y-10+150)*u
 elseif t>=exit then
  local u=math.min(1,(t-exit)/.24)
  x=x+(off-x)*u;y=y+(offY-y)*u;dir=i==1 and 'left' or i==3 and 'right' or 'up'
 end
 return {x=x,y=y,reveal=rise,launch=launch,formation=ease((t-back)/.28),dir=dir,
  fissure=1-ease((t-4.4)/1.1)}
end
local function fissure(x,y,t,i)
 local g=love.graphics;local glow=ease((t-.4-i*.2)/1.1)
 local pulse=.8+.2*math.sin(t*5+i)
 local shrink=1-ease((t-4.4)/1.1);if shrink<=0 then return end
 g.push();g.translate(x,y);g.scale(shrink);x=0;y=0
 for ray=1,5 do
  local a=ray*2.399+i;local points={x,y}
  for j=1,5 do local r=j*17;local bend=math.sin(j*2.7+ray)*9
   points[#points+1]=x+math.cos(a)*r+math.sin(a)*bend
   points[#points+1]=y+math.sin(a)*r*.55+math.cos(a)*bend
  end
  for pass=3,1,-1 do
   g.setColor(1,pass==1 and .65 or .16,.015,glow*pulse*(pass==1 and .95 or .12))
   g.setLineWidth(pass==1 and 2 or pass*5);g.line(points)
  end
 end
 g.pop()
end
function B.draw(canvas,w,h)
 local g=love.graphics;local t=B.age;local width=Arena.width
 g.push('all');g.origin()
 require('boss_arrival_backdrop').draw(canvas,w,h)
 for i=1,3 do
  local fx=width/2+(i-2)*width*.27;local fy=360+(i==2 and 60 or -10)
  fissure(fx,fy,t,i)
  local p=B.pose(i,t)
  -- Cinders burst up first, outlining a silhouette before the wings open.
  for j=1,16 do
   local age=t-p.launch;local u=(age*.5+j*.173)%1
   local alpha=ease(age/.3)*(1-u)*p.fissure
   local ex=fx+math.sin(j*2.399)*u*100;local ey=fy-u*(130+j%5*22)
   g.setColor(1,.18+j%4*.08,.015,alpha*.2);g.circle('fill',ex,ey,5)
   g.setColor(1,.65,.13,alpha);g.circle('fill',ex,ey,1+j%3*.5)
  end
  if p.reveal>0 then
   local hover=math.sin(t*36+i)*2*p.reveal
   g.setColor(.14+.86*p.reveal,.06+.94*p.reveal,.035+.965*p.reveal,p.reveal)
   Art.drawFacing('wasp',p.dir,p.x,p.y+hover,96)
   for j=1,3 do
    local trail=math.max(0,1-p.formation)*p.reveal
    g.setColor(1,.34,.035,.2*trail/j);g.setLineWidth(2)
    g.line(p.x-24+j*12,p.y+30,p.x-24+j*12,p.y+30+j*14*trail)
   end
  end
 end
 g.pop()
end
return B
