local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false
 Profile.language='fr';Profile.completed={};Profile.levels={}
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Profile.levels[w]=10 end
 local g=love.graphics;local Motion=require('ui_motion');local canvas=g.newCanvas(1200,750)
 App.state='menu';WorldMap.hardcore=true;Hardcore.borderState=nil
 local function border(time)
  UI.clock=time;g.setCanvas(canvas);g.clear(0,0,0,0);Hardcore.drawBorder(1200,750);g.setCanvas();return canvas:newImageData()
 end
 local function alpha(data,x,y) local _,_,_,a=data:getPixel(x,y);return a end
 border(0);border(.7);WorldMap.hardcore=false
 local start=border(.7);assert(alpha(start,1,375)>.5,'Deactivation starts from the complete border')
 local mid=border(.95)
 assert(alpha(mid,1,375)<.01 and alpha(mid,600,1)>.5 and alpha(mid,600,748)>.5,'Extinction reaches side centers before top/bottom centers')
 local finish=border(1.36)
 assert(alpha(finish,600,1)<.01 and alpha(finish,600,748)<.01,'Extinction finishes with no glowing center left')
 -- Reversals keep exactly the current progress, even half way through ignition.
 WorldMap.hardcore=true;border(2);border(2.22);local progress=Hardcore.borderState.value
 WorldMap.hardcore=false;border(2.22);assert(Hardcore.borderState.value==progress,'No snap when turning off early')
 border(2.3);assert(Hardcore.borderState.value<progress);progress=Hardcore.borderState.value
 WorldMap.hardcore=true;border(2.3);assert(Hardcore.borderState.value==progress,'No snap when turning back on')
 border(3);assert(Hardcore.borderState.value==1)
 local function hover(hz)
  UI.clock=0;Motion.state=nil;Motion.values={};Graphics.effects=true
  Motion.focus('sample',true)
  for i=1,hz do UI.clock=i/hz;Motion.focus('sample',true) end
  return Motion.values.sample.value
 end
 assert(math.abs(hover(30)-hover(144))<.000001,'Hover speed is independent of frame rate')
 -- Visual offsets never move the clickable area or defer an action.
 App.state='settings';Input.active=false;UI.clock=5;local calls=0
 UI.buttons={};UI.button('Feedback',100,100,200,40,function()calls=calls+1 end)
 UI.click(101,139);assert(calls==1,'Click runs immediately on the original boundary')
 UI.clock=5.08;UI.buttons={};UI.button('Feedback',100,100,200,40,function()calls=calls+1 end)
 assert(UI.buttons[1].y==100 and Motion.pressAmount(Motion.key(100,100,200,40))>0,'Press animation preserves hitbox')
 UI.buttons={};UI.button('Feedback',100,100,200,40,function()calls=calls+1 end,true)
 UI.click(110,110);assert(calls==1,'Disabled controls remain inert')
 Graphics.effects=false;assert(Motion.pressAmount(Motion.key(100,100,200,40))==0 and Motion.reveal(5,.2)==1,'Decorative effects setting suppresses extra motion')
 Graphics.effects=true;UI.clock=8;Motion.prepare();assert(next(Motion.values)==nil,'Old animation entries are released')
 local previousPad=Input.pad;local pad={isGamepad=function()return true end}
 UI.buttons={};UI.button('Feedback',100,100,200,40,function()calls=calls+1 end)
 Input.index=1;Input.press(pad,'a');assert(calls==2,'Gamepad confirmation stays immediate')
 Input.pad=previousPad;Input.active=false
 -- Vote feedback is only attached to an accepted response, and survives refresh.
 local row={id='vote-qa',title='Les fils dorés',author='QA',biome=3,world=3,difficulty=3,starred=false,stars=0}
 local pending,requestCount;requestCount=0
 Online.request=function(path,body,callback)
  requestCount=requestCount+1
  if body then pending=callback else callback({maps={row}},200) end
 end
 Workshop.rows={row};Workshop.busy=false;App.state='workshop'
 Workshop.star(row);Workshop.star(row)
 assert(requestCount==1 and row.voting and not Workshop.voteFeedback,'One pending vote, without premature celebration')
 pending({error='offline'},503)
 assert(not Workshop.voteFeedback and not row.starred and row.stars==0,'Failed votes do not celebrate or change counts')
 Workshop.star(row);pending({starred=true,stars=1},200)
 assert(Workshop.voteFeedback.id==row.id and Workshop.voteFeedback.added and row.stars==1 and not row.voting,'Accepted vote celebrates')
 Workshop.star(row);pending({starred=false,stars=0},200)
 assert(not Workshop.voteFeedback.added and row.stars==0,'Removing a vote uses the reverse feedback')
 App.selectedWorld=1;WorldMap.hardcore=false;WorldMap.open();WorldMap.select(Worlds.order[2],2)
 for _=1,120 do UI.clock=UI.clock+1/60;WorldMap.update(1/60) end
 assert(WorldMap.arrival and #WorldMap.route==0,'Arrival feedback waits for the marker to arrive')
 print('PASS UI feedback: reverse border, interrupted toggles, frame-rate independence, hitboxes, immediate/disabled clicks, reduced effects, confirmed/rejected votes, map arrival')
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=20+tick*.1
  if tick==1 then App.state='menu';App.selectedWorld=1;WorldMap.hardcore=true;Hardcore.borderState={value=1,target=1,at=UI.clock}
  elseif tick==2 then WorldMap.hardcore=false;App.capture='feedback-extinction-full.png'
  elseif tick==4 then App.capture='feedback-extinction-sides.png'
  elseif tick==6 then App.capture='feedback-extinction-centers.png'
  elseif tick==9 then App.capture='feedback-extinction-off.png'
  elseif tick==10 then Workshop.publishing=false;Workshop.status='Une étoile = un vote positif.';App.state='workshop';Workshop.rows={row};Workshop.dropdown=nil
  elseif tick==11 then UI.click(270,213)
  elseif tick==12 then App.capture='feedback-dropdown-reveal.png'
  elseif tick==13 then App.capture='feedback-dropdown-open.png'
  elseif tick==14 then love.keypressed('escape');Workshop.star(row);pending({starred=true,stars=1},200)
  elseif tick==15 then App.capture='feedback-vote.png'
  elseif tick==16 then WorldMap.open();WorldMap.arrival={x=WorldMap.x,y=WorldMap.y,at=UI.clock-.1};App.capture='feedback-world-arrival.png'
  elseif tick==17 then print('PASS feedback captures');love.event.quit() end
 end
end
return T
