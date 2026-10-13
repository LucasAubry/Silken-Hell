-- One achievement at a time: its reward, or its own pixel-art trophy.
local S={index=1}
local white={.94,.94,.91}
local muted={.66,.69,.76}
local gold={.88,.77,.51}
local Motion=require('ui_motion')

function S.current()
 local list=Achievements.list
 if #list==0 then S.index=1;return nil end
 S.index=((S.index or 1)-1)%#list+1
 return list[S.index]
end
function S.count()
 local earned=0
 for _,a in ipairs(Achievements.list) do if Achievements.unlocked(a) then earned=earned+1 end end
 return earned,#Achievements.list
end
function S.step(amount)
 if amount==0 or #Achievements.list==0 then return end
 local previous=S.current()
 local direction=amount>0 and 1 or -1
 S.outgoing={achievement=previous,offset=S.dropOffset(),at=UI.clock,direction=direction}
 S.direction=direction
 S.index=((S.index or 1)-1+amount)%#Achievements.list+1
 S.changedAt=UI.clock
end
function S.move(amount) if amount~=0 then S.step(amount>0 and 1 or -1) end end
function S.open()
 S.current();S.changedAt=nil;S.outgoing=nil;S.direction=1
 App.state='achievements';UI.pressed=nil;Input.index=1
end
function S.dropOffset()
 if not S.changedAt or not Motion.enabled() then return 0 end
 local age=math.max(0,UI.clock-S.changedAt)
 local direction=S.direction or 1
 if age<.44 then return -460*(1-(age/.44)^2)*direction end
 if age<.58 then
  local bounce=(age-.44)/.14
  return -12*math.sin(bounce*math.pi)*(1-bounce)*direction
 end
 return 0
end
function S.trophy(a)
 if not a.trophy then return nil end
 local key='achievement_'..a.trophy
 if not Art.images[key] then Art.add(key,'assets/ui/achievements/'..a.trophy..'.png') end
 return key
end

local function content(a,x,y,size)
 local g=love.graphics;g.setColor(1,1,1)
 if a.rewardSkin then
  Characters.portrait(a.rewardSkin,x,y,size,'down')
 elseif a.rewardEffect then
  require('skin_effects').icon(a.rewardEffect,x,y,size/2,1,true)
 else
  local key=S.trophy(a);local art=key and Art.images[key]
  if art then Art.draw(key,x,y,size*art.w/math.max(art.w,art.h)) end
 end
end
function S.reward(a,done,x,y,size)
 if not a then return end
 local g=love.graphics;size=size or 330
 g.push('all');g.setShader();g.setBlendMode('alpha');g.setColor(1,1,1)
 if done then content(a,x,y,size)
 else
  -- Use alpha only: no eyes, markings or shading reveal a locked reward.
  S.lockedCanvas=S.lockedCanvas or g.newCanvas(896,896,{dpiscale=1})
  local filter=a.trophy and 'nearest' or 'linear'
  S.lockedCanvas:setFilter(filter,filter)
  local clipX,clipY,clipW,clipH=g.getScissor()
  g.push('all');g.setCanvas(S.lockedCanvas);g.origin();g.setScissor();g.clear(0,0,0,0)
  content(a,448,448,size);g.pop()
  -- Reapply after returning to the window: its scissor Y origin differs from a canvas.
  g.setScissor()
  if clipX then g.setScissor(clipX,clipY,clipW,clipH) end
  S.lockedShader=S.lockedShader or g.newShader([[
   vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel) {
    vec4 p=Texel(image,uv);
    float alpha=step(.12,p.a);
    return vec4(0.,0.,0.,alpha)*color;
   }
  ]])
  g.setShader(S.lockedShader);g.setBlendMode('alpha','premultiplied')
  g.draw(S.lockedCanvas,x,y,0,1,1,448,448)
  require('locked_art').question(x,y,size)
 end
 g.pop()
end

local function galleryReward(a,offset)
 local reward=a.rewardSkin or a.rewardEffect
 S.reward(a,Achievements.unlocked(a),600,(reward and 350 or 340)+offset,reward and 328 or 390)
end
function S.drawRewards(a)
 local g=love.graphics
 g.push('all')
 -- Falling art stays inside the showcase, clear of the name and controls.
 local x,y=g.transformPoint(388,126);local right,bottom=g.transformPoint(812,542)
 g.intersectScissor(x,y,right-x,bottom-y)
 local outgoing=S.outgoing
 if outgoing and Motion.enabled() then
  local age=math.max(0,UI.clock-outgoing.at)
  if age<.46 then galleryReward(outgoing.achievement,outgoing.offset+outgoing.direction*1100*(age/.46)^2)
  else S.outgoing=nil end
 end
 galleryReward(a,S.dropOffset())
 g.pop()
end
local function tearIcon(x,y)
 require('difficulty_tears').draw(1,x,y-4.5,0,12)
end
local function condition(a,done)
 local U=UI;local L=require('localization');local font=U.fonts.body
 local description=L.render(a.description and a.description() or '')
 local status=L.render(done and 'Obtenu' or 'Verrouillé')
 local statusWidth=font:getWidth(status)
 if description=='' then
  U.rawText(status,600-statusWidth/2,600,'body',done and gold or muted)
  return
 end
 local gap=24
 local width=math.min(font:getWidth(description),920-statusWidth-gap)
 local _,lines=font:getWrap(description,width)
 local lineHeight=font:getHeight()*font:getLineHeight()
 local height=font:getHeight()+math.max(0,#lines-1)*lineHeight
 local x=600-(width+gap+statusWidth)/2
 U.rawText(description,x,615-height/2,'body',white,width)
 U.rawText(status,x+width+gap,615-font:getHeight()/2,'body',done and gold or muted)
end
local function arrow(step,x,y)
 local U,g=UI,love.graphics;local w,h=76,76
 local mx,my=U.mouse()
 local hover=Input.active and Input.index==#U.buttons+1 or not Input.active and mx>=x and mx<=x+w and my>=y and my<=y+h
 local cx,cy=x+w/2,y+h/2
 if hover then
  g.setColor(.23,.23,.32,.85);g.circle('fill',cx,cy,30)
  g.setColor(gold);g.setLineWidth(1);g.circle('line',cx,cy,30)
 end
 g.setColor(hover and gold or white);g.setLineWidth(3);g.setLineJoin('bevel')
 g.line(cx-step*13,cy,cx+step*13,cy)
 g.line(cx+step*2,cy-12,cx+step*14,cy,cx+step*2,cy+12)
 U.buttons[#U.buttons+1]={x=x,y=y,w=w,h=h,radius=38,achievementStep=step,
  run=function()S.step(step)end,sound='go'}
end
function S.draw()
 local U,g=UI,love.graphics;local a=S.current();local earned,total=S.count()
 g.push('all');U.panel(80,42,1040,603)
 U.text('SUCCÈS',400,61,'heading',white,400,'center')
 tearIcon(139,348)
 U.rawText(earned..'/'..total,165,329,'heading',white,150)
 if a then
  local done=Achievements.unlocked(a)
  S.drawRewards(a)
  local title=require('localization').render(a.localizedName and a.localizedName() or a.name)
  U.rawText(U.ellipsize(title,'heading',650),275,554,'heading',white,650,'center')
  condition(a,done)
 end
 arrow(-1,309,322);arrow(1,815,322)
 U.button('Statistiques',240,674,220,42,function()App.state='statistics';Input.index=1 end,false,false,nil,false,gold)
 U.button('Retour',485,674,230,42,function()App.state='menu';Input.index=1 end,false,false,nil,false,gold)
 U.button('Premières places',740,674,220,42,function()require('top_records').open()end,false,false,nil,false,gold)
 g.pop()
end
return S
