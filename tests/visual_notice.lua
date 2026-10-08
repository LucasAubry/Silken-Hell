local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;App.preview=false;LevelLayouts.disabled=true
 Profile.language='fr';Profile.achievements={};Profile.completed={};Profile.scores={}
 local N=require('achievement_notice');local D=require('discovery_notice');local C=require('run_start');local json=require('json')
 App.state='menu';N.init();N.update(.1);assert(not N.active,'Existing profile is the baseline')
 local before=json.encode(Profile.achievements);N.test();N.update(.4);love.draw()
 assert(N.active.preview and json.encode(Profile.achievements)==before,'Test never unlocks achievements')
 N.active=nil;Profile.achievements.gillou=true;N.update(.01)
 assert(N.active.entry.id=='gillou' and not N.active.preview,'Real achievement shows a notice')
 N.update(.1);assert(#N.queue==0,'Only one notice per unlock')
 N.active=nil;Replay.playing=true;Profile.achievements.maxance=true;N.update(.1)
 assert(not N.active and #N.queue==0,'Replay never announces unlocks');Profile.achievements.maxance=nil;Replay.playing=false
 Profile.completed[2]=true;N.update(.1);assert(N.active.entry.id=='world2','World completion uses the same queue')
 N.init();N.update(.1);assert(not N.active,'Previously unlocked successes stay silent')
 App.hardcore=false;App.practice=nil;App.singleLevel=false;App.sessionLayout=nil;App.start(1)
 N.test();N.update(.5);assert(N.active.age==0,'Countdown defers cards')
 C.press(Profile.keys.dash);N.update(.4)
 D.test();D.active.preview=false
 local card=require('notice_card');local render=card.draw;local slots={}
 card.draw=function(age,heading,name,detail,icon,slot)slots[#slots+1]=slot or 0;render(age,heading,name,detail,icon,slot)end
 D.draw();N.draw();card.draw=render
 assert(slots[1]==1 and slots[2]==0 and card.y<110,'Discovery and achievement stack at the top right')
 local circle,arc=love.graphics.circle,love.graphics.arc;local circles=0
 love.graphics.circle=function(...)circles=circles+1;return circle(...)end
 love.graphics.arc=function(...)circles=circles+1;return arc(...)end
 C.active=true;C.elapsed=.2;C.draw();assert(circles==0 and C.font:getHeight()<32 and C.keyLabel()~='' ,'Start prompt shows a key without a countdown circle')
 love.graphics.circle,love.graphics.arc=circle,arc;C.active=false;C.goAge=1
 local L=require('localization')
 for _,language in ipairs(L.options)do
  Profile.language=language.code;C.goAge=0;C.draw();assert(C.font:hasGlyphs(L.text('Appuie pour démarrer')))
  for _,key in ipairs({'TEST SUCCÈS','SUCCÈS DÉBLOQUÉ','APERÇU · SUCCÈS DÉBLOQUÉ','Ajouté à vos succès'})do assert(L.has(key,language.code))end
 end
 Profile.language='fr';C.goAge=1
 for _,world in ipairs({1,2,4,5,6,7})do
  App.practice=1;App.singleLevel=true;App.start(world)
  local originalMobs=mobs;local carrier={type='qa'};mobs={carrier,{type='piege'}}
  local tear,mob,actor=Campaign.drawTear,Campaign.drawMob,draw_player;local order={}
  Campaign.drawTear=function(...)order[#order+1]='tear';tear(...)end
  Campaign.drawMob=function(m)order[#order+1]=m.type=='piege' and 'trap' or 'monster'end
  draw_player=function(...)order[#order+1]='player';actor(...)end
  Campaign.carrier=carrier;objet.larme_dropped=false;love.draw()
  assert(table.concat(order,',')=='trap,tear,monster,player','Carried tear layering in biome '..world..': '..table.concat(order,','))
  order={};objet.larme_dropped=true;love.draw()
  assert(table.concat(order,',')=='trap,monster,tear,player','Free tear layering in biome '..world)
  order={};Aftermath.cleared=true;love.draw()
  assert(table.concat(order,',')=='trap,monster,tear,player','Boss reward draws once, before player')
  Campaign.drawTear,Campaign.drawMob,draw_player=tear,mob,actor;mobs=originalMobs
 end
 App.start(1);player.level=10;reset_level()
 local shadow,contact=Art.shadow,Art.contactShadow;local copied,ellipses=0,0
 Art.shadow=function(...)copied=copied+1;return shadow(...)end
 require('mobs.bosses.raven.egg').draw(400,300,60,0)
 assert(copied==0,'Egg sprite has no duplicate silhouette shadow')
 Art.contactShadow=function(...)ellipses=ellipses+1;return contact(...)end
 Raven.draw();assert(ellipses==1,'Egg boss has exactly one soft contact shadow')
 Art.shadow,Art.contactShadow=shadow,contact
 print('PASS visual revision: achievement preview/unlock/replay/baseline, stacked top-right cards, smooth compact countdown, six-biome carried/free/reward layers, single egg shadow')
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=30+tick*.2
  if tick==1 then N.test();N.update(.4);D.active=nil;App.capture='revision-egg-success.png'
  elseif tick==2 then App.singleLevel=false;App.practice=nil;App.start(1);C.elapsed=.25;App.capture='revision-small-countdown.png'
  elseif tick==3 then C.active=false;C.goAge=1;N.test();N.update(.4);D.test();D.active.preview=false;D.active.age=.4;App.capture='revision-notices.png'
  elseif tick==4 then App.state='menu';N.test();N.update(.4);D.active=nil;App.capture='revision-success-menu.png'
  elseif tick==5 then print('PASS visual captures');love.event.quit()end
 end
end
return T
