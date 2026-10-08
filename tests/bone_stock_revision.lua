local T={}
function T.run(reset)
 local C=require('mobs.bosses.abyss.pattern_cycle');local S=require('mobs.bosses.abyss.bone_stock');local B=require('mobs.bosses.abyss.bombs')
 reset();C.enter(Abyss,'traverse');Abyss.swimHead.x=900;Abyss.swimHead.y=300;Abyss.buildBones()
 local speed=Abyss.swimSpeed;local ids={}
 for i=1,28 do
  local bone=S.choose(Abyss,nil,false);assert(bone,'Bone available '..i)
  if i<=18 then assert(bone.key=='skeleton_rib')elseif i==19 then assert(bone.key=='skeleton_tail','Tail fires after ribs')else assert(bone.key=='skeleton_spine')end
  assert(not ids[bone.stockId],'Every bone is fired once');ids[bone.stockId]=true
  assert(S.launch(Abyss,bone,640));Abyss.buildBones()
  assert(#Abyss.bones==29-i,'Bone disappears permanently');assert(Abyss.swimSpeed>speed);speed=Abyss.swimSpeed
 end
 assert(not S.choose(Abyss,nil,false) and #Abyss.bones==1 and math.abs(speed-567)<.001,'Only fast head remains')
 C.enter(Abyss,'bones');assert(#Abyss.bones==1,'No regeneration on phase change');C.fireBones(Abyss);assert(#Abyss.debris==28,'No phantom projectiles')
 -- Vacuum recovery returns the exact original slot, even after the tail was fired.
 local p=Abyss.debris[19];assert(p.stockId=='tail');Abyss.debris={p};C.enter(Abyss,'suction')
 local mx,my=C.mouth(Abyss);p.x=mx;p.y=my;player.x=700;player.y=450;player.abyssGrace=20
 C.update(Abyss,.01);assert(not Abyss.missingBones.tail and #Abyss.debris==0,'Suction restores original tail slot')
 C.enter(Abyss,'traverse');assert(#Abyss.bones==2 and Abyss.bones[2].stockId=='tail' and Abyss.swimSpeed<speed)
 -- A returning projectile keeps its exact impact orientation and follows its host.
 reset();C.enter(Abyss,'traverse');Abyss.swimHead.x=650;Abyss.swimHead.y=300;Abyss.buildBones()
 local fired=S.choose(Abyss,nil,false);local id=fired.stockId;S.launch(Abyss,fired,640);Abyss.buildBones()
 p=Abyss.debris[1];p.recoverTime=0;p.angle=.73;p.x=650;p.y=300
 assert(S.recover(Abyss,p,850,300),'Swept collision recovers bone');Abyss.debris={};local impactX,impactY=p.x,p.y
 Abyss.buildBones();local embedded
 for _,b in ipairs(Abyss.bones)do if b.stockId==id then embedded=b end end
 assert(embedded and embedded.embedded and math.abs(embedded.x-impactX)<.001 and math.abs(embedded.y-impactY)<.001 and math.abs(embedded.angle-.73)<.001,'Impact position and angle preserved')
 Abyss.swimHead.x=750;Abyss.swimHead.y=320;Abyss.swimAngle=.4;Abyss.buildBones()
 for _,b in ipairs(Abyss.bones)do if b.stockId==id then embedded=b end end
 assert(math.abs(embedded.angle-1.13)<.001,'Planted bone follows head rotation')
 assert(S.launch(Abyss,embedded,640));assert(not Abyss.embeddedBones[id] and #Abyss.debris==1,'Recovered bone can be fired again without duplication')
 assert(S.restore(Abyss,Abyss.debris[1]));Abyss.debris={};Abyss.buildBones()
 for _,b in ipairs(Abyss.bones)do if b.stockId==id then assert(not b.embedded,'Vacuum places bone back in original slot')end end
 -- Every emission has a new deterministic layout and keeps landing area safe.
 B.spawn(Abyss);local positions={};for i,b in ipairs(Abyss.bombs)do positions[i]={b.tx,b.ty}end
 B.spawn(Abyss);for i,b in ipairs(Abyss.bombs)do assert(b.tx~=positions[i][1] or b.ty~=positions[i][2]);assert(b.tx<=Arena.width-280)end
 print('PASS persistent bone stock, ribs/tail/vertebra order, head-only speed, exact planted recovery, relaunch, vacuum restoration and renewed bomb layouts')
end
return T
