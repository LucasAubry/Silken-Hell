-- Queue newly earned skins, then present them outside live play and credits.
local R={queue={}}
local function clamp(t)return math.max(0,math.min(1,t))end
local function ease(t)t=clamp(t);return 1-(1-t)^3 end
function R.init()
 R.seen={};R.queue={};R.active=nil;R.scanTime=0
 for i=1,#Characters.keys do R.seen[i]=Characters.unlocked(i)==true end
 R.random=R.random or love.math.newRandomGenerator(os.time())
end
function R.observe()
 if not R.seen then R.init();return end
 if Replay.playing then return end
 for i=1,#Characters.keys do
  local unlocked=Characters.unlocked(i)==true
  if unlocked and not R.seen[i] then R.queue[#R.queue+1]=i end
  R.seen[i]=unlocked
 end
end
function R.open(index,preview)
 if R.active then return false end
 R.active={index=index,preview=preview==true,time=0,returnState=App.state}
 UI.pressed=nil;UI.buttons={};Input.index=1;App.state='skinUnlock'
 Audio.play('selection');return true
end
function R.test()
 if not R.seen then R.init() end
 -- Private generator: previewing never advances the game's random sequence.
 return R.open(R.random:random(6,#Characters.keys),true)
end
function R.close(equip)
 local a=R.active;if not a or a.time<3.25 then return false end
 if equip and not a.preview and Characters.unlocked(a.index) then Profile.character=a.index;Profile.save() end
 App.state=a.returnState;R.active=nil;UI.buttons={};UI.pressed=nil;Input.index=1
 return true
end
function R.update(dt)
 R.scanTime=(R.scanTime or 0)-dt
 if R.scanTime<=0 then R.observe();R.scanTime=.2 end
 if not R.active and #R.queue>0 and not Replay.playing
    and (App.state=='menu' or App.state=='victory' or App.state=='customVictory' or App.state=='worlds') then
  R.open(table.remove(R.queue,1),false)
 end
 local a=R.active;if not a then return end
 local before=a.time;a.time=a.time+dt
 if before<1.15 and a.time>=1.15 then Audio.play('pick') end
 if before<2.4 and a.time>=2.4 then Audio.play('levelUp') end
end
function R.draw()
 local a=R.active;if not a then return end
 local g=love.graphics;local t=a.time;local reveal=ease((t-2.4)/.85)
 local cx,cy=600,337;local fx=Graphics.effects
 g.push('all');g.setShader();g.setBlendMode('alpha');g.setLineStyle('smooth')
 g.setColor(.008,.015,.027,.98);g.rectangle('fill',0,0,1200,750)
 -- Soft concentric light, then silk strands drawing inward around a sealed cocoon.
 for i=20,1,-1 do
  local radius=100+i*10
  g.setColor(.48,.27,.07,(.014+.038*reveal)*(1-i/24));g.ellipse('fill',cx,cy,radius,radius*.82)
 end
 if t<3.25 then
  local gather=ease(t/2.4);local opacity=1-reveal
  local breath=1+.025*math.sin(t*4)
  g.setColor(.032,.033,.044,opacity);g.ellipse('fill',cx,cy,96*breath,121*breath)
  local count=fx and 22 or 10
  for i=1,count do
   local angle=i*2.399+t*(.25+gather*.7);local radius=210-(gather*135)+i%4*4
   local x,y=cx+math.cos(angle)*radius,cy+math.sin(angle)*radius*.75
   g.setColor(.87,.76,.48,(.16+.36*gather)*opacity);g.setLineWidth(1)
   g.line(x,y,cx+math.cos(angle+1.4)*92,cy+math.sin(angle+1.4)*118)
   g.setColor(1,.86,.55,.7*opacity);g.circle('fill',x,y,1.4)
  end
  for i=1,9 do
   g.setColor(.78,.73,.6,(.10+.025*i)*opacity)
   g.ellipse('line',cx,cy,92+math.sin(t*1.5+i)*5,30+i*10)
  end
 end
 if t>=2.4 then
  local age=t-2.4
  if fx then
   if not R.rays then
    local vertices={}
    for i=1,18 do
     local angle=i*math.pi/9;local length=i%2==0 and 1 or .8
     vertices[#vertices+1]={0,0,0,0,1,.74,.26,.20}
     vertices[#vertices+1]={math.cos(angle-.035)*length,math.sin(angle-.035)*length,0,0,1,.65,.16,0}
     vertices[#vertices+1]={math.cos(angle+.035)*length,math.sin(angle+.035)*length,0,0,1,.65,.16,0}
    end
    R.rays=g.newMesh(vertices,'triangles','static')
   end
   g.setColor(1,1,1,reveal);g.draw(R.rays,cx,cy,t*.065,330,285)
   for i=1,42 do
    local angle=i*2.399;local radius=90+(1-math.exp(-age*2.2))*(70+i%7*22)
    local opacity=math.max(0,1-age/2.8)
    local x,y=cx+math.cos(angle)*radius,cy+math.sin(angle)*radius*.8
    g.setColor(1,.68+(i%3)*.1,.24,opacity*.7);g.setLineWidth(i%3==0 and 2 or 1)
    g.line(x,y,x+math.cos(angle)*8*opacity,y+math.sin(angle)*8*opacity)
   end
   g.setColor(1,.84,.46,math.max(0,1-age/.8)*.5);g.setLineWidth(2)
   g.ellipse('line',cx,cy,90+age*150,70+age*110)
  end
  -- Reveal the full-resolution sprite immediately. Fading crowned/gold skins
  -- used the small trail compositor and blurred them until opacity reached 1.
  g.setColor(1,1,1)
  Characters.portrait(a.index,cx,cy,240,'down')
  UI.text(Characters.names[a.index],250,499,'heading',{1,.96,.83,reveal},700,'center')
 end
 if t>=3.25 then
  if a.preview then UI.button('CONTINUER',460,602,280,46,function()R.close()end,false,true)
  else
   UI.button('ÉQUIPER',400,602,195,46,function()R.close(true)end,false,true)
   UI.button('CONTINUER',605,602,195,46,function()R.close()end)
  end
 end
 g.pop()
end
return R
