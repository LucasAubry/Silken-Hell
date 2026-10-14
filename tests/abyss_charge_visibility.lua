local T={}
function T.run()
 io.stdout:setvbuf('no')
 love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 Profile.character=1;Profile.skinEffects={};Graphics.showFPS=false
 App.state='playing';App.hardcore=false;App.sessionLayout=nil;Secret.duel=nil
 Campaign.select(7);player.level=10;reset_level();App.respawn();require('retry_wait').reset()
 player.x=Arena.width*.6;player.y=380
 local F=require('mobs.bosses.abyss.charged_fish')
 local g=love.graphics;local canvas=g.newCanvas(Arena.width,600)
 local function charge(n)
  Abyss.fishCharge=0;player.charges=0;player.illuminated=0;player.electrified=0
  for _=1,n do F.trigger(Abyss) end
  Abyss.chargedFish={}
 end
 local function sample(n)
  charge(n)
  local rng=love.math.getRandomState()
  g.push('all');g.setCanvas(canvas);g.origin();g.setShader();g.clear(0,0,0,1)
  Abyss.drawLights();g.pop()
  assert(love.math.getRandomState()==rng and player.charges==n,'Aura never changes combat state or RNG')
  local data=canvas:newImageData()
  local r,green,blue=data:getPixel(math.floor(player.x+65),math.floor(player.y+12))
  data:release();return blue,green
 end
 for _,effects in ipairs({true,false}) do for quality=1,3 do
  Graphics.effects=effects;Graphics.quality=quality
  local dark,darkGreen=sample(0)
  local one,oneGreen=sample(1)
  local two=sample(2)
  local three=sample(3)
  assert(one>dark+.015 and oneGreen>darkGreen+.008,'Collected charge restores a blue aura outside the player silhouette')
  assert(two>one+.06 and three>two+.06,'Each of the first three charges produces a clearly brighter surrounding halo')
  assert(math.abs(sample(0)-dark)<.001,'Aura disappears when the charge is consumed')
  local hidden=Abyss.playerHidden;Abyss.playerHidden=function()return true end
  assert(math.abs(sample(1)-dark)<.001,'Aura remains hidden during concealed player phases')
  Abyss.playerHidden=hidden
 end end
 -- Compare complete skin renders against the same skin under neutral light.
 local selected=Characters.selected
 for _,skin in ipairs({1,8,24}) do
  Characters.selected=function()return skin end
  local function body(n,neutral,beacon,trail)
   charge(n)
   local visibility=Abyss.playerVisibility
   if neutral then Abyss.playerVisibility=function()return 1 end end
   g.push('all');g.setCanvas(canvas);g.origin();g.setShader();g.clear(0,0,0,1)
   if beacon then draw_player_beacon() elseif trail then draw_shadow_dash() else draw_player('down') end
   g.pop();Abyss.playerVisibility=visibility
   local data=canvas:newImageData();local sums={0,0,0}
   for y=math.floor(player.y-40),math.floor(player.y+40) do
    for x=math.floor(player.x-40),math.floor(player.x+70) do
     local r,green,b=data:getPixel(x,y)
     sums[1]=sums[1]+r;sums[2]=sums[2]+green;sums[3]=sums[3]+b
    end
   end
   data:release();return sums
  end
  local dark=body(0);assert(dark[1]+dark[2]+dark[3]>1,'Spider remains faintly visible without charges')
  local lantern=body(0,false,true);assert(lantern[1]>1 and lantern[2]>1,'Small lantern stays visible in darkness')
  local reference=body(3,true)
  local one,three,six=body(1),body(3),body(6)
  for channel=1,3 do
   assert(one[channel]<three[channel] and three[channel]<six[channel],'Each charge reveals more of the natural skin')
   assert(dark[channel]/reference[channel]>.18 and dark[channel]/reference[channel]<.26,'Uncharged body stays dim')
   assert(math.abs(three[channel]/reference[channel]-.8284)<.025,'Neutral brightness preserves skin RGB proportions: '..skin)
  end
  ghosts={{x=player.x,y=player.y,alpha=1,direction='down'}}
  local trail=body(0,false,false,true);assert(trail[1]+trail[2]+trail[3]<dark[1]+dark[2]+dark[3],'Uncharged dash stays dimmer than the body')
  ghosts={}
 end
 -- The real darkness pass must reveal distant scenery progressively, even beyond three charges.
 local previous=0
 for _,n in ipairs({0,1,2,3,6}) do
  charge(n)
  g.push('all');g.setCanvas(canvas);g.origin();g.setShader();g.clear(1,1,1,1)
  Realms.drawDarkness();g.pop()
  local data=canvas:newImageData();local light=data:getPixel(math.floor(player.x-160),math.floor(player.y+12));data:release()
  assert(light>previous+.005,'Additional charges illuminate more surrounding terrain: '..n)
  previous=light
 end
 Characters.selected=selected
 canvas:release();Graphics.effects=true;Graphics.quality=3
 charge(0)
 require('mobs.bosses.abyss.ricochet').fire(Abyss)
 local bolt=Abyss.returnShots[1];bolt.x=player.x-100;bolt.y=player.y+12
 print('Lighting assertions complete; capturing 0, 1, 2 and 3 charges')
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=8
  if tick==1 then charge(0);App.capture='abyss-charge-v2-0.png'
  elseif tick==3 then charge(1);App.capture='abyss-charge-v2-1.png'
  elseif tick==5 then charge(2);App.capture='abyss-charge-v2-2.png'
  elseif tick==7 then charge(3);App.capture='abyss-charge-v2-3.png'
  elseif tick==9 then
   charge(0)
   for _=1,3 do F.trigger(Abyss) end
   F.update(Abyss,1.15,player.x+15,player.y+12)
   assert(not player.reset,'Fish preview remains outside collision range')
   App.capture='abyss-charge-v2-fish.png'
  elseif tick==12 then
   print('PASS charge lighting: dim body, visible lantern, natural skin colors, distinct charge halos, growing terrain light, dim dash, all qualities and charge consumption')
   love.event.quit()
  end
 end
end
return T
