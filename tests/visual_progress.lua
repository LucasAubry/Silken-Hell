local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Graphics.effects=true;Graphics.showFPS=false
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false;Replay.ghost=false
 local D=require('dev_profile');local available=D.available;D.available=function()return true end
 local name,country=Profile.name,Profile.country
 assert(D.apply(false));assert(Profile.name==name and Profile.country==country,'Reset preserves identity/settings')
 local E=require('skin_effects')
 Hardcore.completed['8']=true;Hardcore.completed['9']=true
 Profile.skinGrants={heartbreak=true,['15']=true,['22']=true};Profile.completed[9]=true
 Profile.skinEffects={hardcore=true,gold=true};Profile.tearExtension=true
 for _,kind in ipairs({'hardcore','gold','heartbreak'}) do assert(not E.enabled(kind) and not E.equip(kind,true),'No effect from legacy grants: '..kind) end
 local records=require('top_records')
 records.merge({{runId='12345678-1234-1234-1234-123456789abc',world=1,achievedAt=Profile.progressResetAt-1000,rawTime=5,deaths=0}})
 assert(#Profile.topRecords==0,'Reset progress is not re-awarded by historical online records')
 Profile.save();Profile.load();assert(not E.enabled('hardcore'),'Locked toggle stays unavailable after reload')
 Profile.achievements.hardcore=true;assert(E.enabled('hardcore'))
 Profile.achievements.heartbreak=true;assert(E.enabled('heartbreak'))
 Profile.achievements.top1=true;assert(E.enabled('gold'))
 assert(D.apply(false));assert(not next(Profile.completed) and not next(Hardcore.completed) and not next(Bestiary.seen))
 local all={id='hardcore_all'}
 for i,world in ipairs(Worlds.order) do
  Hardcore.completed[tostring(world)]=true
  assert(Achievements.unlocked(all)==(i==#Worlds.order),'Hardcore trophy needs all seven worlds')
 end
 Hardcore.completed={};Profile.scores={{world=8,hardcore=true},{world=9,hardcore=true}}
 assert(not Achievements.unlocked(all),'Sanctuary/secret bosses cannot grant all-worlds hardcore')
 Profile.scores={};for _,world in ipairs(Worlds.order) do Profile.scores[#Profile.scores+1]={world=world,hardcore=true,deaths=3,time=100} end
 assert(Achievements.unlocked(all),'Historical full runs recover the trophy')
 Profile.scores={{world=1,name=Profile.name,country=Profile.country,time=120,deaths=42,skin=2}};Profile.stats.deaths=42;Profile.character=2
 assert(D.apply(true));assert(#Profile.scores==1 and Profile.scores[1].time==120 and Profile.stats.deaths==42 and Profile.character==2,'Unlock preserves scores, stats and equipped skin')
 Profile.load();Hardcore.load();Bestiary.load()
 for _,a in ipairs(Achievements.list) do assert(Achievements.unlocked(a),'Developer unlock persists: '..a.id) end
 for _,index in ipairs(Characters.baseIndices) do assert(Characters.unlocked(index)) end
 Online.enabled=true;Online.start(1,'QA',1,false);assert(not Online.current,'Developer runs stay local');Online.enabled=false
 local slots=require('menu_trophies').slots()
 assert(#slots==3 and slots[1].achievement.id=='worlds_all' and slots[2].achievement.id=='flawless_all' and slots[3].achievement.id=='hardcore_all')
 local O=require('breathing_bubble')
 for _,dir in ipairs({'down','up','left','right'}) do
  local x,y,r=O.headPosition(400,300,100,dir,10)
  local lx,ly=O.lanternPosition(x,y,r,0,dir);assert(lx==x and ly<y,'Luminous tip centered on the head')
  assert(Art.images[Characters.model(dir,12)],'Partner art loaded in every direction')
 end
 assert(Characters.model('down',12)=='final_partner')
 local B=Bestiary
 assert(#B.variants.queen_child==3 and #B.variants.piege==2 and #B.variants.scie==2 and #B.variants.gull==2)
 B.worldFilter=5;local trap=false
 for _,row in ipairs(B.list('traps')) do if row.entry.id=='piege' then trap=true end end
 assert(trap,'Earth filter includes brown trap variant');B.worldFilter=nil
 B.open('electric_gull');assert(B.entries[UI.bestSelected].id=='gull' and UI.bestVariant==2)
 local g=love.graphics
 local canvas=g.newCanvas(1200,960,{dpiscale=1})
 local function save(file)
  local data=canvas:newImageData();data:encode('png',file..'.png');data:release()
 end
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.17,.15,.12)
 for row,index in ipairs({10,6,7,12}) do
  local y=100+(row-1)*225
  UI.rawText(Characters.names[index],22,y-10,'body',{1,1,1},150)
  for col,dir in ipairs({'down','up','left','right'}) do
   local x=280+(col-1)*250
   Characters.shadow(x,y,165,dir);g.setColor(1,1,1);Characters.portrait(index,x,y,165,dir)
  end
 end
 g.pop();save('visual-progress-skins')
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.10,.08,.06)
 local row=0
 for _,id in ipairs({'piege','scie','queen_child','gull','earth_tunnel'}) do
  local entry;for _,e in ipairs(B.entries) do if e.id==id then entry=e end end
  row=row+1;local y=90+(row-1)*170
  for col=1,#(B.variants[id] or {entry}) do
   local a=B.appearance(entry,col);UI.bestiaryIcon(a,220+(col-1)*350,y,115)
   UI.rawText(a.name,70+(col-1)*350,y+60,'body',{1,1,1},300,'center')
  end
 end
 g.pop();save('visual-progress-bestiary');canvas:release()
 LevelLayouts.disabled=true;App.sessionLayout=nil;App.practice=nil;App.singleLevel=false;App.hardcore=false
 Campaign.select(3);player.level=1;reset_level();App.state='playing'
 local F=require('final_spider');F.x=400;F.y=220;player.x=400+160-15;player.y=220-12
 F.update(.01);assert(F.engaged and F.phase=='intro_jump','Initial encounter reacts from farther away')
 F.reset(true);F.engaged=true;F.phase='webs';F.x=400;F.y=220;F.shot=100
 F.update(.01);assert(F.phase=='intro_jump','Combat proximity also uses increased jump radius')
 F.update(.9);assert(F.landed,'Landing creates a visual impact')
 -- Capture the real screens and scene, with no focus change.
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=UI.clock+.016
  if tick==1 then App.state='menu';Characters.browsed=10;App.capture='visual-progress-menu.png'
  elseif tick==3 then App.state='settings';UI.settingsPage='general';App.capture='visual-progress-settings.png'
  elseif tick==5 then B.open('queen_child');App.capture='visual-progress-page.png'
  elseif tick==7 then
   Campaign.select(5);player.level=4;reset_level();App.state='playing';Profile.character=8;Characters.browsed=nil
   spawn_piege(Arena.width*.4,300);spawn_scie(Arena.width*.65,420,1,1,'up');setup_rotor(mobs[#mobs]);static_mob(mobs[#mobs-1])
   App.capture='visual-progress-earth.png'
  elseif tick==9 then
   Campaign.select(3);player.level=1;reset_level();App.state='playing';F.engaged=true;F.phase='webs';F.carried=12;F.landed={x=F.x,y=F.y,at=F.clock-.2}
   App.capture='visual-progress-queen.png'
  elseif tick==11 then
   assert(D.apply(false));Profile.load();Hardcore.load();Bestiary.load()
   for _,kind in ipairs({'hardcore','gold','heartbreak'}) do assert(not E.unlocked(kind),'Reset removes every effect') end
   assert(not next(Profile.completed) and not next(Profile.scores) and not next(Bestiary.seen))
   D.available=available
   print('PASS visual/progress: reset + unlock persistence, effects gated, three ordered trophies, seven hardcore worlds, centered lantern, partner poses, bestiary variants, enlarged queen leap, rendered screens and Earth scene')
   love.event.quit()
  end
 end
end
return T
