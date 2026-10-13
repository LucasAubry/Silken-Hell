local M={thumbnails={}}

function M.slots()
 local slots={}
 for index,a in ipairs(Achievements.list) do
  if a.trophy then slots[#slots+1]={achievement=a,achievementIndex=index} end
 end
 local width,height,gap=28,32,24
 local left=600-(#slots*width+math.max(0,#slots-1)*gap)/2
 for index,slot in ipairs(slots) do
  slot.x=left+(index-1)*(width+gap);slot.y=455;slot.w=width;slot.h=height
 end
 return slots
end

function M.thumbnail(a)
 local key=require('achievements_screen').trophy(a)
 local art=key and Art.images[key]
 if not art then return nil end
 local thumbnail=M.thumbnails[key]
 if not thumbnail then
  -- Share the crisp pixel-art texture with the achievement gallery.
  local path=require('asset_paths').resolve('assets/ui/achievements/'..a.trophy..'.png')
  local image=require('art_filter').image(path)
  thumbnail={image=image,quad=art.quad,w=art.w,h=art.h}
  M.thumbnails[key]=thumbnail
 end
 return thumbnail
end

function M.draw(tint)
 local g,U=love.graphics,UI
 local gallery=require('achievements_screen')
 local mx,my=U.mouse()
 tint=tint or {.82,.72,.49}
 g.push('all');g.setShader();g.setBlendMode('alpha');g.setLineWidth(1)
 for _,slot in ipairs(M.slots()) do
  local a=slot.achievement
  local done=Achievements.unlocked(a)
  local cx,cy=slot.x+slot.w/2,slot.y+slot.h/2
  local hitX,hitY=cx-22,cy-22
  local hover=Input.active and Input.index==#U.buttons+1
   or not Input.active and mx>=hitX and mx<=hitX+44 and my>=hitY and my<=hitY+44
  local hex={cx,slot.y,slot.x+slot.w,cy-slot.h/4,slot.x+slot.w,cy+slot.h/4,
   cx,slot.y+slot.h,slot.x,cy+slot.h/4,slot.x,cy-slot.h/4}
  g.setColor(.025,.045,.06,.82);g.polygon('fill',hex)
  g.setColor(tint[1],tint[2],tint[3],hover and 1 or done and .72 or .32)
  g.polygon('line',hex)
  -- The trophy sits in front of its smaller case and extends above the rim.
  do
   local trophy=M.thumbnail(a)
   if trophy then
    local scale=40/math.max(trophy.w,trophy.h)
    g.setColor(1,1,1)
    if not done then require('locked_art').bind() end
    g.draw(trophy.image,trophy.quad,cx,cy-5,0,scale,scale,trophy.w/2,trophy.h/2)
    g.setShader()
    if not done then require('locked_art').question(cx,cy-5,40) end
   end
  end
  U.buttons[#U.buttons+1]={x=hitX,y=hitY,w=44,h=44,trophyId=a.id,
   run=function()gallery.index=slot.achievementIndex;gallery.open()end,sound='go'}
 end
 g.pop()
end

return M
