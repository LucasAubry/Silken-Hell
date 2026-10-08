local P=require('creator_projects')
local B={clock=0}
function B.respond(message,ticket)
 if B.ticket or ticket then P.write(love.filesystem.getSaveDirectory(),'creator-response.json',{ticket=ticket or B.ticket,message=message}) end
end
function B.consume(request)
 local root=love.filesystem.getSaveDirectory()
 if type(request)~='table' or type(request.ticket)~='string' or request.ticket==B.last then return end
 B.last=request.ticket;B.ticket=request.ticket
 if Workshop.busy then B.respond('Une publication est déjà en cours.');return end
 if request.action~='validate' and request.action~='publish' then B.respond('Action inconnue.');return end
 local project,err=P.load(root,request.projectId)
 local slot=request.slot
 if not project or type(slot)~='number' or slot%1~=0 or not project.entries[slot] then B.respond(err or 'Niveau introuvable.');return end
 local layout=P.layout(project,slot);local ok,why=LayoutSchema.validate(layout)
 if not ok then B.respond(why);return end
 if request.hash~=Replay.hash(layout) then B.respond('La carte a changé. Relance la validation.');return end
 -- Snapshot the exact saved project version requested by the editor.
 local e=project.entries[slot]
 Workshop.selected={key='project:'..project.id..':'..slot,layout=layout,saved=true}
 Workshop.biome=layout.biome;Workshop.difficulty=e.difficulty;Workshop.difficultyExtra=tostring(e.difficultyExtra or 0)
 Workshop.title=e.name;Workshop.author=e.author;Workshop.editorProject={id=project.id,slot=slot,ticket=request.ticket}
 Workshop.validated=P.proof(root,project,slot);Workshop.publishing=true;Workshop.status=''
 if request.action=='validate' then
  Replay.playing=false;Replay.ghost=false;Replay.recording=false;Replay.input=nil
  if Workshop.testPublication() then B.respond('Termine la carte dans le jeu.')else B.respond(Workshop.status)end
 else
  App.state='workshop';local started=Workshop.publish()
  if not started then B.respond(Workshop.status) end
 end
end
function B.update(dt)
 if os.getenv('SILKEN_CREATOR_BRIDGE')~='1' then return end
 B.clock=B.clock+dt;if B.clock<.2 then return end;B.clock=0
 local root=love.filesystem.getSaveDirectory();P.write(root,'creator-heartbeat.json',{time=os.time()})
 local r=P.read(root,'creator-request.json');if r then os.remove(root..'/creator-request.json');B.consume(r) end
end
return B
