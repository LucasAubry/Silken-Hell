local T={}
function T.run(reset)
 reset();local C=require('mobs.bosses.abyss.pattern_cycle')
 C.enter(Abyss,'traverse');player.abyssGrace=10
 for _,b in ipairs(Abyss.bombs)do b.hit=true end
 C.update(Abyss,.01);assert(Abyss.nextPhase=='bombRain')
 C.update(Abyss,.6);assert(Abyss.phase=='bombRain' and #Abyss.bones==0,'Boss briefly exits while mines reform')
 local serial=Abyss.bombLayoutSerial;local px,py=player.x,player.y
 assert(#Abyss.bombs==6)
 for _,b in ipairs(Abyss.bombs)do assert(not b.flight and b.armDelay>0,'Replacement mines grow in place, without a flying volley')end
 C.update(Abyss,1.3);assert(Abyss.phase=='traverse','Mine chase resumes')
 assert(player.x==px and player.y==py and not player.abyssSpit,'No repeated spit or forced movement')
 for _,b in ipairs(Abyss.bombs)do assert(b.armDelay==0 and b.x==b.tx and b.y==b.ty,'Armed mines remain stationary')end
 for _,b in ipairs(Abyss.bombs)do b.hit=true end
 C.update(Abyss,.7);assert(Abyss.phase=='bombRain' and Abyss.bombLayoutSerial>serial,'New layouts keep the chase going')
 reset();print('PASS mine chase: no repeated bomb volley, brief regeneration, stationary bombs and renewed layouts')
end
return T
