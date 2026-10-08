-- Wait for a fresh speed-button press outside deterministic gameplay/replay time.
local C={}
function C.begin()
 C.elapsed=0;C.goAge=nil;C.countdown=nil
 C.active=not (App.practice or App.singleLevel or App.sessionLayout or Secret.duel or Replay.playing or App.preview or os.getenv('SILKEN_PREVIEW_WORLD'))
 C.armed=not Input.speedHeld()
end
function C.startCountdown()
 C.active=true;C.elapsed=0;C.goAge=nil;C.countdown=3;C.armed=false
end
function C.launch()
 if not C.active or App.state~='playing' or Replay.playing then return false end
 C.active=false;C.goAge=0;C.countdown=nil;Audio.play('startRun')
 require('game_feedback').emit('start',player.x+15,player.y+12)
 return true
end
function C.press(binding,isrepeat)
 if C.countdown then return false end
 if not C.active or binding~=Profile.keys.dash or isrepeat then return false end
 if App.state~='playing' then C.armed=false;return false end
 -- A non-repeated input event is already a fresh press, even between updates.
 return C.launch()
end
function C.suspend()
 if C.active then C.armed=not Input.speedHeld() end
end
function C.advance(dt)
 if App.state~='playing' then C.suspend();return 0 end
 if not C.active then if C.goAge then C.goAge=C.goAge+dt end;return dt end
 C.elapsed=C.elapsed+dt
 if C.countdown then
  C.countdown=math.max(0,C.countdown-dt)
  if C.countdown==0 then C.launch() end
  return 0
 end
 local held=Input.speedHeld()
 if not held then C.armed=true
 elseif C.armed then C.launch();return dt end
 return 0
end
function C.keyLabel()
 if Input.active and Input.pad and Input.pad:isConnected() then return require('pad_controls').label(Profile.padBindings.dash) end
 local key=Profile.keys.dash;local T=require('localization').text
 if key=='space' then return T('ESPACE') end
 local mouse=key:match('^mouse:(%d+)$')
 return mouse and T('SOURIS %s',mouse) or Input.label(key)
end
function C.draw()
 if App.state~='playing' or Replay.playing then return end
 if not C.active and (not C.goAge or C.goAge>=.18) then return end
 local g=love.graphics;local T=require('localization').text
 if C.countdown then
  g.push('all');g.setShader();UI.text(tostring(math.max(1,math.ceil(C.countdown))),480,280,'title',{1,.94,.72},240,'center');g.pop();return
 end
 local alpha=C.active and math.min(1,.35+C.elapsed*5) or 1-C.goAge/.18
 local w,h=g.getDimensions();local _,ph=g.getPixelDimensions()
 local density=math.max(1,math.min(w/1200,h/750)*ph/h)
 if not C.font or math.abs((C.fontDensity or 0)-density)>.01 then
  C.fontDensity=density;C.font=g.newFont(20,'normal',density);C.font:setFilter('linear','linear')
  C.fallback=g.newFont('assets/fonts/NotoSansCJKjp-Regular.otf',20,'normal',density);C.font:setFallbacks(C.fallback)
 end
 local label,key=T('Appuie pour démarrer'),C.keyLabel()
 local keyWidth=math.max(60,C.font:getWidth(key)+28)
 local width=C.font:getWidth(label)+keyWidth+56
 local scale=math.min(1,1000/width)
 local pulse=require('ui_motion').enabled() and .06*math.sin(UI.clock*3) or 0
 g.push('all');g.setShader();g.setFont(C.font);g.translate(600,238);g.scale(scale)
 local x,y=-width/2,-30
 g.setColor(.018,.026,.035,.90*alpha);g.rectangle('fill',x,y,width,60,12)
 g.setColor(.91,.77,.47,(.36+pulse)*alpha);g.setLineWidth(1);g.rectangle('line',x,y,width,60,12)
 g.setColor(.96,.95,.89,alpha);g.print(label,x+20,-C.font:getHeight()/2)
 local kx=x+width-keyWidth-10
 g.setColor(.20,.18,.13,alpha);g.rectangle('fill',kx,-20,keyWidth,40,7)
 g.setColor(.94,.80,.51,(.75+pulse)*alpha);g.rectangle('line',kx,-20,keyWidth,40,7)
 g.setColor(1,.9,.66,alpha);g.print(key,kx+(keyWidth-C.font:getWidth(key))/2,-C.font:getHeight()/2)
 g.pop()
end
return C
