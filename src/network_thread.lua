-- Curl runs on a worker; request data is never interpolated into shell code.
require('love.system');require('love.data')
love.filesystem.setRequirePath('src/?.lua;'..love.filesystem.getRequirePath())
local platform=require('platform')
local requests=love.thread.getChannel('silken.requests')
local responses=love.thread.getChannel('silken.responses')
while true do
 local job=requests:demand()
 if job=='quit' then break end
 local filename='http-'..tostring(job.id)..'.cfg'
 local ok,result=pcall(function()
  assert(love.filesystem.write(filename,require('http_command').config(job)))
  local executable=platform.os()=='Windows' and 'curl.exe' or 'curl'
  local command=platform.command(executable,{'--disable','--config',love.filesystem.getSaveDirectory()..'/'..filename},false)
  local pipe=io.popen(command,'r');if not pipe then return '' end
  local text=pipe:read('*a');pipe:close();return text
 end)
 love.filesystem.remove(filename)
 local body,code=(ok and result or ''):match('^(.*)\n(%d%d%d)%s*$')
 responses:push({id=job.id,body=body or '',code=tonumber(code) or 0})
end
