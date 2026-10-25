-- Complete authored sprites: body and accessories live in the same PNG.
local S={names={[6]='aureole',[8]='ambre',[9]='corail',[11]='cendre',[27]='amir'}}
function S.load(art)
 local metadata=require('json').decode(love.filesystem.read('assets/skins/integrated/frames.json'))
 for name,entry in pairs(metadata) do
  for pose,f in pairs(entry.frames) do
   local key='player_skin_'..name..'_'..pose
   local function load()
    local image=require('art_filter').image(f.path or entry.path)
    return {image=image,quad=love.graphics.newQuad(f.x,f.y,f.w,f.h,image:getDimensions()),w=f.w,h=f.h,renderScale=f.renderScale}
   end
   if art.defer then art.register(key,load) else art.images[key]=load() end
  end
 end
end
function S.bubble(index)
 index=Characters.crowned[index] or index
 return index==9
end
function S.hideMarineOverlay(index)
 index=Characters.crowned[index] or index
 return index==4 or index==10
end
return S
