local T={}
function T.run()
 local disabled=LevelLayouts.disabled;LevelLayouts.disabled=true
 for n=7,10 do
  Campaign.select(7);player.level=n;reset_level();App.state='playing'
  assert(Abyss.giant==(n>=8));assert((Abyss.head~=nil)==(n==10))
  if n==8 then assert(#Abyss.bones==1 and Abyss.bones[1].key=='skeleton_tail') end
  if n==9 then assert(#Abyss.bones>1 and not Abyss.boss) end
  Abyss.update(.1);love.draw()
  if n==8 or n==9 then
   local snapshot=LevelLayouts.snapshot();LevelLayouts.apply(snapshot)
   assert(not Bosses.alive() and Campaign.canCollect() and not Bosses.hud().active,'Fragments édités non bloquants')
   Bosses.update(.1);love.draw()
  end
 end
 Campaign.select(7);player.level=1;reset_level();App.state='playing';mobs={}
 Abyss.threads={{x=player.x+15,y=player.y+12,vx=0,vy=0,life=1,age=0,seed=0}}
 local deaths=player.death;Abyss.update(.01);assert(not player.reset and deaths==player.death and player.electrified>0,'Éclair abyssal non mortel')
 local l={world=2,level=1,width=Arena.width,height=600,entities={{kind='spawn',x=80,y=510},{kind='tear',x=900,y=500},
 {kind='magma_spawner',x=200,y=120,spawnDelay=.4,spawnInterval=.8},
 {kind='boss',type='wasp',x=450,y=180,movementRate=2,attackRate=3},
 {kind='boss',type='wasp',x=450,y=180,movementRate=1,attackRate=1}}}
 assert(LayoutSchema.validate(l));LevelLayouts.apply(l)
 local a,b=Bosses.items[1].boss,Bosses.items[2].boss
 a.rest=10;b.rest=10;a.syncAnchor();b.syncAnchor()
 local x,y=a.bees[1].x,a.bees[1].y;a.update(.05);b.update(.05)
 local da=math.sqrt((a.bees[1].x-x)^2+(a.bees[1].y-y)^2);local db=math.sqrt((b.bees[1].x-x)^2+(b.bees[1].y-y)^2)
 assert(math.abs(da-db*2)<.01 and math.abs(a.rest-9.85)<.001 and math.abs(b.rest-9.95)<.001,'Déplacement et cadence indépendants par trio')
 assert(a.bees~=b.bees and #a.bees==3 and #b.bees==3,'Trio indépendant pour chaque boss de l’éditeur')
 Magma.update(.39);assert(#mobs==0);Magma.update(.02);assert(#mobs==1);Magma.update(.81);assert(#mobs==2)
 l.entities[3].spawnInterval=0;assert(not LayoutSchema.validate(l));l.entities[3].spawnInterval=.8
 l.entities[5].attackRate=9;assert(not LayoutSchema.validate(l))
 LevelLayouts.disabled=disabled;Campaign.select(1);player.level=1;reset_level()
 print('PASS editor rates: abyss stages 7–10, harmless bolts, partial export/collection, independent boss movement/cadence, larva timing and bounds')
end
return T
