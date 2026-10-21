-- A return to the arena: the challenger walks into the light of all seven worlds.
local C={duration=6.8}
local colors={[1]={1,.80,.38},[6]={.55,.73,1},[5]={.76,.56,.33},[4]={.2,.9,.9},[7]={.25,.47,1},[2]={1,.25,.06},[3]={.65,1,.35}}
local function ease(v)v=math.max(0,math.min(1,v));return v*v*(3-2*v)end
function C.bossPosition(i,count,w)
 local u=(i-.5)/count
 return w*(.07+.86*u),210+90*math.abs(u-.5)*2
end
function C.begin()return {age=0,actor={walkMoving=false,sanctuaryPlayer=true},previousY=690} end
function C.update(state,dt)
 state.age=state.age+dt
 local y=690-205*ease(state.age/3.6)
 require('brown_walk').advance(state.actor,math.abs(y-state.previousY),dt);state.previousY=y
 return state.age>=C.duration
end
function C.draw(S)
 local state=S.presentation;local t=state.age;local g=love.graphics;local R=require('sanctuary_scene');local w=Arena.width
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
  local bx,by=C.bossPosition(i,#bosses,w)
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
  local selected=not S.intro and S.page==i
  R.throneAt(bx,by,.52,selected and {1,.83,.26} or c,selected)
  local size=p.type=='skeleton_head' and .23 or p.type=='wasp' and .31 or p.type=='final_spider' and .88 or .62
  g.push();g.translate(bx,by+math.sin(t*1.3+i)*2);g.scale(size)
  R.boss(p,0,0);g.pop()
  -- Soft moving smoke hides the alcove, with no rectangular mask edges.
  if awake<1 then
   C.smoke=C.smoke or g.newShader('assets/shaders/sanctuary_smoke.glsl')
   local cx,cy=g.transformPoint(bx,by-20)
   C.smoke:send('center',{cx,cy});C.smoke:send('radius',{75*zoom,115*zoom})
   C.smoke:send('clock',t+i*2);C.smoke:send('opacity',1-awake)
   g.setShader(C.smoke);g.setColor(1,1,1);g.rectangle('fill',bx-100,by-160,200,280);g.setShader()
  end
  if selected then
   g.setColor(1,.82,.22,.85);g.setLineWidth(2)
   g.ellipse('line',bx,by,63,94)
   UI.arrowArt(bx,by-126+math.sin(UI.clock*3)*3,1,false,math.pi/2,{1,.83,.22})
  end
 end
 R.fog(true,false)
 -- A clear rear silhouette holds the last shot; the same walking rig drives arrival.
 local hy=690-205*ease(t/3.6);local heroSize=Characters.playerWidth*(2.8-.65*pull)
 Characters.shadow(w*.5,hy+15,heroSize,'up',state.actor,.9)
 for j=6,1,-1 do
  g.setColor(.65,.76,.92,.015*reveal);g.ellipse('fill',w*.5,hy+18,heroSize*.45+j*5,12+j*3)
 end
 g.push();g.translate(w*.5,hy);g.rotate(S.turn or 0);g.setColor(1,1,1);Characters.draw(0,0,heroSize,'up',state.actor,8);g.pop()
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
 g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1);g.draw(C.canvas);g.pop()
end
return C
