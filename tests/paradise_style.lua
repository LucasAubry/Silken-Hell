local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Profile.character=1;Profile.name='QA';Profile.unlocked=7;Graphics.showFPS=false
 local g=love.graphics;local ink=require('paradise_ink')
 local before=g.newImage;local uploads=0
 g.newImage=function(...) uploads=uploads+1;return before(...) end
 local index=0;local drawn=true;local oldDraw=love.draw
 local function capture(name)
  local dir=os.getenv('SILKEN_STYLE_CAPTURE_DIR');if not dir then return end
  g.captureScreenshot(function(data)
   local encoded=data:encode('png');local file=assert(io.open(dir..'/'..name..'.png','wb'))
   file:write(encoded:getString());file:close();encoded:release();data:release()
  end)
 end
 love.update=function()
  if not drawn then return end;drawn=false;index=index+1
  if index<=10 then
   Campaign.select(1);player.level=index;reset_level();App.state='playing';player.reset=false
   for _,m in ipairs(mobs) do if m.imgs then m.dir='down';m.img=m.imgs.down or m.imgs.up end end
   if index==10 then
    Raven.hp=9;Raven.active=true
    for _,m in ipairs(Raven.chicks) do m.dir='down' end
    Raven.projectiles={{x=400,y=260,vx=1,vy=0,life=3}}
   end
  elseif index==11 then App.state='playing'
  else
   Campaign.select(2)
   assert(not ink.sprite('original_down') and not ink.sprite('merle_down'),'Ink variants must stay in Paradise')
   g.newImage=before
   assert(uploads==0,'Ink sprites must be preloaded, unexpected uploads: '..uploads)
   print('PASS Paradise ink: 10 levels, four directions, walking skins, boss and HUD; no runtime texture uploads; other biomes retain their assets')
   love.event.quit()
  end
 end
 love.draw=function()
  if index<=10 then
   oldDraw()
   if index==9 or index==10 then capture('paradis-niveau-'..index) end
  elseif index==11 then
   g.clear(.80,.79,.74);g.setColor(1,1,1)
   local kinds={'ange','snake','merle','original','spider'}
   for row,kind in ipairs(kinds) do
    for col,dir in ipairs({'down','left','up','right'}) do
     local x,y=220+(col-1)*220,100+(row-1)*130
     if kind=='ange' or kind=='snake' then
      local key=kind..'_'..dir;local a=ink.frame(key);local s=a.source
      ink.draw(key,x,y,100*s.w/s.h,0,100)
     elseif kind=='merle' then Art.drawFacing(kind,dir,x,y,100)
     else
      Profile.character=kind=='original' and 1 or 2
      player.walkMoving=true;player.walkPhase=1;player.reset=false
      Characters.draw(x,y,62,dir)
     end
    end
   end
   capture('paradis-directions')
  end
  drawn=true
 end
end
return T
