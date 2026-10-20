-- A return to the arena: the challenger walks into the light of all seven worlds.
local C={duration=9.2}
local colors={[1]={1,.80,.38},[6]={.55,.73,1},[5]={.76,.56,.33},[4]={.2,.9,.9},[7]={.25,.47,1},[2]={1,.25,.06},[3]={.65,1,.35}}
local function ease(v)v=math.max(0,math.min(1,v));return v*v*(3-2*v)end
function C.begin()return {age=0,actor={walkMoving=false,sanctuaryPlayer=true},previousY=690} end
function C.update(state,dt)
 state.age=math.min(C.duration,state.age+dt)
 local y=690-205*ease(state.age/3.6)
 require('brown_walk').advance(state.actor,math.abs(y-state.previousY),dt);state.previousY=y
 return state.age>=C.duration
end
function C.draw(S)
 local state=S.intro;local t=state.age;local g=love.graphics;local R=require('sanctuary_scene');local w=Arena.width
 local reveal=ease((t-1.2)/3.5);local pull=ease((t-1.8)/3.6)
 if not C.canvas or C.canvas:getWidth()~=w then
  if C.canvas then C.canvas:release() end
  C.canvas=g.newCanvas(w,600)
 end
 local target=g.getCanvas()
 g.push('all');g.setCanvas(C.canvas);g.origin();g.setScissor();g.setShader();g.clear()
 R.hall(false)
 local impact=math.exp(-((t-1.7)/.16)^2)
 g.translate(math.sin(t*79)*impact*3,math.cos(t*87)*impact*4)
 -- Pull back from the challenger to reveal the full, symmetrical council.
 local zoom=1.3-.3*pull
 g.translate(w*.5,340);g.scale(zoom);g.translate(-w*.5,-340)
 g.setColor(.006,.008,.018,.68*(1-reveal));g.rectangle('fill',-w,-600,w*3,1800)
 -- Long converging floor seams and a silk sigil give the room depth.
 for i=0,20 do
  local x=(i-10)*w*.15+w*.5
  g.setColor(.28,.38,.49,.12+.12*reveal);g.setLineWidth(1)
  g.line(w*.5+(i-10)*13,235,x,680)
 end
 for i=1,9 do
  local y=285+(i/9)^2*400
  g.setColor(.3,.37,.46,.15);g.line(0,y,w,y)
 end
 for ring=1,4 do
  g.setColor(.55,.72,.9,reveal*.09);g.setLineWidth(1.4)
  g.ellipse('line',w*.5,400,130+ring*65,22+ring*17)
 end
 local bosses=S.normalBosses
 for i,p in ipairs(bosses) do
  local u=(i-.5)/#bosses;local bx=w*(.07+.86*u);local by=210+90*math.abs(u-.5)*2
  local awake=ease((t-1.65-i*.34)/.75);local c=colors[p.world] or colors[1]
  -- Light wells ignite underneath each real boss sprite, without spawning text.
  g.setBlendMode('add','alphamultiply')
  for j=7,1,-1 do
   g.setColor(c[1],c[2],c[3],awake*.016)
   g.ellipse('fill',bx,by+42,38+j*6,8+j*2)
   g.polygon('fill',bx-25,by+40,bx+25,by+40,bx+45+j*2,-40,bx-45-j*2,-40)
  end
  g.setBlendMode('alpha','alphamultiply')
  g.setColor(.08,.10,.14);g.ellipse('fill',bx,by+45,58,13)
  g.setColor(c[1],c[2],c[3],awake*.7);g.setLineWidth(2);g.ellipse('line',bx,by+45,58,13)
  local size=p.type=='skeleton_head' and .23 or p.type=='wasp' and .31 or p.type=='final_spider' and .88 or .62
  g.push();g.translate(bx,by+math.sin(t*1.3+i)*2);g.scale(size)
  R.boss(p,0,0);g.pop()
  -- Mask the alcove until its light catches the waiting adversary.
  g.setColor(.006,.009,.018,(1-awake)*.96);g.rectangle('fill',bx-w*.061,by-88,w*.122,128)
 end
 R.fog(true,false)
 -- A clear rear silhouette holds the last shot; the same walking rig drives arrival.
 local hy=690-205*ease(t/3.6);local heroSize=Characters.playerWidth*(2.8-.65*pull)
 Characters.shadow(w*.5,hy+15,heroSize,'up',state.actor,.9)
 for j=6,1,-1 do
  g.setColor(.65,.76,.92,.015*reveal);g.ellipse('fill',w*.5,hy+18,heroSize*.45+j*5,12+j*3)
 end
 g.setColor(1,1,1);Characters.draw(w*.5,hy,heroSize,'up',state.actor,8)
 -- Embers drift towards the confrontation, crossing foreground and background.
 g.setBlendMode('add','alphamultiply')
 for i=1,90 do
  local x=w*((i*.618+t*(.003+i%3*.002))%1);local y=600*((i*.137-t*(.012+i%5*.004))%1)
  g.setColor(.85,.57+.25*math.sin(i)^2,.30,reveal*(.13+i%4*.05))
  g.circle('fill',x,y,.65+i%3*.6)
 end
 g.setBlendMode('alpha','alphamultiply')
 g.setColor(0,0,0,.9);g.rectangle('fill',-w,-600,w*3,628);g.rectangle('fill',-w,572,w*3,700)
 g.setColor(0,0,0,1-ease(t/.8));g.rectangle('fill',-w,-600,w*3,1800)
 g.setCanvas(target);g.pop()
 local dissolve=ease((t-8.2)/1)
 if dissolve>0 then R.draw(S) end
 g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied');local a=1-dissolve;g.setColor(a,a,a,a);g.draw(C.canvas);g.pop()
end
return C
