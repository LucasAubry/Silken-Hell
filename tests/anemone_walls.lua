local T={}
function T.run(reset)
 local wall={x=200,y=200,w=160,h=20,rotation=90}
 assert(Arena.blocked(275,145,10,10,{wall}),'Vertical rotated wall blocks its visible end')
 assert(not Arena.blocked(205,205,10,10,{wall}),'Old horizontal footprint stays passable')
 wall.rotation=45
 assert(Arena.blocked(325,255,10,10,{wall}),'Diagonal wall blocks its end')
 assert(not Arena.blocked(325,155,10,10,{wall}),'Empty bounding-box corner stays passable')
 reset();Abyss.boss=false;Abyss.giant=false;Abyss.phase=nil
 local kill=Hazards.kill;local hits=0;Hazards.kill=function()hits=hits+1 end
 Realms.vents={{x=300,y=300,rx=30,ry=23}};Realms.holes={};player.x=285;player.y=288
 for _,clock in ipairs({0,2.5,3.5,5.5})do Realms.clock=clock;Realms.contact()end
 assert(hits==4,'Anemone contact is lethal throughout the old cycle, without a phase field')
 player.x=400;Realms.contact();assert(hits==4,'Anemone does not kill at a distance');Hazards.kill=kill
 assert(Art.images.electric_anemone,'New sprite loaded')
 Art.drawAnemone(-100,-100,74,70,0)
 local mesh=Art.images.electric_anemone.anemoneMesh
 local tx,ty=mesh:getVertex(11);local bx,by=mesh:getVertex(431)
 Art.drawAnemone(-100,-100,74,70,1)
 local tx2,ty2=mesh:getVertex(11);local bx2,by2=mesh:getVertex(431)
 assert(math.abs(tx2-tx)+math.abs(ty2-ty)>1,'Tentacles move over time')
 assert(bx==bx2 and by==by2,'Anemone base stays fixed')
 print('PASS anemone: continuous contact, new art; walls: rotated collision and empty corners')
end
return T
