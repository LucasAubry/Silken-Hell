local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 App.start(3);local F=require('final_spider');local A=require('final_art')
 local x,y=F.x,F.y
 for i=1,100 do F.update(.1) end
 assert(not F.engaged and #F.webs==0 and #F.eggs==0 and F.x==x and F.y==y,'Passive until touched')
 player.x=F.x-15;player.y=F.y-12;F.update(.01)
 assert(F.engaged and not player.reset and F.phase=='webs','First touch starts fight safely')
 F.update(.01);assert(not player.reset,'Time to get clear')
 player.x=50;player.y=450
 for i=1,15 do F.update(.1) end
 assert(#F.webs>0,'Attacks after activation')
 F.x=500;F.y=300;player.x=500+40-15;player.y=300-12;F.phase='recover';F.phaseTime=0;F.update(.01)
 assert(not player.reset,'Reduced body has no old oversized hitbox')
 player.x=F.x-15;player.y=F.y-12;F.update(.01);assert(player.reset,'Contact lethal during combat')
 App.resolveDeath();assert(not F.engaged and F.phase=='passive','Respawn restores passive encounter')
 local spider=A.spider;local queenSize
 A.spider=function(name,x,y,size,...) if name=='queen' then queenSize=size end;return spider(name,x,y,size,...)end
 F.draw();A.spider=spider;assert(queenSize==62,'Queen art preserved at player size')
 local tick=0
 love.update=function()
 tick=tick+1
 if tick==1 then App.capture='queen-passive-garden.png' end
 if tick==5 then print('PASS passive encounter, safe activation, combat collision, reset, queen art and scale');love.event.quit() end
 end
end
return T
