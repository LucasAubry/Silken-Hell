local T={}
function T.run(reset)
 reset();local C=require('mobs.bosses.abyss.pattern_cycle');local B=require('mobs.bosses.abyss.bombs')
 C.enter(Abyss,'traverse');player.x=900;player.y=400;player.abyssGrace=10
 Abyss.swimHead={x=400,y=300};Abyss.swimAngle=.35;Abyss.swimPath={};Abyss.bombs={{x=100,y=100,r=15}}
 C.shedBone(Abyss);assert(Abyss.open and Abyss.toothOpen>0)
 local mx,my=C.swimMouth(Abyss)
 for _,p in ipairs(Abyss.debris)do
  local dx,dy=p.x-mx,p.y-my
  assert(math.abs(dx*math.cos(.35)+dy*math.sin(.35)+48)<.01,'Teeth leave the deep throat in rotated head space')
 end
 C.update(Abyss,.08);assert(Abyss.open,'Jaw stays open while the teeth exit')
 Abyss.bombs={{x=600,y=300,r=15}};Abyss.lumenParticles={{x=630,y=300,age=0,id=1,consumed=false}}
 local hp=Abyss.hp;local eaten=Abyss.bombsEaten
 local p={tooth=true,x=650,y=300,throatTravel=0}
 assert(B.tooth(Abyss,p,550,300),'Fast tooth catches bomb along its path')
 assert(Abyss.bombs[1].hit and Abyss.hp==hp and Abyss.bombsEaten==eaten,'Shooting clears a bomb without swallowing it')
 assert(Abyss.lumenParticles[1].wakeVx>0,'Explosion pushes blue particles outwards')
 reset();print('PASS deep-mouth teeth, held-open jaw, swept tooth/bomb collision and particle blast')
end
return T
