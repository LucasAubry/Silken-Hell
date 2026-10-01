local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Profile.name='QA';Profile.character=1;for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 local function start(w,n) Secret.duel=nil;App.practice=n;App.start(w);player.reset=false end
 local C=require('mobs.bosses.abyss.pattern_cycle');start(7,10)
 assert(not Abyss.open and Abyss.bones[1].key=='skeleton_head','Abyss starts with closed jaws')
 local kill=Hazards.kill;local deaths=0;Hazards.kill=function() deaths=deaths+1 end
 C.enter(Abyss,'rest');Abyss.plankton={};Abyss.debris={}
 local mx,my=C.mouth(Abyss);player.x=mx-15;player.y=my-12;player.dashing=true;player.abyssGrace=0
 assert(not C.blockedPlayer(Abyss,player.x,player.y),'Throat is reachable')
 C.contact(Abyss);assert(Abyss.hp==9 and deaths==0,'Open-mouth dash removes one HP without killing the player')
 player.dashing=true;C.contact(Abyss);assert(Abyss.hp==9,'Continuous contact cannot deal repeated damage')
 player.x=400;player.dashing=false;C.contact(Abyss);Abyss.mouthHitCooldown=0
 player.x=mx-15;player.dashing=true;C.contact(Abyss);assert(Abyss.hp==8,'New entry can damage the open mouth again')
 player.charges=1;assert(Abyss.playerLightRadius()==320);player.charges=3;assert(Abyss.playerLightRadius()==490)
 Hazards.kill=kill
 start(3,1);local F=require('final_spider');F.engaged=true;F.phase='webs';F.jumpCooldown=0;F.x=200;F.y=180
 player.x=270;player.y=168;local oldX=F.x
 F.update(.01);assert(F.phase=='intro_jump','Queen escapes when the player approaches')
 for _=1,90 do F.update(.01) end
 assert(F.x>oldX+Arena.width*.4 and F.jumpHeight==0 and F.jumpCooldown>0,'Queen lands across the arena with a cooldown')
 F.webs={};F.babies={};F.phase='recover';F.phaseTime=0;F.eggs={{x=300,y=320,age=1,hatch=7.5,seed=1}}
 player.x=285;player.y=308;F.update(.01);assert(F.eggs[1].hits==1 and F.eggs[1].crackShake>0,'First egg crossing cracks and shakes it')
 F.update(.01);assert(#F.eggs==1,'Remaining on an egg is not a second crossing')
 player.x=400;F.update(.01);player.x=285;F.update(.01);assert(#F.eggs==0 and F.hp==19,'Second crossing breaks the egg')
 print('PASS mouth hits, closed intro, brighter charges, queen escape leap, two-crossing eggs')
 local g=love.graphics;love.window.setMode(1440,900,{resizable=true,highdpi=true,vsync=0});love.resize(g.getDimensions())
 local tasks={}
 for _,world in ipairs({1,6,5,4,7,2,3,9,10,11,12,13,14}) do
  for n=1,Worlds.levelCount(world) do tasks[#tasks+1]={world=world,level=n} end
 end
 local tick,handled,index=0,-1,0;local oldDraw=love.draw;love.draw=function()oldDraw();tick=tick+1 end
 love.update=function()
  if handled==tick then return end;handled=tick
  if tick%3~=0 then return end
  index=index+1;local task=tasks[index]
  if task then
   start(task.world,task.level)
   if task.level==Worlds.levelCount(task.world) then App.capture='biome-fix-world-'..task.world..'.png' end
   return
  end
  local extra=index-#tasks
  if extra==1 then
   start(5,4);Realms.larvae={{x=300,y=300,age=1,life=16,dir='down'}};App.capture='biome-fix-earth.png'
  elseif extra==2 then
   start(7,2);Abyss.charge(6);App.capture='biome-fix-charge.png'
  elseif extra==3 then
   start(3,1);F.engaged=true;F.phase='webs';F.x=600;F.y=180;F.eggs={{x=430,y=300,age=1,hatch=7.5,seed=1},{x=530,y=300,age=3,hatch=7.5,seed=2,hits=1},{x=630,y=300,age=6.5,hatch=7.5,seed=3}};F.shells={{x=730,y=300,seed=1}};App.capture='biome-fix-eggs.png'
  elseif extra==4 then Secret.open(false);Secret.page=2;Secret.refresh();assert(Secret.portals[1].art=='merle_flight_down');App.capture='biome-fix-sanctuary-bird.png'
  elseif extra==5 then Secret.page=7;Secret.refresh();App.capture='biome-fix-sanctuary-queen.png'
  elseif extra==6 then
   local old=g.getCanvas();local c=g.newCanvas(1200,750);g.setCanvas(c);g.clear(.10,.13,.18,1);g.setColor(1,1,1)
   for n=1,22 do for i,dir in ipairs({'down','left','right','up'}) do Characters.portrait(n,((n-1)%6)*200+i*44,80+math.floor((n-1)/6)*175,42,dir,false) end end
   g.setCanvas(old);c:release()
   for _,w in ipairs(Worlds.order) do local image=require('icon_composer').make(w);image:release() end
   for _,variant in ipairs({'red','white','black'}) do
    for _,prefix in ipairs({'baby_','left_','side_','up_'}) do require('final_art').draw(prefix..variant,0,0,30,0) end
   end
   for _,name in ipairs({'web_gate','web_shot','shell'}) do require('final_art').draw(name,0,0,30,0) end
   local editorIcon=love.graphics.newImage('assets/icons/silken-editor.png');editorIcon:release()
   -- Load every artwork used by the editor and sanctuary catalogs.
   for _,e in ipairs(require('designer.catalog')) do if e.art and Art.images[e.art] then local a=Art.images[e.art];assert(a.w>0 and a.h>0) end end
   Secret.duel=nil;App.state='menu';App.selectedWorld=1;App.capture='biome-fix-menu.png'
  else
   if _G.AssetAudit then local list={};for p in pairs(AssetAudit) do list[#list+1]=p end;table.sort(list);love.filesystem.write('biome-assets-used.json',require('json').encode(list)) end
   print('PASS '..#tasks..' level renders, nest birds, worms, eggs, all skins, sanctuary identities and icons')
   love.event.quit()
  end
 end
end
return T
