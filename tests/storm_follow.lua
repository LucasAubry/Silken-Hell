local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 local F=require('mobs.bosses.storm.snail_follow');local flight=require('mobs.bosses.storm.flight')
 local width=Arena.width
 local smallest=math.huge
 for _,w in ipairs({720,960,1500})do Arena.width=w
  for _,target in ipairs({{30,30},{w-60,30},{30,540},{w-60,540},{w/2,300}})do
   player.x,player.y=target[1],target[2]
   local s={x=w/2,y=155,angle=0,vx=650,vy=0,flightSpeed=650,wave=4,snails={}}
   F.reset(s);flight.aim(s)
   for i=1,4 do local x,y=F.sample(s,i);s.snails[i]={id=i,x=x,y=y,angle=0,phase='tethered'}end
   for tick=1,3600 do
    flight.update(s,1/120);F.record(s)
    for _,p in ipairs(s.snails)do
     local x,y,a=p.x,p.y,p.angle;F.move(s,p,1/120)
     assert((p.x-x)^2+(p.y-y)^2<(650/120+.01)^2,'No sudden positional jumps')
     assert(math.abs((p.angle-a+math.pi)%(2*math.pi)-math.pi)<.06,'Shell turns progressively')
    end
    for i=1,3 do for j=i+1,4 do
     local a,b=s.snails[i],s.snails[j];local d=math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
     smallest=math.min(smallest,d)
     assert(d>40,'Captive shells never overlap on tight turns: '..d)
    end end
   end
   -- Removing one captive must not pull the remaining snails into new slots.
   local p=s.snails[3];local x,y=p.x,p.y;s.snails[2].phase='spent';F.move(s,p,1/120)
   assert(math.abs(p.x-x)+math.abs(p.y-y)<.001)
   assert(#s.snailRoute<500,'Route memory remains bounded')
   s.x=s.x*1.25;for _,p in ipairs(s.snails)do p.x=p.x*1.25 end;F.resize(s,1.25)
   local p=s.snails[3];local x,y=p.x,p.y;F.move(s,p,1/120)
   assert(math.abs(p.x-x)+math.abs(p.y-y)<.001,'Window resize does not shift a captive along the route')
  end
 end
 Arena.width=width
 print(string.format('PASS snail follow: 15 long routes, gradual shell turns, bounded movement, no crossing/overlap (minimum %.1f px), stable slots after cuts, bounded history',smallest))
 love.event.quit()
end
return T
