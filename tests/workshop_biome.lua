local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false;Replay.ghost=false
 Profile.save=function()end;Profile.language='fr';Profile.name='QA';App.preview=false;App.sessionLayout=nil
 local maps=require('workshop_maps');local json=require('json');local read=love.filesystem.read
 love.filesystem.createDirectory('workshop-biome-qa')
 local root=love.filesystem.getSaveDirectory()..'/workshop-biome-qa'
 love.filesystem.write('workshop-biome-qa/custom_levels.json','CAMPAIGN_UNCHANGED')
 love.filesystem.remove('workshop-biome-qa/workshop_maps.json')
 love.filesystem.read=function(path,...)
  if path=='default_levels.json' then return read('designer/default_levels.json',...) end
  if path==maps.file then return read('workshop-biome-qa/'..maps.file,...) end
  if path=='drafts.json' then return '{}' end
  return read(path,...)
 end
 local M=require('designer.model');M.init(root,root,4)
 assert(M.workshop and M.world==4 and M.level==1 and M.key()=='workshop:4')
 assert(#M.layout.entities==2 and M.layout.biome==4,'A new independent map starts with spawn and tear only')
 M.add({kind='mob',type='crab',speed=130},400,300);assert(M.apply())
 assert(read('workshop-biome-qa/custom_levels.json')=='CAMPAIGN_UNCHANGED','Saving never touches campaign layouts')
 M.select(7,10);assert(M.level==1 and #M.layout.entities==2,'Selecting a biome never selects a campaign level')
 M.add({kind='mob',type='lanternfish',speed=55},550,250);assert(M.apply())
 M.init(root,root,4);assert(#M.layout.entities==3 and M.layout.entities[3].type=='crab','Independent map survives editor restart')
 M.restore();assert(#M.layout.entities==2);M.undo(false);assert(#M.layout.entities==3,'Clear can be undone')
 Workshop.biome=4;Workshop.chooseLocal();App.state='workshop'
 assert(Workshop.selected.key=='workshop:4' and Workshop.selected.saved and #Workshop.materialize().entities==3)
 love.draw()
 local selectedCount=0
 for _,b in ipairs(UI.buttons) do
  -- All seven biomes have their own button; no campaign slot pagination.
  if b.x==125 and b.w==400 then selectedCount=selectedCount+1 end
 end
 assert(selectedCount==7,'Publication offers seven biome buttons')
 Workshop.selectBiome(5);assert(Workshop.selected.saved==false and not Workshop.materialize() and not Workshop.canPublish(),'Uncreated biome cannot be tested or published')
 local open=Creator.open;local opened
 Creator.open=function()opened=true;return true end;Workshop.edit();Creator.open=open;assert(opened,'Editor opens the project library')
 M.select(5,8);M.add({kind='mob',type='mole',speed=100},450,300);assert(M.apply())
 Workshop.reloadLocal();assert(Workshop.materialize().entities[3].type=='mole','Returning from editor picks up saved map')
 Workshop.title='Ma carte';Workshop.difficulty=3
 Workshop.validated={hash=Replay.hash(Workshop.materialize()),build=Replay.build()};assert(Workshop.canPublish())
 M.add({kind='wall',w=40,h=80},620,420);assert(M.apply());Workshop.reloadLocal()
 assert(not Workshop.canPublish(),'Changing map content invalidates its old proof')
 assert(Workshop.title=='Ma carte' and Workshop.difficulty==3,'Refreshing keeps publication fields')
 Workshop.selectBiome(4);assert(Workshop.selected.layout.entities[3].type=='crab','Biome drafts stay independent')
 local called=0;local request=Online.request
 Online.request=function()called=called+1 end
 Workshop.publish();assert(called==0,'Unvalidated map is never sent')
 Online.request=request;Workshop.status='';Workshop.focus=nil
 print('PASS Workshop biome-only creation, isolated campaign saves, restart, undo, editor handoff, refresh and validation invalidation')
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=UI.clock+.1
  if tick==2 then App.capture='workshop-biome-publication.png'
  elseif tick==5 then love.filesystem.read=read;love.event.quit() end
 end
end
return T
