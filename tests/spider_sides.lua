local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Profile.save=function() end;Bestiary.save=function() end;love.focus=function() end
 local A=require('final_art');local F=require('final_spider')
 assert(A.facing(-math.pi/2)=='right' and A.facing(math.pi/2)=='left' and A.facing(0)=='down' and A.facing(math.pi)=='up')
 App.start(3);F.angle=-math.pi/2;F.x=Arena.width*.4;F.y=280
 F.babies={{x=200,y=410,variant='red',angle=math.pi/2},{x=300,y=410,variant='white',angle=-math.pi/2},{x=400,y=410,variant='black',angle=math.pi/2}}
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then App.capture='spider-side-combat.png'
  elseif tick==4 then F.angle=math.pi/2;App.capture='spider-side-combat-left.png'
  elseif tick==7 then
   love.draw=function()
    local g=love.graphics;g.clear(.04,.05,.07);local w,h=g.getDimensions();g.push();g.scale(w/1200,h/720)
    for row,name in ipairs({'queen','baby_red','baby_white','baby_black','partner'}) do
     for col,angle in ipairs({math.pi/2,0,-math.pi/2}) do
      local x=col*300;local y=65+(row-1)*135
      g.setColor(1,1,1);A.spider(name,x,y,120,angle)
      if name=='queen' then A.clutch(x,y,120,24,angle) end
     end
    end
    g.pop();if tick==7 then g.captureScreenshot('spider-side-gallery.png') end
   end
  elseif tick==10 then print('PASS actual left/right profile rendering for queen, three baby colors and partner, directional eggs and crown');love.event.quit() end
 end
end
return T
