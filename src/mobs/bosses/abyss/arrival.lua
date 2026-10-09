local I={}
function I.start(a)
 I.current=a
 a.arrival={age=0};a.lumenParticles={};a.returnShots={};a.open=false
 a.swimHead={x=-180,y=300};a.swimAngle=0;a.swimPath={};a.returnPosePositions={};a.returnPoseAngles={}
 for d=700,0,-6 do a.swimPath[#a.swimPath+1]={x=-180-d,y=300} end
 a.buildBones();player.x=Arena.width/2-15;player.y=300-12
end
function I.finish(a)
 I.current=nil;a.arrival=nil;a.open=false;a.returnMouth=0;a.returnShotTimer=1.4
 require('mobs.bosses.abyss.tooth_wake').setup(a)
 a.returnPX,a.returnPY=player.x+15,player.y+12
end
function I.update(a,dt)
 local intro=a.arrival;if not intro then return false end
 intro.age=intro.age+dt;a.clock=a.clock+dt
 local t=intro.age
 if t>.65 then
  local x=-180+math.min(1,(t-.65)/1.4)*390
  a.swimHead.x=x;local last=a.swimPath[#a.swimPath];if not last or math.abs(last.x-x)>3 then a.swimPath[#a.swimPath+1]={x=x,y=300} end
 end
 a.open=t>=1.8
 a.returnBuildDt=dt;a.buildBones();a.returnBuildDt=nil
 if t>=2.15 and not intro.spit then
  intro.spit=true;require('mobs.bosses.abyss.tooth_wake').setup(a)
  local mx,my=a.mouth()
  for _,p in ipairs(a.lumenParticles) do p.tx,p.ty=p.x,p.y;p.x,p.y=mx,my end
 end
 if intro.spit then
  local u=math.min(1,(t-2.15)/.75);local ease=1-(1-u)^3;local mx,my=a.mouth()
  for _,p in ipairs(a.lumenParticles) do p.x=mx+(p.tx-mx)*ease;p.y=my+(p.ty-my)*ease;p.age=p.age+dt end
 end
 if t>=3.15 then I.current=nil;a.arrival=nil;a.open=false;a.returnMouth=0;a.returnShotTimer=1.3;a.returnPX=player.x+15;a.returnPY=player.y+12 end
 return true
end
return I
