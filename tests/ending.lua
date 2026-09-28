local T={}
local function reset(world,n)
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;App.hardcore=false;LevelLayouts.disabled=true
 Campaign.select(world);player.level=n;reset_level();App.state='playing';player.reset=false
end
function T.run()
 io.stdout:setvbuf('no')
 assert(Worlds.levelCount(3)==2 and #Campaign.data[3]==2,'Renaissance contains two levels')
 reset(3,1);assert(Ending.active and Ending.pending and #mobs==0 and not Renaissance.active and not Bosses.alive(),'Final boss slot reserved without inventing a fight')
 assert(Ending.locked() and objet.larme.taken,'Reserved slot cannot be won as an empty scored level')
 Ending.openReunion();assert(player.level==2 and Ending.active and not Ending.pending,'Reunion accessible for preview')
 assert(#mobs==0 and #Arena.walls==4 and not Renaissance.active,'Reunion has no monsters or obstacles')
 assert(#Ending.children==3 and Ending.children[1].white and Ending.children[2].white and not Ending.children[3].white,'Two white daughters and one brown son')
 for _,c in ipairs(Ending.children) do assert(c.spots) end
 local before=Ending.phase;Ending.update(.1);assert(Ending.phase==before and not Ending.family,'No premature reveal')
 player.x=Ending.partner.x-15;player.y=Ending.partner.y-12;Ending.update(.01)
 assert(Ending.phase=='fadeOut' and Ending.locked(),'Approach triggers fade and locks movement')
 Ending.update(1.3);assert(Ending.fade==1 and Ending.family and Ending.phase=='black','Family appears only behind full black')
 Ending.update(1);Ending.update(1.9)
 assert(Ending.fade==0 and Ending.phase=='family','Fade back reveals family')
 local count=0;local spider=Ending.spider;Ending.spider=function() count=count+1 end
 Ending.drawPlayer();Ending.drawFamily();Ending.spider=spider
 assert(count==5,'Both parents and exactly three children rendered')
 local x=Ending.partner.x;Ending.resize(1.2);assert(Ending.partner.x==x*1.2,'Partner follows resize')
 reset(2,9);Aftermath.cleared=true;assert(not Ending.checkHellVictory(),'No credits before Hell boss')
 reset(2,10);assert(not Ending.checkHellVictory(),'No credits while boss alive')
 local complete,checkpoint=Profile.complete,Online.checkpoint;local completed,sent=0,0
 Profile.complete=function(w) assert(w==2);completed=completed+1 end
 Online.checkpoint=function(n) assert(n==10);sent=sent+1 end
 Wasp.defeated=true;objet.larme.taken=false;App.simulate(.01)
 assert(Ending.creditsStarted and App.state=='credits','Hell boss defeat starts credits automatically through gameplay')
 assert(not Ending.checkHellVictory() and completed==1 and sent==1,'Completion recorded exactly once')
 Profile.complete=complete;Online.checkpoint=checkpoint
 assert(Ending.credits[5][2]=='Aubry Lucas\nAmir' and Ending.credits[6][2]=='Gilloux\nMaxance\nAmir\nNils','Requested credits preserved')
 assert(Ending.aiNotice:find('intelligence artificielle',1,true),'AI notice included')
 assert(Ending.creditDuration()>18 and Ending.creditDuration()<21,'Compact credits finish in about 19 seconds')
 local start=App.start;local destination
 App.start=function(w) destination=w;App.state='playing' end
 Ending.updateCredits(Ending.creditDuration()-7);assert(destination==nil and not Ending.previewCredits and not Ending.drawCreditControls,'Credits continue without monster or preview controls')
 Ending.updateCredits(8);assert(destination==3,'Completed credits lead to reserved final biome')
 App.start=start
 reset(7,10);assert(not Ending.active and Abyss.boss,'Other biomes unchanged')
 print('PASS ending: two levels, reserved boss, peaceful reunion, fade, five family members, resize, Hell victory credits once, requested names, AI note, compact credits without monster, Renaissance transition')
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1
  if frame==1 then reset(3,1);App.capture='ending-reserved.png'
  elseif frame==3 then Ending.openReunion();App.capture='ending-reunion.png'
  elseif frame==5 then player.x=Ending.partner.x-15;player.y=Ending.partner.y-12;Ending.update(.01);Ending.update(1.3);App.capture='ending-black.png'
  elseif frame==7 then Ending.update(1);Ending.update(1.9);Ending.update(3);App.capture='ending-family.png'
  elseif frame==9 then Ending.startCredits();Ending.creditTime=10;App.capture='ending-credits.png'
  elseif frame==11 then Ending.creditTime=Ending.creditDuration()-4;App.capture='ending-compact-final.png'
  elseif frame==13 then love.event.quit() end
 end
end
return T
