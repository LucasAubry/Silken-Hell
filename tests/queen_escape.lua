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
 for i=1,140 do if F.cornerLay then F.phaseTime=F.phaseTime+.04;Q.lay(F,.04,function()error('Stationary queen must not flee')end) end end
 assert(not F.enraged,'Red eyes end with the special clutch')
 assert(F.carried==16 and #F.eggs==8 and not F.cornerLay and F.phase=='webs','Special clutch lays eight eggs and preserves the remaining stock')
 assert(#F.webs>0,'Queen fires webs while laying')
 for i,a in ipairs(F.eggs)do for j,b in ipairs(F.eggs)do if i~=j then
  assert((a.x-b.x)^2+(a.y-b.y)^2>=44^2,'Eggs do not overlap')
  assert(math.abs(a.x-b.x)>.01 and math.abs(a.y-b.y)>.01,'Eggs do not form rows or columns')
 end end end
 F.carried=24;Q.beginLay(F);assert(not F.cornerLay,'Following phase returns to normal')
 local width=Arena.width;Arena.width=600
 for _,position in ipairs({{80,120},{480,120},{80,450},{480,450}}) do
  F.reset(true);player.x,player.y=position[1],position[2];F.cornerPending=true;F.carried=3;F.batch=2;Q.beginLay(F)
  local first=F.cornerSlots[1];F.cornerPending=true;Q.beginLay(F)
  assert(first.x==F.cornerSlots[1].x and first.y==F.cornerSlots[1].y,'Same wave and corner reproduce the same scatter')
  F.cornerReady=true
  for i=1,80 do if F.cornerLay then Q.lay(F,.04,function()end) end end
  assert(F.carried==0 and #F.eggs==3 and F.batch==5 and not F.cornerLay,'Partial stock is respected in every corner')
  for _,e in ipairs(F.eggs) do
   assert(e.x>=65 and e.x<=Arena.width-65 and e.y>=95 and e.y<=525,'Scatter stays inside the arena')
   assert((e.x-player.x-15)^2+(e.y-player.y-12)^2>=65^2,'Scatter leaves space around the player')
  end
 end
 F.reset(true);F.cornerPending=true;Q.beginLay(F);F.cornerReady=true
 for _,p in ipairs(F.cornerSlots) do F.eggs[#F.eggs+1]={x=p.x,y=p.y} end
 local occupied=#F.eggs
 for i=1,80 do if F.cornerLay then Q.lay(F,.04,function()end) end end
 assert(not F.cornerLay and F.phase=='webs' and F.carried==24 and #F.eggs==occupied,'Occupied corner exits without consuming eggs or freezing the phase')
 Arena.width=width
 F.reset(true);F.engaged=true;F.phase='charge';F.target=player;F.snare=2;F.clock=0
 for i=1,12 do x=i%2==0 and -1 or 1;F.clock=i*.3;Q.struggle(F,.3)end
 assert(F.snare>0 and not F.cornerPending,'Slow presses cannot escape')
 for i=1,12 do x=i%2==0 and -1 or 1;F.clock=F.clock+.08;Q.struggle(F,.08)end
 assert(F.phase=='recover' and F.snare==0,'Escape also interrupts an active charge')
 F.reset(true);assert(not F.cornerPending and not F.cornerLay,'Retry resets special phase')
 Input.move,Input.slow=move,slow
 print('PASS queen escape cadence, charge cancellation, eight scattered eggs, partial stock, four corners, occupied-corner recovery and simultaneous webs')
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
