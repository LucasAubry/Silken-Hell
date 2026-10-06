-- Celebrate the rank in its existing results-page slot, without a modal.
local P={previewRank=0}
local colors={{1,.81,.34},{.78,.86,.94},{.84,.52,.30}}
function P.test()
 local V=require('victory_screen')
 if not (V.run and V.run.podiumPreview) then P.previousRun=V.run end
 P.previewRank=P.previewRank%3+1
 local world=App.selectedWorld or 1
 V.run={world=world,biome=Worlds.biome(world),name=Profile.name,time=125.4,deaths=3,rows={},started=UI.clock,page=1,hardcore=false,podiumPreview=P.previewRank}
 App.state='victory';UI.buttons={};UI.pressed=nil;Input.index=1
end
function P.closePreview()
 local V=require('victory_screen')
 if not (V.run and V.run.podiumPreview) then return false end
 V.run=P.previousRun;P.previousRun=nil;App.state='menu';UI.buttons={};UI.pressed=nil;Input.index=1;return true
end
function P.prepare(run,text)
 local rank=tonumber(text:match('^#(%d+)$'))
 if not rank or rank<1 or rank>3 or run.hardcore then return end
 if run.animatedRank~=rank then
  run.animatedRank=rank;run.rankStarted=UI.clock
  if not Replay.playing then Audio.play('levelUp') end
 end
 return rank
end
function P.drawLight(run,text,x,y)
 local rank=P.prepare(run,text);if not rank or not Graphics.effects then return end
 local g=love.graphics;local t=math.max(0,UI.clock-run.rankStarted);local c=colors[rank]
 local cx=x+UI.fonts.heading:getWidth(text)/2;local cy=y+UI.fonts.heading:getHeight()/2
 g.push('all');g.setBlendMode('add')
 P.light=P.light or g.newShader('assets/shaders/podium_light.glsl')
 P.light:send('origin',{cx,cy});P.light:send('lightColor',c);P.light:send('clock',t)
 P.light:send('arrival',math.min(1,t/.65));g.setShader(P.light);g.setColor(1,1,1)
 g.draw(UI.pixel,0,0,0,1200,750);g.setShader()
 -- Continuously renewed sparks travel from the number into the whole page.
 for i=1,(Graphics.quality==1 and 18 or 34) do
  local age=(t*.095+i*.618)%1;local angle=i*2.399+.08*math.sin(t*.2+i)
  local radius=32+age*1250;local alpha=math.sin(age*math.pi)*.65*math.min(1,t)
  local dx,dy=math.cos(angle),math.sin(angle)
  local px,py=cx+dx*radius,cy+dy*radius
  g.setColor(c[1],c[2],c[3],alpha*.6);g.setLineWidth(1)
  g.line(px,py,px-dx*(5+age*12),py-dy*(5+age*12))
  g.setColor(1,c[2]*.5+.5,c[3]*.5+.5,alpha);g.circle('fill',px,py,1+i%3*.35)
 end
 g.pop()
end
function P.drawRank(run,text,x,y)
 local rank=P.prepare(run,text)
 if not rank then UI.rawText(text,x,y,'heading',{.94,.96,1});return end
 local g=love.graphics;local c=colors[rank];local t=math.max(0,UI.clock-run.rankStarted)
 local width=UI.fonts.heading:getWidth(text);local height=UI.fonts.heading:getHeight()
 local cx,cy=x+width/2,y+height/2
 g.push('all');g.setShader()
 if Graphics.effects then
  local burst=.45+.15*math.sin(t*1.3)
  for i=5,1,-1 do
   g.setColor(c[1],c[2],c[3],(.022+.012*math.sin(t*2))*i/5)
   g.ellipse('fill',cx,cy,width/2+i*3,14+i*2)
  end
  for i=1,10 do
   local angle=i*2.399+t*.5;local radius=21+(1-math.exp(-t*4))*19
   g.setColor(c[1],c[2],c[3],burst*.8)
   g.circle('fill',cx+math.cos(angle)*radius,cy+math.sin(angle)*radius*.53,1+i%2*.5)
  end
  local pulse=1.5+.07*math.sin(t*1.8)
  g.translate(cx,cy);g.scale(pulse);g.translate(-cx,-cy)
 else
  g.translate(cx,cy);g.scale(1.5);g.translate(-cx,-cy)
 end
 -- A dark edge keeps the numeral readable against its own light source.
 for _,offset in ipairs({{-1.1,0},{1.1,0},{0,-1.1},{0,1.1},{-.8,-.8},{.8,-.8},{-.8,.8},{.8,.8}}) do
  UI.rawText(text,x+offset[1],y+offset[2],'heading',{.012,.016,.022,1})
 end
 local shine=Graphics.effects and math.max(0,math.cos(t*2.2))^16*.18+.28 or .28
 UI.rawText(text,x,y,'heading',{c[1]+(1-c[1])*shine,c[2]+(1-c[2])*shine,c[3]+(1-c[3])*shine})
 g.pop()
end
return P
