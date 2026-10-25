-- Local diagnostics only: bounded action history and the last twenty reports.
local R={events={},serial=0}
function R.note(kind,detail)
 local text=tostring(kind)..' '..tostring(detail or '')
 R.events[#R.events+1]=os.date('%H:%M:%S')..' '..text:sub(1,240)
 if #R.events>50 then table.remove(R.events,1) end
end
local function context()
 local entry=UI and Bestiary and Bestiary.entries[UI.bestSelected or 0]
 local rows={
  'time='..os.date('%Y-%m-%d %H:%M:%S'),
  'version='..tostring(require('version')),
  'screen='..tostring(App and App.state),
  'world='..tostring(Campaign and Campaign.world)..' level='..tostring(player and player.level),
  'bestiary='..tostring(entry and entry.id)..' category='..tostring(UI and UI.bestCategory)..' page='..tostring(UI and UI.bestPage),
  'skin='..tostring(Profile and Profile.character),
  'practice='..tostring(App and App.practice)..' history='..tostring(App and App.historyPreview)..' replay='..tostring(Replay and Replay.playing),
  'system='..tostring(love.system and love.system.getOS())..' lua='..tostring(_VERSION),
 }
 return table.concat(rows,'\n')
end
function R.write(message,trace)
 local ok,result=pcall(function()
  love.filesystem.createDirectory('crashes')
  R.serial=R.serial+1
  local stamp=os.date('%Y%m%d-%H%M%S')
  local name=string.format('crashes/%s-%03d.log',stamp,R.serial)
  while love.filesystem.getInfo(name) do R.serial=R.serial+1;name=string.format('crashes/%s-%03d.log',stamp,R.serial) end
  local report=context()..'\n\nERROR\n'..tostring(message)..'\n'..tostring(trace or debug.traceback('',2))..'\n\nRECENT ACTIONS\n'..table.concat(R.events,'\n')..'\n'
  assert(love.filesystem.write(name,report))
  assert(love.filesystem.write('last-crash.log',report))
  local files={}
  for _,file in ipairs(love.filesystem.getDirectoryItems('crashes')) do
   if file:match('^%d%d%d%d%d%d%d%d%-%d%d%d%d%d%d%-%d+%.log$') then files[#files+1]=file end
  end
  table.sort(files)
  for i=1,math.max(0,#files-20) do love.filesystem.remove('crashes/'..files[i]) end
  return name
 end)
 if not ok then pcall(function()io.stderr:write('Crash log failed: '..tostring(result)..'\n')end);return nil,result end
 return result
end
function R.install()
 if R.handler and love.errorhandler==R.handler then return end
 local previous=love.errorhandler or love.errhand
 R.handler=function(message)
  local trace=debug.traceback('',2)
  R.write(message,trace)
  if os.getenv('SILKEN_TEST')=='1' then io.stderr:write(tostring(message)..'\n'..trace..'\n');io.stderr:flush();os.exit(1) end
  if previous then return previous(message) end
  return function()return 1 end
 end
 love.errorhandler=R.handler
end
return R
