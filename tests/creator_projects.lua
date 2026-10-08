local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false;Replay.input=nil
 Profile.save=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 Profile.completed={[5]=true};Profile.scores={} -- Unlock Ocean explicitly; never depend on a previous test save.
 App.sessionLayout=nil;App.preview=false;App.practice=nil;App.hardcore=false;Secret.duel=nil
 local P=require('creator_projects');local B=require('creator_bridge');local json=require('json');local root=love.filesystem.getSaveDirectory()
 local project=assert(P.new(root,4,nil,1));local e=project.entries[1];e.name='Ma carte autonome';e.author='Lucas';e.difficulty=3;assert(P.save(root,project))
 local originalCampaign=love.filesystem.read('custom_levels.json')
 local function request(action,ticket) return {projectId=project.id,slot=1,ticket=ticket,action=action,hash=Replay.hash(P.layout(project,1))}end
 B.consume(request('publish','unvalidated'));assert(not Workshop.busy and not Workshop.canPublish())
 assert(P.read(root,'creator-response.json').message:find('Termine',1,true),'Publication requires completion')
 B.consume(request('validate','validation'))
 assert(App.state=='playing' and App.singleLevel and Workshop.validationRun and not App.preview,'Validation is a recorded standalone run, not editor preview')
 assert(Campaign.world==4 and player.level==1 and #App.sessionLayout.entities==2)
 local data={completed=true,single=true,world=4,startLevel=1,build=Replay.build(),layouts={['4:1']=Workshop.materialize()}}
 Workshop.validationFinished(data,'replay-id');assert(P.proof(root,project,1),'Successful run persists exact content proof')
 Workshop.resumePublication();assert(Workshop.canPublish())
 local calls={};Online.request=function(path,body,callback)
  calls[#calls+1]={path=path,body=body}
  if path=='/v1/workshop/validate' then callback({id='proof-id'},201)
  elseif path=='/v1/workshop' then callback({id='map-id-'..project.id},201)
  else callback({maps={},hasMore=false},200) end
 end
 B.consume(request('publish','publish'))
 assert(#calls==3 and calls[1].path=='/v1/workshop/validate' and calls[2].body.title==e.name and calls[2].body.author=='Lucas')
 assert(calls[2].body.layout.difficulty==3 and calls[2].body.proof=='proof-id')
 assert(P.read(root,'creator-response.json').message=='Niveau publié.')
 local ids=P.read(root,'workshop-publications.json');assert(ids['project:'..project.id..':1']=='map-id-'..project.id)
 calls={};B.consume(request('publish','publish'));assert(#calls==0,'Same request is not sent twice')
 e.layout.entities[#e.layout.entities+1]={kind='wall',x=500,y=300,w=40,h=80};P.save(root,project)
 assert(not P.proof(root,project,1),'Editing invalidates saved validation')
 B.consume(request('publish','edited'));assert(#calls==0,'An edited version cannot reuse the previous proof')
 local copy=assert(P.new(root,4,e.layout,1));assert(copy.id~=project.id and not P.proof(root,copy,1),'A copied map gets its own identity and needs validation')
 assert(love.filesystem.read('custom_levels.json')==originalCampaign,'Projects never change campaign files')
 local labels={};local button=UI.button;UI.button=function(label,...)labels[#labels+1]=label;return button(label,...)end
 App.state='workshop';Workshop.publishing=false;Workshop.rows={};Workshop.status='';love.draw();UI.button=button
 local create=false;for _,label in ipairs(labels)do assert(label~='Publier ma carte','No publication entry in Workshop menu');if label=='Créer une carte' then create=true end end;assert(create)
 print('PASS creation publication bridge: validation/replay, persistent proofs, exact metadata payload, independent publication IDs, changed/copy rejection and Workshop menu')
 local tick=0;love.update=function()tick=tick+1;if tick==2 then App.capture='creator-workshop-menu.png' elseif tick==4 then love.event.quit()end end
end
return T
