-- Independent Workshop drafts never replace campaign layouts.
local M={file='workshop_maps.json'}
function M.key(biome) return 'workshop:'..biome end
function M.blank(biome)
 return {world=biome,biome=biome,level=1,difficulty=1,width=960,height=600,entities={
  {id='spawn',kind='spawn',x=100,y=300},{id='tear',kind='tear',x=820,y=300}}}
end
function M.read()
 local raw=love.filesystem.read(M.file);if not raw then return {} end
 local ok,data=pcall(require('json').decode,raw)
 if ok and type(data)=='table' and data.version==1 and type(data.levels)=='table' then return data.levels end
 return {}
end
return M
