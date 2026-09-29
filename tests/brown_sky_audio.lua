local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 local music=Audio.paradise;local playing=false
 Audio.paradise={setVolume=function()end,isPlaying=function()return playing end,play=function()playing=true end,stop=function()playing=false end}
 App.state='rankings';UI.boardReturn='victory';Audio.update(Profile,false);assert(not playing)
 UI.boardReturn=nil;Audio.update(Profile,false);assert(playing)
 App.state='victory';Audio.update(Profile,false);assert(not playing);Audio.paradise=music
 App.start(6);local B=require('biome_borders');B.key=nil;B.draw();assert(B.key==nil,'No sky perimeter')
 local draw=Art.draw;local rotation
 Art.draw=function(key,x,y,size,angle,...)if key=='original_up' then rotation=angle or 0 end;return draw(key,x,y,size,angle,...)end
 Characters.portrait(1,100,100,100,'up');assert(rotation==0,'Rear artwork is not flipped')
 Art.draw=draw
 Profile.character=22;player.walkMoving=true;player.walkPhase=1
 for _,dir in ipairs({'up','down','left','right'})do Characters.draw(100,100,62,dir)end
 player.walkMoving=false
 local tick=0
 love.update=function()
 tick=tick+1
 if tick==1 then App.capture='sky-no-borders.png'
 elseif tick==4 then love.draw=function()
  local g=love.graphics;g.clear(.03,.04,.055);local sw,sh=g.getDimensions();g.push();g.scale(sw/1200,sh/720)
  for i,dir in ipairs({'down','left','up','right'})do
   local x=150+(i-1)*300;g.setColor(1,1,1);Characters.portrait(1,x,175,190,dir);Characters.portrait(22,x,435,140,dir)
   UI.text(dir,x-90,290,'body',{1,1,1},180,'center')
   Profile.character=1;Characters.draw(x,600,62,dir)
  end
  g.pop();if tick==5 then g.captureScreenshot('brown-new-directions.png')end
 end
 elseif tick==8 then print('PASS victory ranking silent, menu ranking music, no sky border, unrotated rear, four walking rigs');love.event.quit()end
 end
end
return T
