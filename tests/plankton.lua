local T={}
function T.run()
 Campaign.select(4);player.level=1;reset_level();App.state='playing'
 local P=require('mobs.plankton')
 local found=false
 for _,m in ipairs(mobs) do if m.type=='plankton' then found=true;assert(not Arena.blocked(m.x-8,m.y-8,16,16),'Spawn libre') end end
 assert(found,'Plancton présent dans Océan 1')
 -- Isolate contact and flight from the other creatures and authored terrain.
 mobs={};Arena.interior={};Realms.current={};player.x=385;player.y=288
 local m=P.spawn(450,300)
 local deaths=player.death
 P.update(m,.05);assert(math.abs(m.x-463.5)<.01 and not m.dead,'Vitesse de fuite triplée')
 m.has_larme=true;Campaign.carrier=m;objet.larme_dropped=false;objet.larme.taken=false
 local x=m.x;P.update(m,.05);assert(m.x>x,'Le porteur fuit aussi')
 Campaign.updateTear(0);assert(not Campaign.canCollect(),'Larme portée inaccessible')
 assert(Campaign.tearScale()==.65,'Larme portée miniature')
 assert(math.abs(objet.larme.x+15-m.x)==14,'Larme proche du corps')
 Campaign.drawTear(false)
 player.x=m.x-15;player.y=m.y-12
 P.update(m,.05)
 assert(m.burst==0,'Explosion déclenchée au contact')
 P.draw(m)
 assert(m.dead and m.spent and objet.larme_dropped,'Mort et lâcher au contact')
 assert(objet.larme.x==m.x-15 and objet.larme.y==m.y-20,'Larme lâchée sur place')
 assert(Campaign.tearScale()==1,'Larme au sol à taille normale')
 local tx,ty=objet.larme.x,objet.larme.y
 P.update(m,.05);assert(objet.larme.x==tx and objet.larme.y==ty,'Pas de second lâcher')
 assert(m.burst==.05,'Explosion avance sans se relancer')
 P.draw(m);P.update(m,.7);assert(m.burst==nil,'Particules terminées')
 local empty=P.spawn(600,300);player.x=585;player.y=288;empty.is_frozen=true
 Realms.capture(empty);P.update(empty,.05);assert(empty.dead,'Contact mortel même immobilisé')
 assert(objet.larme.x==tx and objet.larme.y==ty,'Sans larme, aucun déplacement de la larme existante')
 assert(player.death==deaths and not player.reset,'Joueur indemne')
 -- A current moves a motionless plankton, reverses, and respects walls.
 local drifter=P.spawn(500,400,0);player.x=100;player.y=100
 Realms.current={{x=500,y=400,rx=100,ry=60,speed=200,dx=1}}
 P.update(drifter,.05);assert(math.abs(drifter.x-510)<.01,'Emporté par le courant')
 Realms.current[1].dx=-1;P.update(drifter,.05);assert(math.abs(drifter.x-500)<.01,'Courant inversé')
 Realms.current={require('ground_holes').stroke({500,350,500,500},28,'current')}
 Realms.current[1].speed=200
 P.update(drifter,.05);assert(drifter.y>409 and math.abs(drifter.x-500)<.01,'Suit les courants dessinés')
 local walls=Arena.walls;Arena.walls={{x=480,y=425,w=40,h=4}}
 P.update(drifter,.05);assert(drifter.y<=417,'Le courant ne traverse pas les murs')
 Arena.walls=walls;Arena.interior={};Realms.current={}
 -- Dense groups separate at spawn and stay separate while swimming.
 mobs={};Arena.walls={};player.x=100;player.y=100
 for i=1,8 do P.spawn(500,300) end
 local function spaced()
  for i,a in ipairs(mobs) do for j=i+1,#mobs do
   local b=mobs[j]
   assert(math.abs(a.x-b.x)>=17.99 or math.abs(a.y-b.y)>=17.99,'Les planctons ne se superposent pas')
  end end
 end
 spaced()
 for step=1,120 do for _,a in ipairs(mobs) do P.update(a,1/60) end;spaced() end
 -- The enlarged hitbox catches a touch that used to miss the 8px body.
 mobs={};local touched=P.spawn(500,300);player.x=478;player.y=270
 assert(touched.hitBox_width==16 and touched.hitBox_height==16)
 P.update(touched,0);assert(touched.dead,'Contact dans la nouvelle hitbox')
 -- Wall escape steering is gone: a head-on plankton stays against the wall.
 mobs={};Arena.walls={{x=300,y=100,w=20,h=400}};player.x=185;player.y=300
 local runner=P.spawn(292,312)
 for step=1,30 do P.update(runner,1/60) end
 assert(runner.x==292 and runner.y==312,'Ancien comportement contre les murs')
 -- Currents carry plankton but no longer imprison them.
 mobs={};Arena.walls={};player.x=485;player.y=350
 local zone={x=500,y=300,rx=80,ry=35,speed=80,dx=1}
 Realms.current={zone};local swimmer=P.spawn(500,300,200)
 for i=1,60 do P.update(swimmer,1/60) end
 assert(not swimmer.dead and not require('ocean_current').contains(zone,swimmer.x,swimmer.y),'Le plancton peut sortir du courant')
 Realms.current={}
 Arena.walls=walls;mobs={};player.x=100;player.y=100
 P.art(200,200,12,1);P.draw(m)
 require('level_layouts').spawn({type='plankton',x=300,y=200,has_larme=true,speed=80})
 assert(mobs[#mobs].has_larme and Campaign.carrier==mobs[#mobs],'Porteur créé dans une carte')
 local snapshot=require('level_layouts').snapshot()
 assert(require('layout_schema').validate(snapshot),'Carte avec plancton valide')
 love.draw()
 print('PASS plankton: spacing, enlarged hitbox, original wall collision, escapable currents, death burst and cleanup, triple speed, miniature carried tear, currents, walls, ocean spawn, fleeing carrier, harmless contact, frozen contact, tear drop, layout and rendering')
end
return T
