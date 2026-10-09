local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.state='playing';Campaign.select(3);player.level=1;reset_level();player.reset=false;require('run_start').active=false
 local F=require('final_spider');local Q=require('queen_escape')
 local move,slow=Input.move,Input.slow;local x=0
 Input.move=function() return x,0 end;Input.slow=function()return true end
 F.reset(true);F.engaged=true;F.trap(player)
 for i=1,20 do x=1;F.clock=F.clock+.02;Q.struggle(F,.02)end
 assert(F.snare>0 and not F.cornerPending,'Holding a key cannot free the player')
 F.escapeTaps={};F.escapeHeld={};F.clock=1
 for i=1,12 do x=i%2==0 and -1 or 1;F.clock=F.clock+.08;Q.struggle(F,.08) end
 assert(F.enraged and #F.silkBits>0,'Escape turns eyes red and sheds silk')
 assert(F.snare==0 and F.cornerPending and F.phase=='recover' and not F.target,'Fast inputs free player and cancel attack')
 F.phase='lay';F.batch=0;F.phaseTime=0;F.carried=24;player.x=100;player.y=300;Q.beginLay(F)
 assert(F.cornerLay and not F.cornerPending,'Next laying phase consumes the pending reaction')
 F.x,F.y=F.nest.x,F.nest.y;F.contactGrace=100;F.cornerReady=true
 for i=1,140 do F.phaseTime=F.phaseTime+.04;Q.lay(F,.04,function()error('Stationary queen must not flee')end) end
 assert(not F.enraged,'Red eyes end with the special clutch')
 assert(F.carried==0 and #F.eggs==24 and not F.cornerLay and F.phase=='webs','Entire clutch is laid once, then normal behavior resumes')
 assert(#F.webs>0,'Queen fires webs while laying')
 for i,a in ipairs(F.eggs)do for j,b in ipairs(F.eggs)do if i~=j then assert((a.x-b.x)^2+(a.y-b.y)^2>=44^2,'Eggs do not overlap') end end end
 F.carried=24;Q.beginLay(F);assert(not F.cornerLay,'Following phase returns to normal')
 F.reset(true);F.engaged=true;F.phase='charge';F.target=player;F.snare=2;F.clock=0
 for i=1,12 do x=i%2==0 and -1 or 1;F.clock=i*.3;Q.struggle(F,.3)end
 assert(F.snare>0 and not F.cornerPending,'Slow presses cannot escape')
 for i=1,12 do x=i%2==0 and -1 or 1;F.clock=F.clock+.08;Q.struggle(F,.08)end
 assert(F.phase=='recover' and F.snare==0,'Escape also interrupts an active charge')
 F.reset(true);assert(not F.cornerPending and not F.cornerLay,'Retry resets special phase')
 Input.move,Input.slow=move,slow
 print('PASS queen escape cadence, no held-key escape, charge cancellation, one-shot corner clutch, non-overlapping eggs and simultaneous webs')
 local frame=0
 love.update=function()
  frame=frame+1
  if frame==1 then
   F.reset(true);F.engaged=true;F.phase='aim';F.chargeX=player.x+15;F.chargeY=player.y+12
   F.enraged=true;F.snare=1;F.clock=2;F.escapeTaps={1,1,1,1,1,1,1,1};F.webShake=.17;Q.shed(F,12)
   App.capture='queen-rage-silk.png'
  elseif frame==3 then love.event.quit() end
 end
end
return T
