local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;love.focus=function() end
 local finish=Replay.finish;Replay.finish=function() end
 require('app_icon').complete=function() end
 Profile.completed={};Profile.scores={};Profile.achievements={};Hardcore.completed={}
 assert(#Characters.keys==22)
 for i=15,22 do assert(not Characters.unlocked(i),'New reward begins locked '..i) end
 for _,w in ipairs(Worlds.order) do
  if w~=3 then Profile.completed[w]=true end
  assert(not Characters.unlocked(Characters.crownedByWorld[w]),'Normal victory does not award biome crown')
 end
 for secret,w in pairs(Worlds.secretBiomes) do
  Profile.complete(secret,10,0);assert(Characters.unlocked(Characters.crownedByWorld[w]),'Demon victory unlocks matching crown')
 end
 Profile.completed={};Profile.scores={}
 for _,w in ipairs(Worlds.order) do
  Hardcore.complete(w);assert(Characters.unlocked(Characters.crownedByWorld[w]),'Hardcore victory unlocks matching crown')
 end
 Hardcore.completed={};Profile.completed={};Profile.scores={};Profile.character=1
 Replay.playing=true;Profile.complete(3,10,0);Hardcore.complete(1);Replay.playing=false
 assert(not Characters.unlocked(22) and not Characters.unlocked(15),'Replays cannot earn rewards')
 Profile.complete(3,10,0);assert(Characters.unlocked(22),'Finished story awards brown crown')
 Profile.character=22;Profile.save();Profile.load();assert(Profile.character==22 and Characters.selected()==22,'Crowned skin persists through profile reload')
 Hardcore.completed['1']=true;Profile.character=15;Profile.save();Profile.load();assert(Characters.selected()==15)
 for _,w in ipairs(Worlds.order) do Hardcore.completed[tostring(w)]=true end
 Replay.finish=finish
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then App.state='menu';Profile.character=22;App.capture='crown-brown-menu.png'
  elseif tick==4 then App.start(1);Profile.character=22;App.capture='crown-brown-playing.png'
  elseif tick==7 then
   local draw=love.draw
   love.draw=function()
    local g=love.graphics;g.clear(.03,.04,.06);local sw,sh=g.getDimensions();g.push();g.scale(sw/1200,sh/720)
    for i=15,22 do
     local x=150+((i-15)%4)*300;local y=155+math.floor((i-15)/4)*325
     g.setColor(1,1,1);Characters.portrait(i,x,y,160,'down');g.setFont(UI.fonts.body);g.printf(Characters.names[i],x-140,y+95,280,'center')
     for n,dir in ipairs({'left','up','right'}) do Characters.portrait(i,x-90+(n-1)*90,y+160,55,dir) end
    end
    g.pop();if tick==7 then g.captureScreenshot('crowned-skins-gallery.png') end
   end
  elseif tick==10 then print('PASS 8 crown variants, demon and hardcore rewards, normal exclusions, replay exclusions, brown ending reward, selection persistence, four directional renders');love.event.quit() end
 end
end
return T
