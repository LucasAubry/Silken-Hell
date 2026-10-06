local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.playing=false
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Profile.completed={};Profile.scores={};Profile.achievements={};Profile.character=1;Hardcore.completed={}
 local R=require('skin_unlock');R.init();App.state='menu'
 local function icon()
  UI.draw();for _,b in ipairs(UI.buttons)do if b.radius then return b end end
 end
 assert(not icon(),'No variant icon before unlocking')
 Profile.completed[1]=true;Profile.character=6;assert(not icon(),'Locked gold variant stays hidden')
 Hardcore.completed['1']=true;local b=assert(icon(),'Unlocked variant has a round button')
 assert(b.w==32 and b.h==32)
 assert(not UI.click(b.x,b.y),'Corners outside circular hit target do not activate')
 assert(UI.click(b.x+16,b.y+16));UI.updatePress(.12)
 assert(Profile.character==15,'Round icon equips the gold variant')
 b=icon();UI.click(b.x+16,b.y+16);UI.updatePress(.12);assert(Profile.character==6,'Round icon restores classic')
 R.init();R.observe();assert(#R.queue==0,'Existing rewards are not announced again on launch')
 App.state='playing';Profile.completed[6]=true;R.scanTime=0;R.update(.01)
 assert(#R.queue==1 and not R.active and App.state=='playing','Unlock queues without interrupting gameplay')
 App.state='credits';R.update(.3);assert(not R.active,'Credits finish before reveal')
 App.state='victory';R.update(.01);assert(R.active.index==7 and App.state=='skinUnlock')
 assert(not R.close(),'Cannot dismiss before reveal')
 love.keypressed('escape');assert(R.active,'Escape cannot bypass suspense')
 R.update(3.3);assert(R.close(true) and Profile.character==7 and App.state=='victory','Real reward can be equipped and resumes results')
 R.observe();assert(#R.queue==0,'Unlock only announces once')
 Hardcore.completed['6']=true;R.scanTime=0;R.update(.01)
 assert(R.active.index==16,'Hardcore reward triggers the same reveal');R.update(3.3);R.close()
 local function snapshot()
  local values={tostring(Profile.character)}
  for n,map in ipairs({Profile.completed,Profile.achievements,Hardcore.completed})do
   for k,v in pairs(map)do values[#values+1]=n..':'..tostring(k)..':'..tostring(v)end
  end
  table.sort(values);return table.concat(values,'|')
 end
 local before=snapshot()
 local random=love.math.getRandomState();App.state='menu';R.test()
 assert(R.active.preview and R.active.index>=6 and R.active.index<=22)
 R.update(3.4);R.close(true)
 assert(before==snapshot(),'Preview never unlocks or equips a skin')
 assert(random==love.math.getRandomState(),'Preview leaves gameplay RNG intact')
 Profile.completed={};Profile.scores={};Profile.achievements={};Hardcore.completed={};R.init()
 for _,world in ipairs(Worlds.order)do Profile.completed[world]=true;Hardcore.completed[tostring(world)]=true end
 Profile.achievements={gillou=true,maxance=true};R.observe()
 assert(#R.queue==17,'Every earnable classic, achievement and gold skin is queued')
 local earned={};for _,index in ipairs(R.queue)do assert(not earned[index]);earned[index]=true end
 for index=6,22 do assert(earned[index],'Unlock animation covers skin '..index) end
 R.init()
 App.state='menu';Profile.character=15
 local tick=0;local draw=love.draw
 local function capture(name)
  love.graphics.captureScreenshot(function(data)local f=assert(io.open('/tmp/silken-unlock-'..name..'.png','wb'));f:write(data:encode('png'):getString());f:close()end)
 end
 love.update=function()
  tick=tick+1;UI.clock=4
  if tick==2 then R.open(16,true);R.update(1.5)
  elseif tick==3 then R.update(1.2)
  elseif tick==4 then R.update(1.3)
  elseif tick==5 then Graphics.effects=false end
 end
 local names={'menu','suspense','reveal','complete','reduced-effects'}
 love.draw=function()
  draw();if names[tick]then capture(names[tick])end
  if tick>=6 then print('PASS circular variant toggle and visibility; queued real/hardcore unlocks; credits and input gating; one-shot rewards; preview without save/RNG changes; reveal captures');love.event.quit()end
 end
end
return T
