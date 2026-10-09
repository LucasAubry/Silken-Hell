local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Profile.name='lucas';Profile.language='fr'
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Profile.levels[w]=10 end
 local json=require('json');local scene=require('sanctuary_scene')
 App.sessionLayout=nil;App.practice=nil;App.hardcore=false;App.singleLevel=false
 -- Sanctuary duels must retain the original arena geometry and spawn positions.
 for _,w in ipairs(Worlds.order) do
  Secret.duel=nil;Campaign.select(w);player.level=w==3 and 1 or 10;reset_level()
  local walls=json.encode(Arena.walls);local x,y=player.x,player.y
  Secret.duel={kind='boss'};reset_level()
  assert(json.encode(Arena.walls)==walls and player.x==x and player.y==y,'Original arena layout: '..w)
 end
 Secret.duel=nil
 local g=love.graphics;local canvas=g.newCanvas(1200,750)
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.01,.01,.01,1)
 for i=1,14 do g.setColor(1,1,1);Characters.portrait(i,45+i*70,100,25) end
 g.pop();canvas:newImageData():encode('png','sanctuary-avatar-check.png')
 Online.scores=function()return {{name='lucas',skin=1,time=122,deaths=0},{name='lucas',skin=2,time=130,deaths=1}},'ready' end
 local frame=0
 love.update=function()
  frame=frame+1;UI.clock=UI.clock+.016
  require('achievement_notice').active=nil;require('achievement_notice').queue={}
  require('discovery_notice').active=nil;require('discovery_notice').queue={}
  if frame==1 then App.state='menu';UI.clock=2.8;App.capture='sanctuary-menu-fix.png'
  elseif frame==3 then Secret.open();Secret.x=Secret.position(4);Secret.cameraX=Secret.x-Arena.width*.5;App.capture='sanctuary-octopus-fix.png'
  elseif frame==5 then Secret.x=Secret.position(6);Secret.cameraX=Secret.x-Arena.width*.5;App.capture='sanctuary-sisters-fix.png'
  elseif frame==7 then Secret.x=Secret.position(5);Secret.cameraX=Secret.x-Arena.width*.5;App.capture='sanctuary-bones-fix.png'
  elseif frame==9 then Secret.launch(Secret.portals[6]);require('run_start').active=false;App.capture='sanctuary-marble-fix.png'
  elseif frame==11 then print('PASS sanctuary layouts for seven bosses and menu/gallery/marble rendering');love.event.quit() end
 end
end
return T
