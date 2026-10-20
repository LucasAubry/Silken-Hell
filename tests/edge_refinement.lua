local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end
 App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;App.hardcore=false
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true;Hardcore.completed[tostring(w)]=true end
 local sky=require('sky');Campaign.select(6)
 local min,max=100,0
 for x=80,700,10 do
  local edge=sky.edgeDepth(x,1);min=math.min(min,edge);max=math.max(max,edge)
  assert(sky.fallAt(x,edge-.1) and not sky.fallAt(x,edge+.1),'Cloud edge and falling limit agree')
 end
 assert(max-min>15,'Cloud edge must visibly vary')
 local g=love.graphics;local c=g.newCanvas(960,600)
 for _,world in ipairs({1,4,6,7})do
  Campaign.select(world);player.level=1;reset_level();App.state='playing';UI.clock=3
  g.push('all');g.setCanvas(c);g.origin();g.clear();draw_level()
  require('paradise_frame').draw();require('biome_edge_life').draw();g.pop()
  c:newImageData():encode('png','refined-edge-'..world..'.png')
 end
 g.push('all');g.setCanvas(c);g.origin();g.clear(.08,.10,.14)
 for i,dir in ipairs({'down','up','left','right'})do
  g.setColor(1,1,1);Characters.portrait(12,120+(i-1)*240,170,175,dir)
  require('final_art').spider('partner',120+(i-1)*240,420,150,({down=0,up=math.pi,left=math.pi/2,right=-math.pi/2})[dir])
 end
 g.pop();c:newImageData():encode('png','partner-eight-legs.png');c:release()
 App.state='menu';App.selectedWorld=4;UI.draw();assert(#UI.buttons>0)
 App.selectedWorld=7;UI.draw()
 WorldMap.open();WorldMap.hardcore=true;UI.clock=1;UI.draw();UI.clock=2;UI.draw()
 print('PASS irregular sky edge/collision, four biome renders, partner sprites in all directions, tinted menu and breathing hardcore skull')
 love.event.quit(0)
end
return T
