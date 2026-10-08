local T={}
function T.run(M,state,select,apply,preview)
 assert(M.workshop and M.level==1)
 local campaignBefore=love.filesystem.read('custom_levels.json')
 local project,save=M.project,M.save
 M.project=love.filesystem.getSaveDirectory();M.save=M.project
 for _,w in ipairs(require('worlds').order) do
  select(w,9);assert(M.world==w and M.level==1 and M.layout.biome==w)
  love.draw()
 end
 select(4,1);M.restore();M.add({kind='mob',type='crab',speed=130},480,300)
 assert(apply());assert(love.filesystem.getInfo('workshop_maps.json'))
 local old=os.execute;os.execute=function()return 0 end
 love.filesystem.write('preview-heartbeat.txt',tostring(os.time()));preview();os.execute=old
 local data=require('json').decode(love.filesystem.read('preview-request.json'))
 assert(data.layout.biome==4 and data.layout.level==1 and #data.layout.entities==3)
 assert(love.filesystem.read('custom_levels.json')==campaignBefore,'Workshop editor never writes campaign levels')
 local tick=0
 state.testUpdate=function()
  tick=tick+1
  if tick==2 then M.selected=nil;state.tool=nil;love.graphics.captureScreenshot('workshop-editor-biome.png')
  elseif tick==4 then M.project=project;M.save=save;print('PASS independent Workshop editor: seven biomes, save and preview without campaign writes');love.event.quit() end
 end
end
return T
