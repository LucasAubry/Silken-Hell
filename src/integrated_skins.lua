-- Complete authored sprites: body and accessories live in the same PNG.
local S={names={[4]='ecume',[6]='aureole',[8]='ambre',[9]='corail',[11]='cendre'}}
function S.load(art)
 local metadata=require('json').decode(love.filesystem.read('assets/skins/integrated/frames.json'))
 for name,entry in pairs(metadata) do
  for pose,f in pairs(entry.frames) do
   local image=require('art_filter').image(f.path or entry.path)
   art.images['player_skin_'..name..'_'..pose]={image=image,
    quad=love.graphics.newQuad(f.x,f.y,f.w,f.h,image:getDimensions()),w=f.w,h=f.h,renderScale=f.renderScale}
  end
 end
end
function S.bubble(index)
 index=Characters.crowned[index] or index
 return index==4 or index==9
end
return S
