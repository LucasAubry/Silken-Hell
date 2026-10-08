-- OS-specific process launching and safe replacement of existing save files.
local P={}
function P.os() return love.system.getOS() end
function P.flag(name)
 for _,value in ipairs(arg or {}) do if value==name then return true end end
 return false
end
function P.quote(s) return "'"..tostring(s):gsub("'","'\\''").."'" end
function P.psQuote(s) return "'"..tostring(s):gsub("'","''").."'" end
function P.windowsArg(s)
 -- Windows CommandLineToArgvW / CRT quoting, including trailing backslashes.
 return '"'..s:gsub('(\\*)"',function(bs)return bs..bs..'\\"'end):gsub('(\\+)$','%1%1')..'"'
end
function P.powershell(script)
 local units={}
 local function unit(n) units[#units+1]=string.char(n%256,math.floor(n/256)) end
 for _,code in require('utf8').codes(script) do
  if code<65536 then unit(code) else code=code-65536;unit(55296+math.floor(code/1024));unit(56320+code%1024) end
 end
 return 'powershell.exe -NoLogo -NoProfile -NonInteractive -EncodedCommand '..love.data.encode('string','base64',table.concat(units))
end
function P.command(executable,args,background,system)
 system=system or P.os()
 if system=='Windows' then
  local quoted={};for _,v in ipairs(args)do quoted[#quoted+1]=P.windowsArg(v)end
  if background then
   return P.powershell("$ErrorActionPreference='Stop'; try { Start-Process -FilePath "..P.psQuote(executable)..
    " -ArgumentList "..P.psQuote(table.concat(quoted,' ')).." | Out-Null; exit 0 } catch { exit 1 }")
  end
  local values={};for _,v in ipairs(args)do values[#values+1]=P.psQuote(v)end
  return P.powershell("[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding; & "..P.psQuote(executable)..' '..table.concat(values,' ')..'; exit $LASTEXITCODE')
 end
 local values={P.quote(executable)};for _,v in ipairs(args)do values[#values+1]=P.quote(v)end
 return table.concat(values,' ')..(background and ' >/dev/null 2>&1 &' or ' 2>/dev/null')
end
function P.launch(mode,target)
 local args={}
 if not love.filesystem.isFused() then args[1]=target or os.getenv('SILKEN_ASSET_ARCHIVE') or love.filesystem.getSource() end
 args[#args+1]=mode
 local ok=os.execute(P.command(love.filesystem.getExecutablePath(),args,true))
 return ok==true or ok==0
end
function P.saveDirectory(identity)
 local old=love.filesystem.getIdentity()
 love.filesystem.setIdentity(identity);love.filesystem.createDirectory('')
 local path=love.filesystem.getSaveDirectory()
 love.filesystem.setIdentity(old)
 return path
end
local ffi,crt
local function windows()
 if ffi then return end
 ffi=require('ffi')
 ffi.cdef[[int MultiByteToWideChar(unsigned int,unsigned long,const char*,int,unsigned short*,int);
 int MoveFileExW(const unsigned short*,const unsigned short*,unsigned long);
 void *_wfopen(const unsigned short*,const unsigned short*);
 size_t fread(void*,size_t,size_t,void*); size_t fwrite(const void*,size_t,size_t,void*);
 int fclose(void*); int ferror(void*);
 long BCryptGenRandom(void*,unsigned char*,unsigned long,unsigned long);]]
 crt=ffi.load('msvcrt')
end
local function wide(s)
 windows()
 local n=ffi.C.MultiByteToWideChar(65001,0,s,-1,nil,0)
 local out=ffi.new('unsigned short[?]',n)
 ffi.C.MultiByteToWideChar(65001,0,s,-1,out,n);return out
end
function P.open(path,mode)
 if P.os()~='Windows' then return io.open(path,mode) end
 windows()
 local handle=crt._wfopen(wide(path),wide(mode))
 if handle==nil then return nil,'Impossible d’ouvrir '..path end
 local file={}
 function file:read(format)
  assert(format=='*a','Only full-file reads are supported')
  local chunks={};local buffer=ffi.new('char[65536]')
  while true do
   local n=tonumber(crt.fread(buffer,1,65536,handle))
   if n>0 then chunks[#chunks+1]=ffi.string(buffer,n) end
   if n<65536 then break end
  end
  if crt.ferror(handle)~=0 then return nil end
  return table.concat(chunks)
 end
 function file:write(data)
  if tonumber(crt.fwrite(data,1,#data,handle))~=#data then return nil,'Écriture impossible.' end
  return self
 end
 function file:close() if handle~=nil then local ok=crt.fclose(handle)==0;handle=nil;return ok end end
 return file
end
function P.randomBytes(count)
 if P.os()~='Windows' then
  local f=io.open('/dev/urandom','rb');if not f then return end
  local data=f:read(count);f:close();return data
 end
 windows()
 local buffer=ffi.new('unsigned char[?]',count)
 if ffi.load('bcrypt').BCryptGenRandom(nil,buffer,count,2)~=0 then return end
 return ffi.string(buffer,count)
end
function P.replace(from,to)
 if P.os()~='Windows' then return os.rename(from,to) end
 windows()
 if ffi.C.MoveFileExW(wide(from),wide(to),9)~=0 then return true end
 return nil,'Impossible de remplacer le fichier enregistré.'
end
return P
