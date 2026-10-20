-- Sort the lower trunk with actors; keep the canopy above their complete silhouette.
local T={}
-- name, height in spider widths, canopy cut, trunk anchor X/Y, trunk half-width.
local species={{'oak',3.3,.70,.55,.91,.08},{'birch',3.8,.74,.52,.945,.045},{'maple',3.5,.72,.60,.945,.05}}
function T.load()
 if T.shader then return end
 for _,v in ipairs(species) do Art.add('prologue_tree_'..v[1],'assets/prologue/tree_'..v[1]..'.png') end
 T.shader=love.graphics.newShader([[
 vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  vec4 p=Texel(tex,uv); if(p.a<0.80) discard;
  return vec4(p.rgb,1.0)*color;
 }
 ]])
end
function T.geometry(i,width,height)
 local p=require('prologue_terrain').trees[i];local v=species[(i-1)%3+1]
 local h=Characters.playerWidth*v[2]*(.92+(i%4)*.045)
 local art=Art.images['prologue_tree_'..v[1]]
 local spriteWidth=h*art.w/art.h
 return {x=p[1]*width/1200,y=p[2]*height/750,h=h,species=v,index=i,
  rx=spriteWidth*v[6]+Characters.playerWidth*.14,ry=h*.025+Characters.playerWidth*.10}
end
function T.blocked(x,y,width,height)
 for i=1,#require('prologue_terrain').trees do
  local t=T.geometry(i,width,height)
  -- Collide at the visible trunk's foot, not the image's padded bottom centre.
  if ((x-t.x)/t.rx)^2+((y-t.y+5)/t.ry)^2<1 then return true end
 end
 return false
end
function T.drawPart(t,upper,clock)
 local g=love.graphics;local a=Art.images['prologue_tree_'..t.species[1]]
 if not a.treeParts then
  local x,y,w,h=a.quad:getViewport();local cut=math.floor(h*t.species[3]);local iw,ih=a.image:getDimensions()
  a.treeParts={g.newQuad(x,y,w,cut,iw,ih),g.newQuad(x,y+cut,w,h-cut,iw,ih),cut=cut}
 end
 local s=t.h/a.h;local cut=a.treeParts.cut
 g.push('all');g.setShader(T.shader);g.setColor(.94,.94,.88)
 -- A tiny shear moves the upper branches while keeping the roots planted.
 g.translate(t.x,t.y);g.shear(math.sin(clock*.8+t.index)*.006,0)
 g.draw(a.image,a.treeParts[upper and 1 or 2],0,(upper and -a.h*t.species[5] or cut-a.h*t.species[5])*s,0,s,s,a.w*t.species[4],0)
 g.pop()
end
function T.drawScene(actors,width,height,clock)
 T.load();local trees={}
 for i=1,#require('prologue_terrain').trees do
  local t=T.geometry(i,width,height);trees[#trees+1]=t
  actors[#actors+1]={y=t.y,draw=function()T.drawPart(t,false,clock)end}
 end
 table.sort(actors,function(a,b)return a.y<b.y end)
 for _,a in ipairs(actors) do a.draw() end
 table.sort(trees,function(a,b)return a.y<b.y end)
 for _,t in ipairs(trees) do T.drawPart(t,true,clock) end
end
return T
