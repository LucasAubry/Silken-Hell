local T={}
function T.run()
 local H=require 'boss_hud';local g=love.graphics
 Replay.disabled=true;LevelLayouts.disabled=true;Online.enabled=false
 App.start(1);Replay.recording=false
 local ox,oy=player.x,player.y
 for _,size in ipairs({{1200,750},{1800,800},{900,1200}}) do
  local w,h=size[1],size[2];local scale,x,y=App.viewport(w,h);local ui=math.min(w/1200,h/750)
  player.x=((w-1200*ui)/2+600*ui-x)/scale-15
  player.y=((h-750*ui)/2+86*ui-y)/scale-8
  assert(H.overlaps(w,h),'HUD overlap must account for letterboxing and widescreen')
  player.y=540;assert(not H.overlaps(w,h),'Player away from bar must not fade HUD')
 end
 player.x,player.y=ox,oy
 local examples={
  {kind='merle',boss={active=true,hp=4,maxHp=6,flash=0,name='L’Œuf du Merle'}},
  {kind='wasp',boss={active=true,hp=6,maxHp=9,flash=0,name='Les Trois Sœurs de braise',bees={{hp=3},{hp=2},{hp=1}}}},
  {kind='storm',boss={active=true,hp=5,maxHp=8,flash=0,name='Le Séraphin des orages'}},
  {kind='hedgehog',boss={active=true,hp=4,maxHp=7,flash=0,name='Le Hérisson des profondeurs'}},
  {kind='octopus',boss={active=true,hp=5,maxHp=8,flash=0,name='Le Poulpe des marées'}},
  {kind='skeleton_fish',boss={active=true,hp=7,maxHp=10,flash=0,name='Le Léviathan des Abysses'}}}
 local overlap=H.overlaps;H.overlaps=function() return true end;H.lastTime=nil;H.opacity=1
 for i=1,30 do UI.clock=UI.clock+1/60;H.draw(examples[1].boss) end
 assert(H.opacity>.27 and H.opacity<.30,'Bar fades to 28 percent')
 H.overlaps=function() return false end
 for i=1,30 do UI.clock=UI.clock+1/60;H.draw(examples[1].boss) end
 assert(H.opacity>.99,'Opacity recovers smoothly');H.overlaps=overlap
 assert(g.getCanvas()==nil,'HUD must restore render target')
 print('PASS boss HUD: six themes, overlap at three aspect ratios, smooth 28% fade and recovery, render-state restoration');io.stdout:flush()
 local draw=love.draw;local tick=0
 love.update=function(dt)
  UI.clock=UI.clock+dt;tick=tick+1
  if tick==3 then
   love.draw=draw;Campaign.select(4);player.level=10;reset_level();App.state='playing';player.x=Arena.width/2-15;player.y=400;App.capture='boss-hud-opaque.png'
  elseif tick==6 then
   local w,h=g.getDimensions();local scale,x,y=App.viewport(w,h);local ui=math.min(w/1200,h/750)
   player.x=((w-1200*ui)/2+600*ui-x)/scale-15;player.y=((h-750*ui)/2+86*ui-y)/scale-8
  elseif tick==45 then App.capture='boss-hud-transparent.png'
  elseif tick==49 then
   player.x=80;player.y=450;Octopus.stun=2;Octopus.rider={arm=1};Octopus.updateTether(1);App.capture='octopus-head-pull.png'
  elseif tick==53 then
   Campaign.select(1);player.level=10;reset_level();App.state='playing';App.capture='egg-six-nests.png'
  elseif tick==57 then
   player.dashing=true;player.x=Raven.x-15;player.y=Raven.y-12;Raven.contact();App.capture='egg-hit.png'
  elseif tick==61 then love.event.quit(0) end
 end
 love.draw=function()
  g.clear(.025,.035,.045)
  for i,e in ipairs(examples) do g.push('all');g.translate(0,(i-1)*112);H.paint(e.boss,e.kind);g.pop() end
  if tick==1 then g.captureScreenshot('boss-hud-themes.png') end
 end
end
return T
