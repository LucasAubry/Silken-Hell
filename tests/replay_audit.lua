-- Optional read-only audit: fixtures live in the isolated test save, not the repo.
local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=false;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 local json=require 'json';local records=json.decode(assert(love.filesystem.read('history-fixtures.json')));local report={}
 for _,data in ipairs(records) do
  print('AUDIT '..data.build:sub(1,12)..' world='..data.world..' frames='..data.frames)
  local started=Replay.play(data);local drawn=false
  while started and Replay.playing do
   Replay.speed=8;Replay.update(.25,App.simulate)
   if Replay.legacy and not Replay.recovery and not drawn then love.draw();drawn=true end
  end
  report[#report+1]={build=data.build,status=Replay.status,matched=Replay.verified and Replay.verified.choice.engine.revision,mismatch=Replay.lastMismatch}
  print('RESULT '..data.build:sub(1,12)..' '..Replay.status)
  love.filesystem.write('history-audit.json',json.encode(report))
 end
 print('PASS archive audit completed');love.event.quit()
end
return T
