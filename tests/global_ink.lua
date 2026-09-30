local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Profile.name='QA';Profile.character=1;for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 local g=love.graphics
 love.window.setMode(1440,900,{resizable=true,highdpi=true,vsync=0});love.resize(g.getDimensions())
 local tasks={}
 for _,world in ipairs({1,6,5,4,7,2,3,9,10,11,12,13,14}) do
  for level=1,Worlds.levelCount(world) do tasks[#tasks+1]={world=world,level=level} end
 end
 local tick,handled,index=0,-1,0
 local originalDraw=love.draw
 love.draw=function() originalDraw();tick=tick+1 end
 local sheets=false
 love.update=function()
  if handled==tick then return end;handled=tick
  if tick%3==1 then assert(App.scenePixelHeight>600,'Every biome uses native density') end
  if tick%3==0 then
   index=index+1;local task=tasks[index]
   if task then
    Secret.duel=nil;App.practice=task.level;App.start(task.world);player.reset=false
    print('Render',task.world,task.level)
    if task.level==Worlds.levelCount(task.world) then App.capture='ink-world-'..task.world..'.png' end
   elseif not sheets then
    sheets=true;Secret.open(false);App.capture='ink-sanctuary.png'
   else
    assert(App.scenePixelHeight>600,'Sanctuary uses native density')
    -- Exercise every skin and every direction including separately drawn crowns.
    local old=g.getCanvas();local canvas=g.newCanvas(1440,1100)
    g.setCanvas(canvas);g.clear(.12,.16,.20,1);g.setColor(1,1,1)
    for n=1,22 do for i,dir in ipairs({'down','left','right','up'}) do
     local col=(n-1)%6;local row=math.floor((n-1)/6)
     Characters.portrait(n,col*240+30+(i-1)*59,row*270+110,54,dir,false)
    end end
    g.setCanvas(old);canvas:newImageData():encode('png','ink-skins.png');canvas:release()
    -- Queen directions: crown and separate clutch move with each pose.
    local canvas=g.newCanvas(1000,350);g.setCanvas(canvas);g.clear(.12,.16,.20,1);g.setColor(1,1,1)
    for i,angle in ipairs({0,math.pi/2,-math.pi/2,math.pi}) do
     require('final_art').spider('queen',i*230-80,180,170,angle)
     require('final_art').clutch(i*230-80,180,170,18,angle)
    end
    g.setCanvas(old);canvas:newImageData():encode('png','ink-queen.png');canvas:release()
    print('PASS '..#tasks..' levels, 22 skins × 4 directions, sanctuary, queen attachments')
    love.event.quit()
   end
  end
 end
end
return T
