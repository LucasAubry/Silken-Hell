local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;App.hardcore=false;App.singleLevel=true;Secret.duel=nil
 local g=love.graphics;local assets=require('map_assets');local gate=require('abyss_gate');local json=require('json')
 if App.preview then
  assert(next(Art.pending),'Preview registers unused textures without loading them')
  assert(not rawget(Art.images,'octopus_extended_down') and not rawget(Art.images,'skeleton_head'),'An infernal larva map does not load ocean/abyss bosses')
  local count=0;for _ in pairs(require('art_filter').images) do count=count+1 end
  print('PREVIEW_TEXTURES '..count)
  assert(count<70,'Only common assets and this map are resident')
 end
 local function load(map)
  assert(LayoutSchema.validate(map));App.sessionLayout=map;assets.load(map)
  Campaign.select(map.world);player.level=map.level;App.state='playing';reset_level();require('run_start').active=false
 end
 local function scene(path)
  local canvas=g.newCanvas(Arena.width,600,{dpiscale=1})
  g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.setShader();g.clear()
  Campaign.draw();for _,m in ipairs(mobs) do Campaign.drawMob(m) end
  Campaign.drawTear(true);gate.draw();draw_player('down');g.pop()
  local data=canvas:newImageData();data:encode('png',path);data:release();canvas:release()
 end
 for _,biome in ipairs({1,2,4,5,6,7}) do
  local map={world=biome,level=1,width=960,height=600,entities={{kind='spawn',x=760,y=470},{kind='mob',type='magma_larva',x=280,y=300,has_larme=true}}}
  load(map);local larva=mobs[1]
  Magma.explode(larva);Magma.update(.01);Campaign.updateTear(.01)
  assert(#mobs==0 and objet.larme_dropped and not objet.larme.taken and Campaign.canCollect(),'Dead carrier releases collectible in biome '..biome)
  assert(objet.larme.x+15==280*Arena.width/960 and objet.larme.y+20==300,'Drop is centred at the death location')
  local x,y=objet.larme.x,objet.larme.y
  for i=1,30 do Campaign.updateTear(.1) end
  assert(objet.larme.x==x and objet.larme.y==y,'Released tear cannot teleport or follow its removed carrier')
  scene('preview-tear-'..biome..'.png')
 end
 local map={world=2,level=4,width=960,height=600,entities={{kind='spawn',x=760,y=470},{kind='mob',type='larva',x=300,y=300,has_larme=true},{kind='mob',type='magma_larva',x=450,y=300},{kind='wall',x=500,y=200,w=110,h=24}}}
 load(map);mobs[1].x=320;mobs[1].y=310;table.remove(mobs,1);Campaign.updateTear(0)
 assert(objet.larme_dropped and objet.larme.x==305 and objet.larme.y==290,'Other removed carriers release their tear too')
 -- Repeated deaths must only rebuild authored state, without GPU uploads or native encounters.
 load(map);scene('preview-larvae.png')
 local native=Campaign.spawnHell;Campaign.spawnHell=function()error('Generated Hell before applying the preview')end
 local newImage,newCanvas=g.newImage,g.newCanvas;local uploads,canvases=0,0
 g.newImage=function(...)uploads=uploads+1;return newImage(...)end
 g.newCanvas=function(...)canvases=canvases+1;return newCanvas(...)end
 local start=love.timer.getTime()
 for i=1,30 do App.respawn();assert(#mobs==2 and #Arena.interior==1) end
 local elapsed=(love.timer.getTime()-start)*1000/30
 g.newImage=newImage;g.newCanvas=newCanvas;Campaign.spawnHell=native
 assert(uploads==0 and canvases==0,'Retries reuse textures and render surfaces')
 print(string.format('PREVIEW_RETRY_AVERAGE_MS %.3f',elapsed))
 local gateMap={world=7,level=9,width=960,height=600,entities={{kind='spawn',x=790,y=300},{kind='abyss_gate',x=105,y=300,w=540,h=648},{kind='tear',x=202.2,y=350}}}
 load(gateMap)
 assert(gate.active and gate.x<Arena.width/2 and gate.tx<Arena.width/2 and player.x>Arena.width/2,'Gate and tear on left, approach from right')
 local snapshot=LevelLayouts.snapshot();assert(LayoutSchema.validate(snapshot))
 local found=0;for _,e in ipairs(snapshot.entities) do if e.kind=='abyss_gate' then found=found+1 end end
 assert(found==1,'Gate survives snapshot/editor round trips')
 scene('preview-abyss-left.png')
 player.x=gate.tx-15;player.y=gate.ty-12;gate.update(.01);assert(gate.closing)
 gate.update(1.3);App.simulate(.01);assert(App.state=='customVictory','Preview gate finishes only this map')
 table.remove(gateMap.entities,2);load(gateMap);assert(not gate.active,'Removing the head removes the encounter')
 local order={levels={['2:4']={level=4,marker='four'},['2:7']={level=7,marker='seven'}}}
 require('campaign_order').migrate(order);require('campaign_order').migrate(order)
 assert(order.levels['2:4'].marker=='seven' and order.levels['2:7'].marker=='four' and order.levels['2:4'].level==4,'Hell reorder is idempotent')
 local focus=love.window.hasFocus;love.window.hasFocus=function()return true end
 Graphics.limit=0;App.preview=true;assert(Graphics.targetRate()==60 and Graphics.targetRate(true)==60)
 love.window.hasFocus=function()return false end;assert(Graphics.targetRate()==15);love.window.hasFocus=focus
 print('PASS map preview: selective assets, repeated retries, carrier death drops, biome rendering, larva sizes, movable left gate, Hell order and frame budgets')
 print('VISUALS '..love.filesystem.getSaveDirectory())
 love.event.quit()
end
return T
