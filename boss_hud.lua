-- Boss-only overlay: one small reusable canvas lets the name, frame and life
-- segments fade together without changing the rest of the interface.
local H={opacity=1,left=298,top=40,width=604,height=78}
local g=love.graphics
H.themes={
 merle={edge={.83,.86,.64},fill={.42,.66,.52},light={.92,.95,.76}},
 wasp={edge={.94,.65,.22},fill={.83,.36,.10},light={1,.81,.35}},
 storm={edge={.53,.78,.94},fill={.24,.53,.81},light={.82,.95,1}},
 hedgehog={edge={.72,.53,.32},fill={.42,.51,.30},light={.84,.75,.46}},
 octopus={edge={.31,.65,.69},fill={.13,.45,.52},light={.58,.85,.79}},
 skeleton_fish={edge={.74,.79,.69},fill={.29,.32,.65},light={.58,.75,.95}},
 mixed={edge={.68,.65,.73},fill={.45,.29,.48},light={.87,.76,.84}}
}
function H.kind(boss)
 for kind,value in pairs({merle=Raven,wasp=Wasp,storm=Storm,hedgehog=Hedgehog,octopus=Octopus,skeleton_fish=Abyss}) do if boss==value then return kind end end
 local common
 for _,item in ipairs(Bosses.items) do
  if item.boss==boss then return item.kind end
  if common and common~=item.kind then return 'mixed' end
  common=item.kind
 end
 return common or 'mixed'
end
function H.overlaps(w,h)
 local scale,ox,oy=App.viewport(w,h);local ui=math.min(w/1200,h/750)
 local sx,sy=BossFX.offset()
 local x=(ox+(player.x+15+sx)*scale-(w-1200*ui)/2)/ui
 local y=(oy+(player.y+8+sy)*scale-(h-750*ui)/2)/ui
 local radius=31*scale/ui
 local top=H.top+(H.offsetY or 0)
 return x+radius>=H.left and x-radius<=H.left+H.width and y+radius>=top and y-radius<=top+H.height
end
local function tint(c,a) g.setColor(c[1],c[2],c[3],a or 1) end
local function frame(mode,x,y,w,h,cut)
 g.polygon(mode,x+cut,y,x+w-cut,y,x+w,y+cut,x+w,y+h-cut,x+w-cut,y+h,x+cut,y+h,x,y+h-cut,x,y+cut)
end
local function emblem(kind,x,y,t)
 tint(t.edge);g.setLineWidth(2)
 if kind=='merle' then
  g.ellipse('fill',x,y,8,12);g.setColor(.14,.24,.21);g.line(x-2,y-7,x+2,y-2,x-2,y+2,x+2,y+7)
 elseif kind=='wasp' then
  g.circle('line',x,y,11,6);g.circle('fill',x,y,4,6)
 elseif kind=='storm' then
  g.polygon('fill',x+3,y-14,x-8,y+2,x,y+2,x-3,y+14,x+9,y-3,x+1,y-3)
 elseif kind=='hedgehog' then
  for i=-1,1 do g.polygon('fill',x+i*5-3,y+9,x+i*6,y-12+math.abs(i)*5,x+i*5+3,y+9) end
 elseif kind=='octopus' then
  g.arc('line','open',x,y,10,-math.pi*.8,math.pi*.85);g.circle('line',x+1,y+1,4)
  for i=0,2 do g.circle('fill',x-7+i*5,y+10,1.5) end
 elseif kind=='skeleton_fish' then
  g.setLineWidth(4);g.line(x-7,y+8,x+7,y-8)
  for _,sign in ipairs({-1,1}) do g.circle('fill',x+sign*7-2,y-sign*8-2,3);g.circle('fill',x+sign*7+2,y-sign*8+2,3) end
 else g.polygon('line',x,y-12,x+10,y,x,y+12,x-10,y);g.line(x-4,y,x+4,y) end
 g.setLineWidth(1)
end
function H.paint(boss,kind)
 local t=H.themes[kind] or H.themes.mixed
 if kind=='wasp' and boss.hardcore then t={edge={1,.37,.12},fill={.70,.12,.055},light={1,.69,.17}} end
 UI.outlined(boss.name,335,45,'medium',t.light,530)
 local x,y,w,h=335,77,530,18
 g.setColor(.025,.04,.055,.96)
 if kind=='octopus' then g.rectangle('fill',x-5,y-5,w+10,h+10,12,12) else frame('fill',x-5,y-5,w+10,h+10,kind=='storm' and 10 or 5) end
 tint(t.edge);g.setLineWidth(2)
 if kind=='octopus' then g.rectangle('line',x-5,y-5,w+10,h+10,12,12) else frame('line',x-5,y-5,w+10,h+10,kind=='storm' and 10 or 5) end
 g.setLineWidth(1)
 local function segment(left,width,hp,maxHp)
  tint(t.fill,.23);g.rectangle('fill',left,y,width,h)
  local fill=width*math.max(0,math.min(1,hp/math.max(1,maxHp)))
  tint(t.fill);g.rectangle('fill',left,y,fill,h)
  tint(t.light,.8);g.rectangle('fill',left,y,fill,3)
  g.setColor(0,0,0,.25);g.rectangle('fill',left,y+h-4,fill,4)
  if (boss.flash or 0)>0 then g.setColor(1,1,1,math.min(.5,boss.flash*2));g.rectangle('fill',left,y,fill,h) end
  for i=1,math.min(20,maxHp)-1 do local xx=left+width*i/math.min(20,maxHp);g.setColor(.02,.04,.05,.65);g.line(xx,y+3,xx,y+h-2) end
 end
 if boss.bees then
  local width=(w-24)/3
  for i,bee in ipairs(boss.bees) do segment(x+(i-1)*(width+12),width,bee.hp,3) end
 else segment(x,w,boss.hp,boss.maxHp) end
 tint(t.edge)
 if kind=='hedgehog' then
  for i=0,12 do local xx=x+10+i*(w-20)/12;g.polygon('fill',xx-4,y-5,xx,y-11,xx+4,y-5);g.line(xx-3,y+h+5,xx,y+h+9,xx+3,y+h+5) end
 elseif kind=='storm' then
  g.line(x+8,y-6,x+82,y-6,x+88,y-10,x+95,y-6,x+168,y-6)
  g.line(x+w-168,y+h+6,x+w-95,y+h+6,x+w-88,y+h+10,x+w-82,y+h+6,x+w-8,y+h+6)
 elseif kind=='skeleton_fish' then
  for i=0,10 do local xx=x+i*w/10;g.line(xx-3,y-7,xx,y-4,xx+3,y-7);g.line(xx-3,y+h+7,xx,y+h+4,xx+3,y+h+7) end
 elseif kind=='octopus' then
  for i=0,12 do g.circle('line',x+10+i*(w-20)/12,y+h+6,2) end
 elseif kind=='wasp' then
  for _,xx in ipairs({x+w/3-4,x+w*2/3+4}) do g.circle('fill',xx,y+h/2,5,6) end
 elseif kind=='merle' then
  for i=0,5 do local xx=x+(i+.5)*w/6;g.line(xx-4,y-5,xx,y-8,xx+4,y-5) end
 end
 emblem(kind,315,86,t);emblem(kind,885,86,t)
end
function H.draw(boss)
 if not boss or not boss.active or boss.defeated then H.lastTime=nil;return end
 -- Leave the expanded upper nest visible beneath the first boss HUD.
 H.offsetY=H.kind(boss)=='merle' and -34 or 0
 local target=H.overlaps(g.getDimensions()) and .28 or 1
 local dt=H.lastTime and math.max(0,math.min(.1,UI.clock-H.lastTime)) or 1/60
 H.lastTime=UI.clock;H.opacity=H.opacity+(target-H.opacity)*(1-math.exp(-dt*14))
 H.canvas=H.canvas or g.newCanvas(H.width,H.height)
 local previous=g.getCanvas()
 g.push('all');g.setCanvas(H.canvas);g.origin();g.clear(0,0,0,0);g.setBlendMode('alpha');g.setShader();g.translate(-H.left,-H.top)
 H.paint(boss,H.kind(boss))
 g.setCanvas(previous);g.pop()
 g.push('all');g.setBlendMode('alpha','premultiplied');g.setColor(H.opacity,H.opacity,H.opacity,H.opacity);g.draw(H.canvas,H.left,H.top+(H.offsetY or 0));g.pop()
end
return H
