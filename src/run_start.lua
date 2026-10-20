-- Wait for a fresh speed-button press outside deterministic gameplay/replay time.
local C={}
local storyWorlds={[6]=true,[5]=true,[4]=true,[7]=true,[2]=true,[3]=true}
local function smooth(v)v=math.max(0,math.min(1,v));return v*v*(3-2*v)end
function C.begin()
 C.elapsed=0;C.goAge=nil;C.countdown=nil;C.arrival=nil;C.arrivalActor=nil;C.arrivalKind=nil;C.arrivalPractice=false;C.rememberTransition=nil
 C.active=not (App.practice or App.singleLevel or App.sessionLayout or Secret.duel or Replay.playing or App.preview or os.getenv('SILKEN_PREVIEW_WORLD'))
 C.armed=not Input.speedHeld()
 if App.practice and not (App.preview or App.sessionLayout or Secret.duel or Replay.playing) then
  C.beginArrival(true,true);C.arrivalPractice=true;Hardcore.beginTrainingBorder()
 elseif C.active then
  if (Profile.transitionsSeen or {})[tostring(Campaign.world)]==true and storyWorlds[Campaign.world] then
   direction='up';C.arrivalKind='brief';C.arrival=0;C.armed=false
   C.arrivalDuration=require('biome_entry').begin(Campaign.world)
  elseif Campaign.world==6 then C.beginSkyArrival(true)
  elseif Campaign.world==5 then C.beginEarthArrival()
  elseif Campaign.world==4 then C.beginOceanArrival()
  elseif Campaign.world==7 then C.beginAbyssArrival()
  elseif Campaign.world==2 then C.beginHellArrival()
  elseif Campaign.world==3 then C.beginRenaissanceArrival()
  else C.beginArrival(true,true) end
  if C.scene() and C.arrivalKind~='brief' then C.rememberTransition=Campaign.world end
 end
end
-- The first portal opens onto the real level, held still until the story ends.
function C.beginSkyArrival(fromParadise)
 direction='up'
 C.arrivalKind='sky';C.arrival=0;C.active=true;C.armed=false
 C.arrivalDuration=require('sky_arrival').begin(fromParadise)
end
function C.beginEarthArrival()
 direction='up'
 C.arrivalKind='earth';C.arrival=0;C.active=true;C.armed=false
 C.arrivalDuration=require('earth_arrival').begin()
end
function C.beginOceanArrival()
 direction='up'
 C.arrivalKind='ocean';C.arrival=0;C.active=true;C.armed=false
 C.arrivalDuration=require('ocean_arrival').begin()
end
function C.beginAbyssArrival()
 direction='up'
 C.arrivalKind='abyss';C.arrival=0;C.active=true;C.armed=false
 C.arrivalDuration=require('abyss_arrival').begin()
end
function C.beginHellArrival()
 direction='up';C.arrivalKind='hell';C.arrival=0;C.active=true;C.armed=false
 C.arrivalDuration=require('hell_arrival').begin()
end
function C.beginRenaissanceArrival()
 direction='up';C.arrivalKind='renaissance';C.arrival=0;C.active=true;C.armed=false
 C.arrivalDuration=require('renaissance_arrival').begin()
end
function C.scene()
 if C.arrivalKind=='brief' then return require('biome_entry') end
 if C.arrivalKind=='hell' then return require('hell_arrival') end
 if C.arrivalKind=='renaissance' then return require('renaissance_arrival') end
 if C.arrivalKind=='sky' then return require('sky_arrival') end
 if C.arrivalKind=='earth' then return require('earth_arrival') end
 if C.arrivalKind=='abyss' then return require('abyss_arrival') end
 if C.arrivalKind=='ocean' then return require('ocean_arrival') end
end
function C.beginArrival(opening,brief)
 C.arrivalKind='portal'
 C.arrivalOpening=opening==true
 C.arrivalBrief=brief==true
 C.arrival=0;C.active=true;C.armed=false
 C.arrivalActor={x=player.x+15,y=player.y+8-75,targetY=player.y+8,walkMoving=false}
 C.arrivalPortal={x=player.x+15,y=player.y+8-75}
end
function C.startCountdown()
 C.active=true;C.elapsed=0;C.goAge=nil;C.countdown=3;C.armed=false
end
function C.launch()
 if C.arrival or not C.active or App.state~='playing' or Replay.playing then return false end
 C.active=false;C.goAge=0;C.countdown=nil;Audio.play('startRun')
 require('game_feedback').emit('start',player.x+15,player.y+8)
 return true
end
function C.press(binding,isrepeat)
 if C.arrival or C.countdown then return false end
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
 if C.arrival then
  local step=math.min(dt,.05);C.arrival=C.arrival+step
  local scene=C.scene()
  if scene then
   scene.advance(C.arrival)
   if App.historyPreview then
    if C.arrival>=C.arrivalDuration+2 then require('history').close() end
    return 0
   end
   if C.arrival>=C.arrivalDuration then
    if C.rememberTransition then
     Profile.transitionsSeen=Profile.transitionsSeen or {};Profile.transitionsSeen[tostring(C.rememberTransition)]=true;Profile.save();C.rememberTransition=nil
    end
    C.arrival=nil;C.arrivalKind=nil;C.launch();C.goAge=nil
   end
   return 0
  end
  local a=C.arrivalActor;local oldY=a.y
  a.y=a.targetY-75+75*smooth((C.arrival-1.4)/1.9)
  require('brown_walk').advance(a,a.y-oldY,step)
  if C.arrival>=(C.arrivalBrief and 4.9 or 12.5) and App.historyPreview then require('history').close();return 0 end
  if C.arrival>=(C.arrivalBrief and 4.9 or 12.5) then
   C.arrival=nil;C.armed=false;C.elapsed=0
   if C.arrivalPractice then C.arrivalPractice=false;C.launch();C.goAge=nil end
  end
  return 0
 end
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
-- Visual proxy only: campaign position and replay state never move during arrival.
function C.drawArrivalActor()
 if C.scene() then return end
 local t=C.arrival;local a=C.arrivalActor;local g=love.graphics
 local closing=smooth((t-3.3)/1.1);local amount=(1-closing)*(C.arrivalOpening and smooth((t-.2)/1.1) or 1)
 if amount>0 then require('prologue').drawPortal(C.arrivalPortal,amount,t) end
 if t>=3.3 and t<4.9 then
  local age=t-3.3;g.push('all');g.setShader()
  for i=1,18 do
   local angle=i*2.399;local r=12+age*28
   g.setColor(1,.92,.75,math.max(0,1-age/1.6)*.65)
   g.circle('fill',C.arrivalPortal.x+math.cos(angle)*r,C.arrivalPortal.y+math.sin(angle)*r*.7,1.3)
  end
  g.pop()
 end
 local emerge=smooth((t-1.4)/.55)
 if emerge>0 then
  g.push('all');Characters.shadow(a.x,a.y,Characters.playerWidth*(.55+.45*emerge),'down',a,emerge);g.setColor(1,1,1,emerge)
  Characters.draw(a.x,a.y,Characters.playerWidth*(.55+.45*emerge),'down',a)
  g.pop()
 end
end
function C.drawArrival()
 if C.scene() then return end
 local g=love.graphics;local t=C.arrival
 local reveal=smooth((t-.2)/(C.arrivalOpening and .6 or 1.6));local out=1-smooth((t-10.9)/1.6)
 g.push('all');g.setShader()
 -- Cover letterboxing as well as the arena during the black-to-daylight fade.
 g.setColor(.008,.005,.016,1-reveal);g.rectangle('fill',-4000,-4000,9200,8750)
 g.setColor(1,.88,.58,math.sin(reveal*math.pi)*.13);g.rectangle('fill',-4000,-4000,9200,8750)
 if C.arrivalBrief then g.pop();return end
 local title=smooth((t-.8)/1.2)*out
 UI.text('Paradis',371,83,'medium',{.05,.07,.04,.8*title},460,'center')
 UI.text('Paradis',370,82,'medium',{1,.94,.74,title},460,'center')
 g.setColor(1,.91,.65,.5*title);g.setLineWidth(1);g.line(560,116,640,116)
 local story=smooth((t-4.2)/.8)*out
 g.setColor(.025,.04,.035,.88*story);g.rectangle('fill',140,562,920,98,14)
 local text=t<8 and 'Le portail s’est refermé… Elle est passée par ici. Je dois retrouver sa trace.' or 'Elle a laissé des larmes. Je vais les suivre.'
 UI.text(text,165,582,'medium',{1,.96,.84,story},870,'center')
 g.pop()
end
function C.draw()
 if App.state~='playing' or Replay.playing then return end
 if C.arrival then C.drawArrival();return end
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
