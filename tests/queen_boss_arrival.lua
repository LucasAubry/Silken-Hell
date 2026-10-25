local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false
 Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 App.preview=false;App.practice=nil;App.singleLevel=false;App.hardcore=false;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 local B=require('queen_boss_arrival');local F=require('final_spider');local H=require('history');local R=require('run_start')
 local save,seen=Profile.save,Profile.transitionsSeen;local writes=0
 Profile.save=function()writes=writes+1 end;Profile.transitionsSeen={}
 Campaign.select(3);player.level=1;reset_level();App.state='playing';R.begin(false)
 assert(B.active and not B.current(),'Cocoon waits for the biome arrival')
 local arrivalTicks=0
 while R.arrival do R.advance(.05);arrivalTicks=arrivalTicks+1;assert(arrivalTicks<350) end
 assert(B.active and not B.current() and B.age==0,'Cinematic does not advance while the run waits for input')
 assert(R.launch() and B.current() and not F.engaged,'Starting the run launches the cocoon')
 writes=0;assert(R.goAge==nil,'Start prompt clears before the cocoon movie')
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local set=g.setCanvas
  g.push('all');set(c);g.setCanvas=function(target,...)if target==nil then return set(c)end;return set(target,...)end
  love.draw();g.setCanvas=set;set();g.pop();local data=c:newImageData();data:encode('png','queen-arrival-'..name..'.png');data:release();c:release()
 end
 local function advance(t)while B.active and B.age<t-1e-6 do App.simulate(math.min(1/60,t-B.age))end end
 advance(1);capture('descent');advance(3.8);capture('shake');advance(4.6);capture('burst');advance(5.6);capture('trapped')
 assert(B.pose(3).y<F.y and B.projectileSize==require('queen_projectile').size)
 assert(B.captures>1 and F.snare>0 and F.introContact and not F.engaged)
 advance(7.3);assert(not B.active and writes==1)
 assert(B.hitCount==1 and #B.splats>5 and #F.webs==0,'One real shot hits the player; the remaining volley collides with walls')
 local x,y=player.x,player.y;local move,slow=Input.move,Input.slow
 Input.move=function()return 1,0 end;Input.slow=function()return true end
 for _=1,180 do App.simulate(1/60)end
 assert(player.x==x and player.y==y and F.snare>0 and not F.engaged,'Player must struggle; waiting or holding cannot escape')
 for _=1,5 do
  Input.move=function()return 0,0 end;App.simulate(.04)
  Input.move=function()return 1,0 end;App.simulate(.04)
 end
 assert(F.snare==0 and not F.introSnare and not F.engaged,'Repeated direction presses free the player without starting combat')
 Input.move=function()return 0,0 end
 player.x=F.x+100;player.y=F.y;App.simulate(.05)
 assert(not F.engaged,'Proximity alone does not start combat')
 player.x=F.x-15;player.y=F.y-12;App.simulate(.05)
 assert(F.engaged and F.hp==F.maxHp,'Touch starts combat without damaging the queen')
 Input.move=move;Input.slow=slow
 App.respawn();assert(not B.active and F.engaged and F.snare==0,'Retry resumes combat without replaying the cocoon')
 App.state='menu';local rng=love.math.getRandomState();H.play('boss_queen');assert(B.current())
 local ticks=0;while App.historyPreview do love.update(.05);ticks=ticks+1;assert(ticks<180)end
 assert(App.state=='history' and not B.active and writes==1 and love.math.getRandomState()==rng)
 H.play('boss_queen');love.keypressed('escape');assert(not B.active)
 Profile.transitionsSeen={};Campaign.select(3);player.level=1;Replay.playing=true;reset_level();R.active=false;R.arrival=nil
 while B.active do B.update(.05)end
 assert(not Profile.transitionsSeen.boss_queen);Replay.playing=false
 Profile.save=save;Profile.transitionsSeen=seen
 print('PASS Queen cocoon: descent, rupture, player hit, persistent restraint, struggle, contact gate, retry, History and replay isolation')
 love.event.quit()
end
return T
