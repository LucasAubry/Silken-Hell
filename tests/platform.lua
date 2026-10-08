local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false
 local P=require('platform');local root=love.filesystem.getSaveDirectory()
 local name="portabilité ' & % !.json"
 love.filesystem.write(name,'old');love.filesystem.write(name..'.new','new')
 assert(P.replace(root..'/'..name..'.new',root..'/'..name));assert(love.filesystem.read(name)=='new')
 local file=assert(P.open(root..'/'..name,'rb'));assert(file:read('*a')=='new');file:close()
 file=assert(P.open(root..'/'..name,'wb'));assert(file:write('Unicode'));file:close()
 assert(love.filesystem.read(name)=='Unicode')
 love.filesystem.remove(name)
 local entropy=assert(P.randomBytes(32));assert(#entropy==32 and entropy~=P.randomBytes(32))
 local original=love.filesystem.getIdentity()
 assert(P.saveDirectory(original)==root and love.filesystem.getIdentity()==original)
 local cfg=require('http_command').config({url='https://example.com/',body={name="éclair ' & % ! $(echo wrong)"},token='test'})
 assert(cfg:find('data-binary',1,true) and cfg:find('Content-Type',1,true))
 local cmd=P.command('C:/Program Files/LÖVE/love.exe',{'a & b',[[C:a b]],'--editor'},true,'Windows')
 assert(cmd:match('^powershell.exe .+ %-EncodedCommand [%w+/=]+$'),'Only encoded script reaches cmd.exe')
 local httpExecutable=P.httpExecutable()
 if os.getenv('SILKEN_STANDALONE_TEST')=='1' and P.os()~='OS X' then
  assert(httpExecutable:find('/network/',1,true),'Standalone packages must use their own network helper')
 end
 local pipe=assert(io.popen(P.command(httpExecutable,{'--version'},false),'r'))
 local result=pipe:read('*a');pipe:close();assert(result:find('curl',1,true),'HTTP executable must be available')
 love.filesystem.remove('platform-child.txt')
 assert(P.launch('--platform-child'),'Launch the same archive with a mode flag')
 local http
 if os.getenv('SILKEN_PLATFORM_HTTP_TEST')=='1' then
  http=love.thread.newThread('src/network_thread.lua');http:start()
  love.thread.getChannel('silken.requests'):push({id=991,url=require('online_config').url..'/v1/location'})
 end
 local httpDone=not http
 local elapsed=0
 love.update=function(dt)
  elapsed=elapsed+dt
  if http and not httpDone then
   assert(not http:getError(),http:getError())
   local response=love.thread.getChannel('silken.responses'):pop()
   if response then
    assert(response.code==200 and require('json').decode(response.body).country,'HTTPS thread must return valid JSON')
    love.thread.getChannel('silken.requests'):push('quit');httpDone=true
   end
  end
  if httpDone and love.filesystem.read('platform-child.txt')=='ok' then
   love.filesystem.remove('platform-child.txt')
   print('PASS native platform: atomic Unicode replacement, save identity, HTTP process, child process ('..P.os()..')')
   love.event.quit()
  elseif elapsed>30 then error('Child process did not start') end
 end
end
return T
