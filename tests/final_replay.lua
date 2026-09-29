local T={}
function T.run()
 Online.enabled=false;Profile.save=function() end;Bestiary.save=function() end;Replay.disabled=false
 local F=require('final_spider');local V=require('victory_screen');local complete=Profile.complete
 Profile.complete=function() Replay.finish() end
 Input.move=function() return 0,0 end;Input.slow=function() return true end
 App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;App.start(3)
 local function simulation(dt)
  -- Repeat the same scripted encounter outcome inside the recorded simulation.
  if Replay.frame==20 then for i=1,20 do F.damage() end end
  if Replay.frame==180 then player.x=Arena.width*.5-15;player.y=25 end
  if Replay.frame==240 then player.x=Ending.partner.x-15;player.y=Ending.partner.y-12 end
  App.simulate(dt)
 end
 for i=1,300 do if App.state=='playing' then Replay.update(1/60,simulation) end end
 assert(App.state=='credits' and Replay.last and Replay.last.completed and #Replay.last.splits==2,'Both levels saved before credits')
 local data=Replay.last;local final=data.checks[#data.checks];assert(final[2]==2 and final[6],'Final checkpoint marks completed run')
 Ending.updateCredits(Ending.creditDuration()+1);local result=V.run
 assert(Replay.play(data));for i=1,300 do if Replay.playing then Replay.update(1/60,simulation) end end
 assert(not Replay.playing and App.state=='victory' and V.run==result,'Full final replay restores original recap')
 assert(Replay.status=='Lecture terminée.',Replay.status)
 Profile.complete=complete;print('PASS final replay: two-level recording, terminal checkpoint at credits, exact playback, restored recap');love.event.quit()
end
return T
