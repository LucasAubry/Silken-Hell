local H={}
local function value(s)
 return '"'..tostring(s):gsub('\\','\\\\'):gsub('"','\\"'):gsub('\r','\\r'):gsub('\n','\\n'):gsub('\t','\\t')..'"'
end
function H.config(job)
 local lines={'silent','connect-timeout = 3','max-time = 8','max-filesize = 131072','proto = "=https"',
  'write-out = "\\n%{http_code}"','request = '..value(job.method or 'GET'),
  'header = "Accept: application/json"','url = '..value(job.url)}
 if job.token then lines[#lines+1]='header = '..value('Authorization: Bearer '..job.token) end
 if job.body then
  lines[#lines+1]='header = "Content-Type: application/json"'
  lines[#lines+1]='data-binary = '..value(require('json').encode(job.body))
 end
 return table.concat(lines,'\n')
end
return H
