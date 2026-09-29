local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 App.start(3);local A=require('final_art');local C=Characters
 assert(require('final_spider').phase=='passive')
 for _,angle in ipairs({0,.3,math.pi,math.pi+.3,-math.pi/2,math.pi/2}) do
  local dir,turn=A.pose(angle);assert(math.abs(turn)<=math.pi/4+.001)
 end
 local draw=Art.draw;local cy,rotation
 Art.draw=function(key,x,y,w,a,...)if key=='reward_crown' then cy=y;rotation=a or 0 end;return draw(key,x,y,w,a,...)end
 C.crown(0,0,100,'up');assert(cy==-30 and rotation==0,'Rear crown stays on the upper head, upright');Art.draw=draw
 local tick=0
 love.draw=function()
 love.graphics.clear(.045,.06,.08);local dirs={'down','left','up','right'};local angles={0,math.pi/2,math.pi,-math.pi/2}
 for i,dir in ipairs(dirs)do
  local x=150+(i-1)*280
  UI.text(dir,x-70,20,'small',{1,1,1},140,'center')
  Profile.character=22;C.draw(x,130,100,dir)
  C.portrait(15,x,280,100,dir,false)
  A.spider('queen',x,440,100,angles[i]);A.clutch(x,440,100,24,angles[i])
  A.spider('queen',x,590,100,angles[i]+.35);A.clutch(x,590,100,24,angles[i]+.35)
 end
 if tick==2 then love.graphics.captureScreenshot('crown-orientation.png') end
 end
 love.update=function()tick=tick+1;if tick==5 then print('PASS crown anchors, directional pose transforms, passive encounter preserved');love.event.quit()end end
end
return T
