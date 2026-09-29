local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function() end;Bestiary.save=function() end
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 local F=require('final_spider');Secret.catalog();assert(#Secret.normalBosses==7 and #Secret.demonBosses==6)
 Secret.open(false)
 for i,b in ipairs({Raven,Storm,Hedgehog,Octopus,Abyss,Wasp,F}) do
  Secret.page=i;Secret.refresh();Secret.launch(Secret.portals[1]);assert(App.state=='playing' and b.active,'Native boss '..i)
  assert(App.sessionLayout==nil and App.practice==(i==7 and 1 or 10));assert(i==7 or not Ending.active)
  App.state='customVictory';love.keypressed('escape');assert(App.state=='bossWorld' and Secret.page==i and not Ending.active,'Restore selected page '..i)
 end
 Secret.open(true);for i=1,6 do Secret.page=i;Secret.refresh();Secret.launch(Secret.portals[1]);assert(App.state=='playing' and Worlds.isSecret(Campaign.world));Secret.open();assert(Secret.hardcore and Secret.page==i) end
 Secret.open(false);for _,entry in ipairs(Secret.creatures) do if entry.world==3 then
  Secret.launch(entry);assert(not Ending.active and not Renaissance.active and #mobs>0,'Renaissance creature duel stays a creature duel');Secret.open(false);break
 end end
 Secret.page=7;Secret.refresh();Secret.launch(Secret.portals[1]);assert(F.active)
 F.hp=1;F.damage();F.gate=true;player.x=Arena.width*.5-15;player.y=25;F.update(.01)
 assert(App.state=='customVictory' and player.level==1,'Sanctuary final boss does not start the ending');love.keypressed('escape');assert(Secret.page==7)
 Secret.duel=nil;App.practice=nil;App.singleLevel=false;App.sessionLayout=nil;App.start(3)
 local positions={}
 for wave=1,4 do
  F.wave=wave;F.batch=0;F.eggs={};F.carried=24;F.chooseNest()
  for i=1,8 do F.layEgg() end;assert(#F.eggs==8)
  local ys={};for i,e in ipairs(F.eggs) do
   assert(e.x>=65 and e.x<=Arena.width-65 and e.y>=105 and e.y<=525)
   ys[math.floor(e.y/10)]=true
   for j=i+1,#F.eggs do local b=F.eggs[j];assert((e.x-b.x)^2+(e.y-b.y)^2>=44^2) end
  end
  local count=0;for _ in pairs(ys) do count=count+1 end;assert(count>=3,'Eggs do not align in rows')
  positions[#positions+1]=F.nest.x..':'..F.nest.y
 end
 assert(positions[1]~=positions[2],'Nest changes between clutches')
 for _,name in ipairs({'queen','baby_red','baby_white','baby_black','egg','egg_crack1','egg_crack2','shell','web_shot','web_wall','web_gate','partner'}) do
  local d=love.image.newImageData(require('asset_paths').resolve('assets/sprites/final/'..name..'.png'));local _,_,_,a=d:getPixel(0,0);assert(a==0);d:release()
 end
 local tick=0;love.focus=function() end
 love.update=function()
  tick=tick+1;UI.clock=4
  if tick==1 then for i,e in ipairs(F.eggs) do e.age=i*.85 end;F.babies={{x=200,y=350,age=2,seed=1,variant='red'},{x=280,y=400,age=2,seed=2,variant='white'},{x=350,y=440,age=2,seed=11,variant='black'}};F.shells={{x=150,y=220,seed=1}};F.wallWeb(34,300);App.capture='spider-assets-combat.png'
  elseif tick==4 then Secret.open(false);Secret.page=7;Secret.refresh();App.capture='spider-assets-sanctuary.png'
  elseif tick==7 then Secret.duel=nil;App.practice=2;App.sessionLayout=nil;App.start(3);App.capture='spider-assets-partner.png'
  elseif tick==10 then print('PASS assets: 7 native normal bosses, 6 demon bosses, preserved sanctuary page, Renaissance creatures isolated, final duel exit, random spaced nests, 12 transparent PNG sprites');love.event.quit() end
 end
end
return T
