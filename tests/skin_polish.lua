local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true;Hardcore.completed[tostring(w)]=true end
 Profile.achievements={gillou=true,maxance=true}
 local C=Characters;local original=Art.draw;local calls=0
 Art.draw=function(key,...)if key=='reward_crown' then calls=calls+1 end;return original(key,...)end
 for i=15,22 do
  for _,dir in ipairs({'down','up','left','right'})do
   calls=0;C.portrait(i,100,100,100,dir)
   assert(calls==(C.nativeCrown[C.crowned[i]] and 0 or 1),'Never stack crowns '..i..dir)
  end
 end
 Art.draw=original
 local last;local draw=Art.draw;Art.draw=function(key,...)last=key;return draw(key,...)end
 C.portrait(1,100,100,80,'left');assert(last=='original_left','Brown portrait uses profile pose')
 C.portrait(1,100,100,80,'right');assert(last=='original_right')
 Art.draw=draw
 App.start(3);Profile.character=22;player.walkMoving=true;player.walkPhase=1
 for _,dir in ipairs({'down','up','left','right'})do C.draw(100,100,62,dir) end
 player.walkMoving=false
 local g=love.graphics;g.setColor(.3,.4,.5,.7);C.portrait(15,100,100,80,'up',true)
 local r,gg,b,a=g.getColor();assert(math.abs(r-.3)<.001 and math.abs(a-.7)<.001,'Portrait restores tint and alpha')
 g.setColor(1,1,1)
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then App.state='menu';Profile.character=22;App.capture='polished-brown-menu.png'
  elseif tick==4 then
   love.draw=function()
    g.clear(.03,.04,.06);local sw,sh=g.getDimensions();g.push();g.scale(sw/1200,sh/720)
    for i=15,22 do
     local x=150+((i-15)%4)*300;local y=125+math.floor((i-15)/4)*345
     g.setColor(1,1,1);C.portrait(i,x,y,160,'down')
     UI.text(C.names[i],x-140,y+78,'small',{1,1,1},280,'center')
     for n,dir in ipairs({'left','up','right'})do C.portrait(i,x-90+(n-1)*90,y+150,65,dir)end
    end
    g.pop();if tick==5 then g.captureScreenshot('polished-crowns-gallery.png') end
   end
  elseif tick==8 then print('PASS all 8 crowned rewards in 4 views; no duplicate crowns; brown directional portraits; locked tint restoration');love.event.quit()end
 end
end
return T
