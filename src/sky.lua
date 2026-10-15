-- Empty gameplay layout with a painted backdrop. Stable ID 6 preserves saves.
local S={}
function S.prepare(layout)
 if layout.world~=6 or layout.skyRevision==1 then return layout end
 layout.skyRevision=1
 layout.entities={{kind='spawn',id='spawn',x=layout.width/2,y=300}}
 return layout
end
function S.draw(width,height)
 require('biome_floor').draw(6,width,height,UI and UI.clock or 0)
end
return S
