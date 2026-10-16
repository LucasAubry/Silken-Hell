-- Empty gameplay layout with a painted backdrop. Stable ID 6 preserves saves.
local S={}
function S.openEdges()
 return Campaign and Campaign.biome==6 and not (Secret and Secret.inArena())
end
function S.fallAt(x,y)
 return S.openEdges() and (x<22 or x>Arena.width-22 or y<22 or y>578)
end
function S.prepare(layout)
 if layout.world~=6 or (layout.skyRevision or 0)>=3 then return layout end
 layout.skyRevision=3
 -- Upgrade only the old empty defaults; keep authored maps intact.
 if #layout.entities==1 and layout.entities[1].kind=='spawn' then
  layout.entities[#layout.entities+1]={kind='mob',id='sky-dragonfly',type='dragonfly',x=layout.width*.24,y=160,speed=90}
  layout.entities[#layout.entities+1]={kind='mob',id='sky-moth',type='mist_moth',x=layout.width*.75,y=420,speed=55}
  if layout.level>=5 then layout.entities[#layout.entities+1]={kind='mob',id='sky-dragonfly-2',type='dragonfly',x=layout.width*.78,y=150,speed=100} end
 end
 local generated=true
 for _,e in ipairs(layout.entities) do if e.kind~='spawn' and not (e.id and e.id:match('^sky%-')) then generated=false end end
 if generated then
  local found=false;for _,e in ipairs(layout.entities) do if e.type=='wind_bat' then found=true end end
  if not found then layout.entities[#layout.entities+1]={kind='mob',id='sky-wind-cloud',type='wind_bat',x=layout.width*.18,y=400,speed=0} end
 end
 return layout
end
function S.draw(width,height)
 require('biome_floor').draw(6,width,height,UI and UI.clock or 0)
end
return S
