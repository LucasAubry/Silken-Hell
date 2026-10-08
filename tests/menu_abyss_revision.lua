local T={}
local C=require('mobs.bosses.abyss.pattern_cycle')
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false;Replay.ghost=false
 Profile.save=function()end;Bestiary.save=function()end
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 local function reset(world,n)
  Replay.recording=false;Campaign.select(world or 7);player.level=n or 10;reset_level();App.state='playing';player.reset=false
  player.x=Arena.width-60;player.y=540;return Abyss
 end
 -- Energy is spent by absorption, never by a direct dash.
 local b=reset();C.enter(b,'bones');local x,y=C.mouth(b)
 player.x=x-15;player.y=y-12;player.charges=3;player.dashing=true;player.abyssGrace=10;C.contact(b);assert(b.hp==18 and player.charges==3)
 C.enter(b,'suction');x,y=C.mouth(b);player.x=x-15;player.y=y-12;C.suction(b,.1);assert(b.hp==18 and player.charges==0)
 C.suction(b,.1);assert(b.hp==18,'Absorption cannot repeat')
 local Bombs=require('mobs.bosses.abyss.bombs')
 for hp=17,0,-1 do
  C.enter(b,'traverse');b.swimAngle=0;local mx,my=C.swimMouth(b);b.bombs={{x=mx,y=my,r=15}};b.biteTime=0
  Bombs.mouth(b,mx,my,0);Bombs.mouth(b,mx,my,.21);assert(b.hp==hp)
 end
 assert(b.defeated,'Swallowed bombs defeat the boss')
 for round=1,2 do for _,part in ipairs({'head',5,'tail'}) do for _,dash in ipairs({false,true}) do
  b=reset();b.round=round;C.enter(b,'traverse')
  local offset=part=='tail' and 715 or type(part)=='number' and 65+part*62 or 0
  b.swimHead.x=Arena.width*.5+b.swimDir*offset;b.swimHead.y=b.swimY;b.buildBones()
  local piece;for _,bone in ipairs(b.bones) do if bone.part==part then piece=bone;break end end
  local found=false
  for yy=piece.y-50,piece.y+50,4 do
   for xx=piece.x-60,piece.x+60,4 do
    player.x=xx-15;player.y=yy-12
    if b.overlapsBone(piece) then found=true;break end
   end
   if found then break end
  end
  assert(found,'A real bone collision is sampled')
  player.dashing=dash;C.contact(b)
  assert(b.hp==18 and player.reset,'Head, spine and tail cannot take dash or walking damage')
 end end end
 for _,phase in ipairs({'intro'}) do
  b=reset();C.enter(b,phase);b.hp=5;player.charges=2;x,y=C.mouth(b)
  player.x=x-15;player.y=y-12;player.charges=1;player.dashing=true;C.contact(b);assert(b.hp==5,'Closed mouth is not an attack opening')
 end
 b=reset();Bosses.load({{type='skeleton_fish',x=200,y=300},{type='skeleton_fish',x=400,y=300}},{},{})
 local custom=Bosses.items[1].boss;C.enter(custom,'suction');x,y=C.mouth(custom)
 player.x=x-15;player.y=y-12;player.charges=1;player.dashing=true;C.suction(custom,.1)
 assert(custom.hp==18 and Bosses.items[2].boss.hp==18 and not custom.bodyContact,'Custom bosses survive charged absorption without losing health')
 -- Validate scene depth using the real draw pipeline, independent of mob spawn order.
 reset(1,1)
 local carrier={type='test_carrier',x=500,y=300};local other={type='test_other',x=500,y=300}
 mobs={other,carrier};Campaign.carrier=carrier;objet.larme_dropped=true
 local trace={};local drawMob,drawTear=Campaign.drawMob,Campaign.drawTear
 Campaign.drawMob=function(m)trace[#trace+1]=m==carrier and 'carrier' or 'other'end
 Campaign.drawTear=function()trace[#trace+1]='tear'end
 love.draw();assert(table.concat(trace,',')=='carrier,tear,other','Dropped tear is above carrier and below other creatures')
 trace={};objet.larme_dropped=false;love.draw();assert(table.concat(trace,',')=='tear,other,carrier','Carried tear stays behind creatures')
 Campaign.drawMob=drawMob;Campaign.drawTear=drawTear
 -- Compare actual pixels: bubble-only light reveals a dim silhouette; energy brightens it.
 local g=love.graphics
 local function brightness(charged,boss)
  reset(7,boss and 10 or 2);player.x=500;player.y=288;direction='down'
  mobs={};Ocean.bubbles={};Bosses.items={};AbyssTerrain.parts={}
  if charged then Abyss.charge(6) end
  local canvas=g.newCanvas(Arena.width,600);g.push('all');g.setCanvas(canvas);g.clear(0,0,0,1)
  draw_player(direction);Realms.drawDarkness();g.setCanvas();g.pop()
  local data=canvas:newImageData();local light=0
  for yy=265,325 do for xx=475,555 do local r,gg,bb=data:getPixel(xx,yy);light=light+r+gg+bb end end
  data:release();canvas:release();return light
 end
 local dim=brightness(false,false);local bright=brightness(true,false);local bossDim=brightness(false,true)
 assert(dim>5 and dim<bright*.6,'Spider is faintly visible in bubble light and brighter with energy')
 assert(bossDim<bright*.6,'Boss fight no longer fully reveals the uncharged spider')
 print('PASS charged absorption, victory, body collisions both directions, closed-mouth protection, custom bosses, tear depth, dim bubble lighting: '..dim..' / '..bright..' / '..bossDim)
 local renders=0;LevelLayouts.disabled=false
 for _,world in ipairs(Worlds.order) do for n=1,Worlds.levelCount(world) do
  reset(world,n);love.draw();renders=renders+1
 end end
 LevelLayouts.disabled=true
 print('PASS '..renders..' authored level renders across all campaign biomes')
 local frame=0
 love.update=function()
  frame=frame+1
  if frame==1 then App.state='menu';App.selectedWorld=1;Profile.language='fr';App.capture='menu-abyss-menu.png'
  elseif frame==3 then reset(7,2);player.x=500;player.y=288;direction='down';App.capture='menu-abyss-dim.png'
  elseif frame==5 then Abyss.charge(6);App.capture='menu-abyss-lit.png'
  elseif frame==7 then reset();C.enter(Abyss,'bones');player.x=280;player.y=310;App.capture='menu-abyss-mouth.png'
  elseif frame==9 then love.event.quit() end
 end
end
return T
