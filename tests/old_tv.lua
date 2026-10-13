local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false
 Profile.save=function()end;Bestiary.save=function()end
 local g=love.graphics;local tv=require('old_tv')
 local canvas=g.newCanvas(320,180,{dpiscale=1})
 local rng=love.math.getRandomState()
 local newCanvas,newImage=g.newCanvas,g.newImage
 g.newCanvas=function()error('TV filter must not allocate a canvas')end
 g.newImage=function()error('TV filter must not upload textures')end
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.5,.5,.5,1)
 g.setColor(.3,.4,.5,.6);tv.draw(320,180)
 local r,green,b,a=g.getColor()
 assert(math.abs(r-.3)<.001 and math.abs(a-.6)<.001,'Filter restores render state')
 g.pop();g.newCanvas,g.newImage=newCanvas,newImage
 assert(love.math.getRandomState()==rng,'Filter does not consume gameplay RNG')
 local pixels=canvas:newImageData()
 local center=pixels:getPixel(160,90);local corner=pixels:getPixel(2,2)
 assert(center>.40 and center<.5,'Scanlines remain subtle enough for text')
 assert(corner<center,'TV edges are darker than the center')
 pixels:release();canvas:release()
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then App.state='menu';App.capture='old-tv-menu.png'
  elseif tick==3 then
   App.singleLevel=true;App.practice=1;App.start(3);App.practice=nil
   require('run_start').active=false;player.reset=false;App.capture='old-tv-game.png'
  elseif tick==5 then
   print('PASS old TV: compiled overlay, readable center, vignette, render state, stable RNG, no canvas or texture allocation')
   love.event.quit()
  end
 end
end
return T
