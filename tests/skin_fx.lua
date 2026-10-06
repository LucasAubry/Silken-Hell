local T={}
function T.run()
 local P=require 'prism_palette';local F=require 'psychedelic_fx';local M=require 'monster_fx'
 local g=love.graphics;local selected=Characters.selected;local skin=Profile.character
 local image=g.newImage
 local quality=Graphics.quality;local replayData=Replay.data;local ghost=Replay.ghost
 local uploads=0
 g.newImage=function(...) uploads=uploads+1;return image(...) end
 for i=1,22 do
  Profile.character=i;Characters.selected=function()return i end
  local c=Characters.effectColor();local palette=P.player()
  for k=1,3 do assert(palette[1][k]==c[k]) end
  for world=1,7 do
   Campaign.select(world);assert(P.player()==palette,'Skin palette cannot change with biome')
   F.collect(200,200);assert(F.pickupPulse.palette==P.player(i),'Pickup must match the equipped skin in every biome')
   for _,pose in ipairs({'up','down','left','right'}) do Characters.portrait(i,60,60,50,pose) end
  end
  if Characters.crowned[i] then
   local base=Characters.effectColor(Characters.crowned[i])
   for k=1,3 do assert(c[k]==base[k],'Crown variants must retain body color') end
  end
 end
 Characters.selected=function()return 3 end
 F.death(100,100);F.collect(200,200);local old=F.deathPulse.palette;local pickup=F.pickupPulse.palette
 Characters.selected=function()return 4 end;Campaign.select(2)
 assert(F.deathPulse.palette==old and F.pickupPulse.palette==pickup and pickup==P.player(3) and P.player()~=old,'Events must retain their source palette through skin/biome transitions')
 Replay.playing=true;Replay.ghost=false;Replay.data={skin=3};Characters.selected=selected
 assert(P.player()==P.player(3),'Playback must use recorded skin');Replay.playing=false;Replay.data=replayData;Replay.ghost=ghost
 local count=0;local halo=M.halo;M.halo=function(...)count=count+1;return halo(...)end
 M.mob({x=100,y=100,type='worm',dead=true});M.mob({x=100,y=100,type='fish',abyssHeld=true})
 M.mob({x=100,y=100,type='fish',tunnelTravel={}})
 assert(count==0,'Hidden/dead creatures must not emit halos')
 local state=love.math.getRandomState();local effects=Graphics.effects
 g.push('all');g.setColor(.2,.4,.6,.7);g.setLineWidth(3)
 for quality=1,3 do Graphics.quality=quality;M.mob({x=100,y=100,type='fish'}) end
 local r,green,b,a=g.getColor();assert(math.abs(a-.7)<.001 and math.abs(r-.2)<.001 and g.getLineWidth()==3)
 Graphics.effects=false;local circle=g.circle;g.circle=function()error('Disabled monster FX cannot draw')end
 M.halo(100,100,50);g.circle=circle;Graphics.effects=effects;Graphics.quality=quality;g.pop()
 assert(love.math.getRandomState()==state,'Monster FX must not consume gameplay RNG')
 M.halo=halo;Profile.character=skin;Characters.selected=selected;F.reset();Campaign.select(1)
 g.newImage=image;assert(uploads==0,'Skins must be preloaded')
 for _,name in ipairs({'soie','perle','braise','ecume','royale'}) do
  assert(require('art_filter').image('assets/skins/'..name..'/down.png'):getFilter()=='nearest')
 end
 assert(not require('paradise_ink').sprite('original_down') and not require('paradise_ink').sprite('spider_down'),'Pixel spiders cannot use illustrated overrides')
 local dir=os.getenv('SILKEN_STYLE_CAPTURE_DIR')
 if dir then
  local c=g.newCanvas(1000,650);g.push('all');g.setCanvas(c);g.origin();g.clear(.04,.045,.06)
  for i=1,22 do
   local x=80+(i-1)%6*164;local y=65+math.floor((i-1)/6)*160
   local color=Characters.effectColor(i);g.setColor(color[1],color[2],color[3]);g.circle('line',x,y,49)
   g.setColor(1,1,1);Characters.portrait(i,x,y,82,'down');g.printf(Characters.names[i],x-78,y+56,156,'center')
  end
  g.pop();local data=c:newImageData();local bytes=data:encode('png');local file=assert(io.open(dir..'/skins.png','wb'))
  file:write(bytes:getString());file:close();bytes:release();data:release();c:release()
 end
 print('PASS skin FX: 22 skins / four directions, crown colors, biome independence, event snapshots, replay skin, hidden enemies, render state and RNG isolation, zero uploads')
end
return T
