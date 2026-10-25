local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.recording=false
 local H=require('history');local B=require('egg_boss_arrival')
 local seen,save=Profile.transitionsSeen,Profile.save;Profile.transitionsSeen={};local writes=0;Profile.save=function()writes=writes+1 end
 local scenes=H.visibleScenes('boss');assert(#scenes==1 and scenes[1].id=='boss_egg','Egg button is available before viewing the movie')
 H.open();UI.buttons={};H.draw()
 local button;for _,b in ipairs(UI.buttons)do if b.text=='L’Œuf du Merle' or b.label=='L’Œuf du Merle' then button=b end end
 assert(#UI.buttons>=2,'History offers the egg movie and Back')
 local world,level=Campaign.world,player.level;local rng=love.math.getRandomState()
 H.play('boss_egg');assert(B.active and H.bossPreview=='egg')
 local ticks=0;while App.historyPreview do H.update(.05);ticks=ticks+1;assert(ticks<140)end
 assert(App.state=='history' and not B.active and Campaign.world==world and player.level==level)
 assert(writes==0 and love.math.getRandomState()==rng,'History preserves progress and simulation RNG')
 H.play('boss_egg');H.close();assert(not B.active and not App.historyPreview,'Back cancels the movie')
 Profile.transitionsSeen=seen;Profile.save=save
 local g=love.graphics;local c=g.newCanvas(720,280);g.push('all');g.setCanvas(c);g.clear(.12,.14,.19,1)
 for i,dir in ipairs({'down','up','left'})do g.setColor(1,1,1);Characters.portrait(10,120+(i-1)*240,130,170,dir)end
 g.setCanvas();g.pop();local d=c:newImageData();d:encode('png','lantern-rework.png');d:release();c:release()
 print('PASS egg History button, playback, Back, progress isolation and three lantern poses')
 love.event.quit()
end
return T
