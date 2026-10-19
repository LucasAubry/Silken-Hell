-- Playable story interlude; leaves campaign physics and replay inputs untouched.
local S={}
local function distance(a,b)return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)end
function S.begin(actor,portal)
 S.active=true;S.actor={x=actor.x,y=actor.y,dir='down'};S.portal={x=portal.x,y=portal.y}
 S.time=0;S.delivered=0;S.carried=nil;S.weave=0;S.exit=nil;S.fade=nil;S.threads={}
 local positions=levels[player.level].larme_position
 for i,p in ipairs(positions) do
  local x,y=Arena.clearSpot(p.x,p.y,30,24)
  S.threads[#S.threads+1]={x=x+15,y=y+12}
 end
end
function S.update(dt)
 dt=math.min(dt,.05)
 if S.fade then
  S.fade=S.fade-dt/1.1
  if S.fade<=0 then S.active=false;return true end
  return false
 end
 if S.exit then
  S.exit=S.exit+dt
  if S.exit>=1 then S.fade=1 end
  return false
 end
 S.time=S.time+dt;S.weave=math.max(0,S.weave-dt)
 local a=S.actor;local ox,oy=a.x,a.y
 if S.weave==0 then
  local dx,dy=Input.move();local speed=Input.slow() and 300 or 540
  local steps=math.max(1,math.ceil(speed*dt/4))
  for i=1,steps do
   local x,y=a.x+dx*speed*dt/steps,a.y+dy*speed*dt/steps
   if not willCollide(x-15,a.y-12) then a.x=x end
   if not willCollide(a.x-15,y-12) then a.y=y end
  end
  if math.abs(dx)>math.abs(dy) then a.dir=dx<0 and 'left' or 'right' elseif dy~=0 then a.dir=dy<0 and 'up' or 'down' end
  if not S.carried then
   for _,thread in ipairs(S.threads) do
    if not thread.taken and distance(a,thread)<28 then thread.taken=true;S.carried=thread;break end
   end
  end
  if S.carried and distance(a,S.portal)<48 then
   S.carried=nil;S.delivered=S.delivered+1;S.weave=.6
  elseif S.delivered==#S.threads and distance(a,S.portal)<28 then S.exit=0 end
 end
 require('brown_walk').advance(a,distance(a,{x=ox,y=oy}),dt)
 return false
end
function S.draw()
 local g=love.graphics;local p=S.portal;g.push('all');g.setShader()
 if S.fade then g.setColor(1,1,1);Characters.draw(player.x+15,player.y+12,Characters.playerWidth,'down',player);g.pop();return end
 local count=#S.threads;local complete=S.delivered==count
 if complete then require('prologue').drawPortal(p,math.min(1,1-S.weave/.6),S.time) end
 g.setLineWidth(1.5)
 for i=1,count do
  local angle=(i-1)*math.pi*2/count-math.pi/2
  local x,y=p.x+math.cos(angle)*50,p.y+math.sin(angle)*65
  g.setColor(1,.94,.75,.3);g.circle('line',x,y,3)
  if i<=S.delivered then
   local progress=i==S.delivered and 1-S.weave/.6 or 1
   g.setColor(1,.95,.8,.9);g.line(p.x,p.y,p.x+(x-p.x)*progress,p.y+(y-p.y)*progress)
   for ring=1,5 do
    local r=ring/5;local nextAngle=angle+math.pi*2/count
    g.line(p.x+math.cos(angle)*50*r,p.y+math.sin(angle)*65*r,p.x+math.cos(nextAngle)*50*r*progress,p.y+math.sin(nextAngle)*65*r*progress)
   end
  end
 end
 for i,t in ipairs(S.threads) do if not t.taken then
  local pulse=.75+.25*math.sin(S.time*3+i)
  g.setColor(1,.92,.68,.12*pulse);g.circle('fill',t.x,t.y,19)
  g.setColor(1,.97,.84,pulse)
  for k=1,4 do g.ellipse('line',t.x,t.y,5+k*2,3+k) end
  g.line(t.x+9,t.y,t.x+15,t.y+6,t.x+20,t.y+3)
 end end
 local a=S.actor;local alpha=S.exit and math.max(0,1-S.exit/.65) or 1
 g.setColor(1,1,1,alpha);Characters.draw(a.x,a.y,Characters.playerWidth*math.max(.1,alpha),a.dir,a)
 if S.carried then
  g.setColor(1,.96,.8,.9);g.setLineWidth(2)
  g.line(a.x,a.y-8,a.x-8,a.y-17,a.x+6,a.y-24,a.x+11,a.y-14,a.x,a.y-8)
 end
 g.pop()
end
function S.drawUI()
 local g=love.graphics;g.push('all');g.setShader()
 local status=string.format('%d / %d   ·   %.1f s',S.delivered,#S.threads,S.time)
 UI.text(status,401,79,'medium',{.04,.055,.025,.9},400,'center')
 UI.text(status,400,78,'medium',{1,.94,.76},400,'center')
 if S.time<4 then
  g.setColor(.025,.04,.035,.85);g.rectangle('fill',180,580,840,64,12)
  UI.text('Rapporte les fils de soie au portail pour reconstruire sa toile.',200,598,'medium',{1,.96,.84},800,'center')
 end
 local alpha=S.fade or (S.exit and math.min(1,S.exit) or 0)
 if alpha>0 then g.setColor(.008,.005,.016,alpha);g.rectangle('fill',-4000,-4000,9200,8750) end
 g.pop()
end
return S
