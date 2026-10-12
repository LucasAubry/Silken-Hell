-- The menu's petrol plates and ivory edging for Paradise and Sky.
local P={}
local g=love.graphics
local ivory={1,.95,.82}
local gold={1,.76,.24}
local function bevel(mode,x,y,w,h,cut)
 g.polygon(mode,x+cut,y,x+w-cut,y,x+w,y+cut,x+w,y+h-cut,
  x+w-cut,y+h,x+cut,y+h,x,y+h-cut,x,y+cut)
end
function P.active()
 return Campaign and (Campaign.biome==1 or Campaign.biome==6) and not (Secret and Secret.inArena())
end
function P.plate(x,y,w,h,focus,disabled)
 local cut=7
 local alpha=disabled and .38 or 1
 g.setColor(.15,.12,.07,.30);bevel('fill',x+1,y+3,w,h,cut)
 g.setColor(disabled and {.08,.12,.13,.98} or {.018,.070,.076,.99})
 bevel('fill',x,y,w,h,cut)
 g.setColor(.14,.25,.25,focus and .58 or .30)
 g.polygon('fill',x+cut,y+3,x+w-cut,y+3,x+w-3,y+cut,x+w-3,y+h*.48,x+3,y+h*.48,x+3,y+cut)
 -- A dark gold bevel under the thin ivory lip gives the menu plates depth.
 g.setLineJoin('bevel');g.setLineWidth(3.2)
 g.setColor(.53,.41,.22,alpha)
 bevel('line',x,y,w,h,cut)
 g.setLineWidth(1);g.setColor(ivory[1],ivory[2],ivory[3],.95*alpha)
 bevel('line',x,y,w,h,cut)
 g.setColor(.82,.70,.42,(focus and .92 or .78)*alpha)
 bevel('line',x+3,y+3,w-6,h-6,math.max(3,cut-2))
 g.setColor(1,.94,.72,.42*alpha)
 g.line(x+cut+2,y+1,x+w-cut-2,y+1)
 g.setLineWidth(1)
end
function P.status(U,text,x,y,w,h)
 g.push('all');g.setShader();g.setBlendMode('alpha')
 P.plate(x,y,w,h)
 local label=U.ellipsize(require('localization').render(text),'body',w-22)
 U.rawText(label,x+11,y+(h-U.fonts.body:getHeight())/2,'body',ivory,w-22,'center')
 g.pop()
end
local function hourglass(x,y)
 g.setColor(gold);g.setLineWidth(2)
 g.line(x-8,y-11,x+8,y-11)
 g.line(x-8,y+11,x+8,y+11)
 g.line(x-6,y-9,x-5,y-5,x+4,y+5,x+6,y+9)
 g.line(x+6,y-9,x+5,y-5,x-4,y+5,x-6,y+9)
 g.setColor(1,.86,.45)
 g.polygon('fill',x-4,y-6,x+4,y-6,x,y-2)
 g.polygon('fill',x,y+4,x-4,y+8,x+4,y+8)
 g.circle('fill',x,y+1,1)
end
function P.draw(U)
 g.push('all');g.setShader();g.setBlendMode('alpha')
 local deaths=tostring(player.death)
 local deathWidth=math.max(36,U.fonts.medium:getWidth(deaths))
 P.plate(28,9,244+deathWidth,43)
 hourglass(59,30.5)
 local elapsed=Replay.playing and Replay.frame*Replay.step or Scoring.total(timer,player.death)
 U.rawText(U.time(elapsed),81,30.5-U.fonts.medium:getHeight()/2,'medium',ivory,119,'center')
 g.setLineWidth(1);g.setColor(.86,.76,.53,.42);g.line(208,17,208,44)
 g.setColor(.03,.05,.04,.8);g.line(210,17,210,44)
 g.setColor(1,1,1);Art.draw('skull',240,30.5,26)
 U.rawText(deaths,262,30.5-U.fonts.medium:getHeight()/2,'medium',ivory,deathWidth,'center')
 P.plate(559,8,82,45)
 U.rawText(string.format('%02d',player.level),566,30.5-U.fonts.medium:getHeight()/2,'medium',ivory,68,'center')
 g.pop()
 if Replay.playing then
  P.status(U,Replay.ghost and 'Entraînement' or ('/ '..U.time(Replay.data.frames*Replay.step)),335,56,215,30)
 end
end
function P.icon(U,cx,cy,kind,callback,disabled)
 local mx,my=U.mouse()
 local hover=not disabled and ((Input and Input.active) and Input.index==#U.buttons+1
  or not (Input and Input.active) and math.abs(mx-cx)<=25 and math.abs(my-cy)<=22)
 g.push('all');g.setShader();g.setBlendMode('alpha')
 P.plate(cx-25,cy-22,50,44,hover,disabled)
 g.setColor(gold[1],gold[2],gold[3],disabled and .35 or 1);g.setLineWidth(2.5)
 if kind=='pause' then
  g.rectangle('fill',cx-7,cy-10,5,20);g.rectangle('fill',cx+3,cy-10,5,20)
 elseif kind=='info' then
  g.circle('line',cx,cy,12,32)
  g.circle('fill',cx,cy-6,1.8);g.rectangle('fill',cx-1.3,cy-1.5,2.6,8)
  g.setLineWidth(1.5);g.line(cx-3,cy+7,cx+3,cy+7)
 else
  g.arc('line','open',cx,cy,10.5,-math.pi*.8,math.pi*.8,32)
  g.polygon('fill',cx-13,cy-6,cx-4,cy-12,cx-4,cy)
 end
 g.pop()
 U.buttons[#U.buttons+1]={x=cx-25,y=cy-22,w=50,h=44,run=callback,disabled=disabled}
end
return P
