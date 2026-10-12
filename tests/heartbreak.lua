local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 local save=Profile.save;Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.sessionLayout=nil;App.workshopMap=nil;App.preview=false;App.singleLevel=false;App.practice=nil;App.hardcore=false;Secret.duel=nil
 Profile.completed={};Profile.scores={};Profile.achievements={};Profile.storyTexts={};Profile.character=1;Hardcore.completed={}
 local E=Ending;local N=require('achievement_notice');local R=require('skin_unlock');local X=require('skin_extension')
 local function reunion(practice)
  App.singleLevel=practice==true;App.practice=practice and 2 or nil
  Campaign.select(3);player.level=2;reset_level();App.state='playing';player.reset=false
  player.x=75;player.y=500;E.partner.x=Arena.width-110;E.partner.y=150
 end
 for _,flag in ipairs({'singleLevel','practice','preview','sessionLayout','workshopMap'}) do
  App[flag]=true;assert(not Achievements.award('heartbreak'),'No achievement in '..flag)
  Profile.complete(1,60,0);Hardcore.complete(1)
  assert(not Profile.hasCompleted(1) and not Hardcore.completed['1'],'No completion rewards in '..flag)
  App[flag]=nil
 end
 Secret.duel={};assert(not Achievements.award('heartbreak'));Secret.duel=nil
 Replay.playing=true;assert(not Achievements.award('heartbreak'));Replay.playing=false
 reunion(true);E.clock=30;E.update(.01)
 assert(E.phase=='depart' and not X.unlocked(),'Training has the same departure without its reward')
 E.partner.y=-71;E.update(.01);assert(App.state=='credits' and not Profile.hasCompleted(3))
 reunion(false);E.clock=29.9;player.x=E.partner.x-15;player.y=E.partner.y-12;E.update(.01)
 assert(App.state=='credits' and not X.unlocked(),'Touching the white spider finishes without heartbreak')
 Profile.completed={};Profile.scores={};Profile.achievements={};N.init();R.init()
 reunion(false);E.clock=29.98;E.update(.01)
 assert(not X.unlocked() and E.phase=='approach','No early award')
 E.partner.x=Arena.width-110;E.partner.y=150;E.update(.02)
 assert(X.unlocked() and E.phase=='depart','Thirty seconds without contact unlocks heartbreak')
 N.update(.01);R.update(.01)
 assert(N.active and N.active.entry.id=='heartbreak' and not R.active and not R.toast)
 local before=E.partner.y;E.update(.1);assert(E.partner.y<before,'The white spider visibly leaves upwards')
 E.partner.y=-71;E.update(.01);assert(App.state=='credits')
 N.update(.01);R.scanTime=0;R.update(.01)
 assert(N.visible() and not R.toast and not R.active,'Achievement remains visible during credits and precedes rewards')
 for _=1,200 do N.update(.1);R.update(.1);if R.toast then break end end
 assert(R.toast and R.toast.index=='heartbreak' and not N.active and App.state=='credits','Extension follows achievements without interrupting credits')
 local clock=E.creditTime;E.updateCredits(.2);assert(E.creditTime>clock)
 R.update(3.7);assert(R.toast and type(R.toast.index)=='number','Newly earned skin follows the extension')
 assert(not Profile.tearExtension);X.toggle();assert(Profile.tearExtension);X.toggle();assert(not Profile.tearExtension)
 local files={};for _,name in ipairs({'profile.txt','scores.tsv','hardcore-scores.json','score_details.json'})do files[name]=love.filesystem.read(name) or false end
 Profile.tearExtension=true;save();Profile.achievements={};Profile.tearExtension=false;Profile.load()
 assert(X.unlocked() and Profile.tearExtension,'Achievement and extension preference survive reload')
 for name,data in pairs(files)do if data then love.filesystem.write(name,data)else love.filesystem.remove(name)end end
 Profile.completed={};Profile.scores={};Profile.achievements={heartbreak=true};Profile.character=5;Characters.browsed=nil
 Characters.cycle(1);assert(Characters.menuIndex()==6 and Characters.selected()==5,'Locked skins can be browsed without equipping')
 Characters.cycle(-1);assert(Characters.menuIndex()==5 and Characters.selected()==5)
 App.state='menu';UI.clock=0;UI.menuArrival=nil
 local _,start=UI.menuPosition();UI.clock=1.6;local _,mid=UI.menuPosition();UI.clock=3.2;local _,finish=UI.menuPosition()
 assert(start<0 and mid>start and mid<finish and finish>230,'Menu spider descends progressively from above')
 UI.draw();local gallery
 for _,b in ipairs(UI.buttons)do if b.w==210 and b.h==190 then gallery=b end end
 assert(gallery);gallery.run();assert(App.state=='skins');UI.draw()
 assert(#UI.buttons==Characters.baseCount+1,'Gallery includes every skin and a return button')
 assert(UI.buttons[6].disabled and not UI.buttons[1].disabled)
 UI.buttons[1].run();assert(App.state=='menu' and Characters.selected()==1)
 -- Verify that locked portraits contain a solid black silhouette, with no colored artwork.
 local g=love.graphics;local canvas=g.newCanvas(256,256)
 g.push('all');g.setCanvas(canvas);g.clear(0,0,0,0);g.setColor(1,1,1);Characters.portrait(15,128,128,220,'down',true);g.pop()
 local data=canvas:newImageData();local black,question=0,0
 for y=0,255 do for x=0,255 do local r,green,b,a=data:getPixel(x,y)
  if a>.9 then if r<.01 and green<.01 and b<.01 then black=black+1 else question=question+1;assert(math.abs(r-b)<.1,'No skin colors leak through the lock')end end
 end end
 assert(black>1000 and question>50,'Black silhouette and question mark are both visible')
 data:release();canvas:release()
 print('PASS heartbreak timing, contact/departure endings, practice/replay exclusion, persistent extension, ordered credits rewards, locked browsing, all-skins gallery and progressive silk arrival')
 N.init();R.init();local draw=love.draw;local frame=0
 love.update=function()
  frame=frame+1;UI.clock=2.4
  if frame==1 then App.state='menu';UI.menuArrival=2.4
  elseif frame==2 then UI.menuArrival=.8
  elseif frame==3 then UI.menuArrival=-2
  elseif frame==4 then Characters.select(6)
  elseif frame==5 then App.state='skins'
  elseif frame==6 then E.startCredits();E.creditTime=3;N.active={entry=Achievements.list[1],age=1}
  elseif frame==7 then N.active=nil;R.toast={index='heartbreak',age=1}
  else love.event.quit()end
 end
 love.draw=function()
  draw();if frame<=7 then g.captureScreenshot(function(image)local f=assert(io.open('/tmp/silken-heartbreak-'..frame..'.png','wb'));f:write(image:encode('png'):getString());f:close()end)end
 end
end
return T
