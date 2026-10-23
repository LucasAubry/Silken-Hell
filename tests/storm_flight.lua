local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false
 Profile.save=function()end;Profile.record=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end
 local F=require('mobs.bosses.storm.flight');local oldWidth=Arena.width
 for _,width in ipairs({720,960,1500})do
  Arena.width=width
  for _,target in ipairs({{30,30},{width-60,30},{30,540},{width-60,540},{width/2,300}})do
   player.x,player.y=target[1],target[2]
   local s={x=width/2,y=155,angle=0,vx=650,vy=0,flightSpeed=650,wave=4}
   F.aim(s)
   local straight=0
   for i=1,3600 do
    local x,y,a,v=s.x,s.y,s.angle,s.flightSpeed;F.update(s,1/120)
    local da=(s.angle-a+math.pi)%(2*math.pi)-math.pi
    assert(math.abs(da)<=2.6/120+.00001,'Bounded turning rate')
    assert(math.abs(s.flightSpeed-v)<=650/120+.001,'No sudden speed change')
    assert(math.abs((s.x-x)*math.sin(s.angle)-(s.y-y)*math.cos(s.angle))<.001,'Bird flies nose first')
    assert(s.x>25 and s.x<width-25 and s.y>25 and s.y<575,'Curved turns stay in the arena: '..width..' '..s.x..','..s.y)
    if math.abs(da)<.001 then straight=straight+1 end
   end
   assert(straight>100,'Straight runs remain between turns: '..width..' '..target[1]..','..target[2]..' straight='..straight)
  end
 end
 Arena.width=oldWidth
 local sweep=require('mobs.bosses.storm.sweep')
 local s={x=480,y=300,angle=.5,holes={},fogAmount=1,fogTarget=1,groundRevision=0}
 sweep.begin(s);local elapsed=0;local done=false;local turns=0
 while not done do
  done=sweep.update(s,1/120);elapsed=elapsed+1/120
  if s.cleanStage=='approach' and s.cleanIndex>1 then
   assert(s.x<0 or s.x>Arena.width,'U-turn remains outside the map')
   turns=turns+1
  end
 end
 assert(turns>0 and math.abs(elapsed-1.5)<.01,'Curved clearing still takes 1.5 seconds')
 print('PASS Merle natural flight: 15 long routes, bounded heading and acceleration, nose-first motion, straight runs, smooth offscreen U-turns, 1.5 second clearing')
 love.event.quit()
end
return T
