-- Blocking HTTPS stays on a worker thread so gameplay never waits for the network.
local json=require 'json'
local requests=love.thread.getChannel('silken.requests')
local responses=love.thread.getChannel('silken.responses')
local function quote(s) return "'"..tostring(s):gsub("'", "'\\''").."'" end
while true do
    local job=requests:demand()
    if job=='quit' then break end
    local command='curl --silent --connect-timeout 3 --max-time 8 --max-filesize 131072 --proto =https -w '..quote('\n%{http_code}')
    command=command..' -X '..quote(job.method or 'GET')..' -H '..quote('Accept: application/json')
    if job.token then command=command..' -H '..quote('Authorization: Bearer '..job.token) end
    if job.body then command=command..' -H '..quote('Content-Type: application/json')..' --data-binary '..quote(json.encode(job.body)) end
    command=command..' '..quote(job.url)..' 2>/dev/null'
    local ok,result=pcall(function()
        local pipe=io.popen(command,'r')
        if not pipe then return '' end
        local text=pipe:read('*a'); pipe:close(); return text
    end)
    local body,code=(ok and result or ''):match('^(.*)\n(%d%d%d)$')
    responses:push({id=job.id,body=body or '',code=tonumber(code) or 0})
end
