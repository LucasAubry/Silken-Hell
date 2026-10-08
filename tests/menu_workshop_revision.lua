local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;App.preview=false;LevelLayouts.disabled=true
 Profile.language='fr';Profile.completed={};Profile.levels={};Profile.name='Workshop QA'
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Profile.levels[w]=10 end
 local N=require('discovery_notice');local json=require('json')
 Bestiary.seen={};Bestiary.unread={};N.queue={};N.active=nil
 App.hardcore=false;App.start(2)
 assert(#N.queue>0,'A real first encounter queues a notice')
 local first=N.queue[1];local count=#N.queue
 assert(not Bestiary.discover(first.id) and #N.queue==count,'Repeated encounters do not repeat notices')
 require('run_start').press(Profile.keys.dash)
 N.update(.01);assert(N.active and not N.active.preview)
 local before=json.encode(Bestiary.seen);App.state='menu';N.test();N.update(.5)
 assert(json.encode(Bestiary.seen)==before and N.active.preview,'Preview preserves discoveries')
 local L=require('localization')
 for _,language in ipairs(L.options) do
  Profile.language=language.code
  for _,label in ipairs({'TEST DÉCOUVERTE','APERÇU · NOUVELLE DÉCOUVERTE','NOUVELLE DÉCOUVERTE','Ajoutée au bestiaire','Aperçu sans déblocage','Étoiles : votes des joueurs','Les plus aimées','Préparer pour Steam','Export impossible.','Export prêt. La connexion Steamworks reste à configurer.','Une étoile = un vote positif.'}) do
   assert(L.has(label,language.code) and UI.fonts.tiny:hasGlyphs(L.text(label)),'New label translated with font coverage: '..language.code..' '..label)
  end
  love.draw()
 end
 Profile.language='fr'
 Bestiary.unread={rebirth_bush=true,walking_tree=true,white_spider=true}
 assert(not Bestiary.pending(),'Retired creatures do not leave an unread badge')
 for _,e in ipairs(Bestiary.entries) do assert(e.id~='rebirth_bush' and e.id~='walking_tree' and e.id~='white_spider') end
 assert(Bestiary.discover('skeleton_head') and Bestiary.seen.skeleton_fish,'Abyss head uses the real boss entry')
 Replay.playing=true;local absent=Bestiary.entries[#Bestiary.entries].id;Bestiary.seen[absent]=nil
 assert(not Bestiary.discover(absent),'Replay must not unlock creatures');Replay.playing=false
 local rows={{id='qa',title='La traversée des marées',author='Créateur QA',world=4,biome=4,difficulty=3,stars=27,starred=true},
 {id='qa2',title='Au-dessus des nuages',author='Nuage',world=6,biome=6,difficulty=2,stars=9,starred=false}}
 local requests={};Online.request=function(path,body,callback) requests[#requests+1]=path;callback({maps=rows,hasMore=false},200) end
 Workshop.open();love.draw()
 UI.click(270,213);love.draw();assert(Workshop.dropdown and #UI.buttons==8,'Biome list contains all plus seven worlds')
 local d=Workshop.dropdown;UI.click(d.x+100,d.bounds.y+6+3*35+16)
 assert(not Workshop.dropdown and Workshop.filterBiome==Worlds.order[3] and requests[#requests]:find('biome='..Worlds.order[3],1,true),'Biome selection refreshes the filter')
 love.draw();UI.click(570,213);love.draw();assert(#UI.buttons==6,'All plus five difficulties')
 d=Workshop.dropdown;UI.click(d.x+90,d.bounds.y+6+4*35+16)
 assert(Workshop.filterDifficulty==4 and not Workshop.dropdown,'Difficulty selection')
 love.draw();UI.click(270,213);love.draw();local nr=#requests
 UI.click(1050,169);assert(not Workshop.dropdown and #requests==nr,'Outside click closes without clicking through')
 love.draw();UI.click(270,213);love.draw();love.keypressed('escape')
 assert(App.state=='workshop' and not Workshop.dropdown,'Escape closes only the dropdown')
 local layout={world=4,level=1,biome=4,difficulty=3,width=960,height=600,entities={{kind='spawn',x=100,y=300},{kind='tear',x=750,y=300}}}
 Workshop.publishing=true;Workshop.localRows={{key='4:1',layout=layout}};Workshop.localPage=1;Workshop.selectLocal(Workshop.localRows[1]);Workshop.author='QA'
 Workshop.validated={hash=Replay.hash(Workshop.materialize()),build=Replay.build()}
 assert(Workshop.canPublish());love.draw();UI.click(750,311);love.draw();assert(#UI.buttons==5);love.keypressed('escape')
 local openURL=love.system.openURL;love.system.openURL=function()return true end;Workshop.exportSteam();love.system.openURL=openURL
 local folder='steam-workshop/'..Replay.hash(Workshop.materialize())
 local manifest=json.decode(assert(love.filesystem.read(folder..'/manifest.json')))
 local content=json.decode(assert(love.filesystem.read(folder..'/'..manifest.content)))
 assert(manifest.version==1 and manifest.tags[2]=='biome:4' and manifest.sha256==Replay.hash(content) and LayoutSchema.validate(content),'Steam preparation exports portable validated content')
 assert(not require('workshop_content').export({},'Invalid','QA'),'Invalid map is rejected')
 -- Check ignition ordering at real screen pixels on a transparent canvas.
 local g=love.graphics;local canvas=g.newCanvas(1200,750)
 App.state='menu';WorldMap.hardcore=true;Hardcore.borderState=nil;UI.clock=100
 local function border(t)
  UI.clock=t;g.setCanvas(canvas);g.clear(0,0,0,0);Hardcore.drawBorder(1200,750);g.setCanvas();return canvas:newImageData()
 end
 border(100);local early=border(100.1);local _,_,_,center=early:getPixel(600,1);local _,_,_,corner=early:getPixel(1,1);local _,_,_,side=early:getPixel(1,375)
 assert(center>.5 and corner<.01 and side<.01,'Ignition starts at top center, before corners and sides')
 local _,_,_,bottom=early:getPixel(600,748);assert(bottom>.5,'Bottom center ignites simultaneously')
 local finished=border(100.7);local _,_,_,full=finished:getPixel(1,375);assert(full>.5,'Full border lights within 0.7 seconds')
 local art=require('final_art');local spider=art.spider;local queens=0
 art.spider=function(kind,...)if kind=='queen' then queens=queens+1 end;return spider(kind,...) end
 App.selectedWorld=3;WorldMap.open();love.draw();art.spider=spider
 assert(queens==1,'Exactly one real red queen orbits Renaissance')
 print('PASS menu/workshop: modal dropdowns, filters, preview without unlock, first encounters, retired entries, Steam content, ignition ordering, single queen')
 Workshop.publishing=false;Workshop.dropdown=nil;Workshop.filterBiome=0;Workshop.filterDifficulty=0;Workshop.rows=rows;Workshop.status=''
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=200+tick*.15
  if tick==1 then App.state='menu';App.selectedWorld=1;WorldMap.hardcore=true;Hardcore.borderState=nil;N.test();N.update(.5);App.capture='revision-menu-ignition-start.png'
  elseif tick==2 then App.capture='revision-menu-ignition-mid.png'
  elseif tick==6 then App.capture='revision-menu-notice.png'
  elseif tick==7 then App.state='workshop';App.hardcore=false;App.capture='revision-workshop.png'
  elseif tick==8 then UI.click(270,213);Workshop.dropdown.opened=UI.clock-.2;App.capture='revision-workshop-biomes.png'
  elseif tick==9 then love.keypressed('escape');love.draw();UI.click(570,213);Workshop.dropdown.opened=UI.clock-.2;App.capture='revision-workshop-difficulties.png'
  elseif tick==10 then Workshop.dropdown=nil;Workshop.publishing=true;App.capture='revision-workshop-publish.png'
  elseif tick==11 then App.state='rankings';UI.boardWorld=1;UI.boardHardcore=false;UI.boardLocal=true;UI.boardPage=1;App.capture='revision-rankings.png'
  elseif tick==12 then App.selectedWorld=3;WorldMap.hardcore=false;WorldMap.open();App.capture='revision-map-queen.png'
  elseif tick==13 then WorldMap.hardcore=true;App.selectedWorld=7;App.state='menu';Hardcore.borderState={value=1,target=1,at=UI.clock};App.capture='revision-menu-abyss.png'
  elseif tick==14 then print('PASS visual captures');love.event.quit() end
 end
end
return T
