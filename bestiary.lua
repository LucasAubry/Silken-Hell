local json=require 'json'
local B={seen={},unread={},dirty=false,entries={
 {id='ange',name='Ange gardien',art='catalog_ange',world=1,text='Il poursuit l’araignée. Certains anges portent une larme : attire-les dans un piège pour la faire tomber.'},
 {id='snake',name='Serpent céleste',art='catalog_snake',world=1,text='Il avance lorsque tu bouges. Les pièges peuvent l’immobiliser ; le toucher est mortel.'},
 {id='scie',name='Roue enchaînée',art='wheel',world=1,text='Sa lame tourne au bout d’une chaîne. Évite la tête mobile et traverse lorsque son passage est libre.'},
 {id='piege',name='Piège de capture',art='catalog_trap',world=1,text='Il immobilise brièvement sa première victime. Un monstre porteur piégé lâche sa larme. Le piège se réarme après six secondes.'},
 {id='merle',name='Le Merle noir',art='merle_down',world=1,text='Il reste au centre et tire des plumes mortelles. Les nids ralentissent et divisent ses tirs. Guide les projectiles vers les plumes dorées pour le vaincre.'},
 {id='imp',name='Goule de braise',art='imp_down',world=2,text='Elle poursuit sa cible, puis accélère pendant deux secondes. Un piège peut arrêter sa charge et lui faire lâcher sa larme.'},
 {id='spinner',name='Serpent tournoyant',art='serpent_down',world=2,text='Il tourne sur lui-même et se déplace indépendamment de toi. Il rebondit sur les murs sans poursuivre le joueur.'},
 {id='wasp',name='Guêpe solitaire',art='wasp_down',world=2,text='Invulnérable en vol, elle lance des dards et invoque des guêpes. Au sol, touche son corps pour lui retirer une vie sans mourir. Elle redécolle après un coup ou si tu attends trop. Son venin vert ralentit.'},
 {id='waspling',name='Petite guêpe',art='wasp_down',world=2,text='Invoquée par la guêpe solitaire, elle poursuit l’araignée pendant quelques secondes. Son contact est mortel.'},
 {id='lava',name='Flaque de lave',art='lava',world=2,text='Une flaque immobile et mortelle. Contourne son bord incandescent.'},
 {id='fish',name='Poisson-lame',art='fish_down',world=4,text='Il patrouille puis traverse rapidement le bassin dans sa direction actuelle. Ses nageoires sont mortelles.'},
 {id='jelly',name='Méduse électrique',art='jelly_down',world=4,text='Elle dérive lentement et prépare une décharge circulaire. Sors du cercle lumineux avant son impulsion. Lorsqu’elle porte une larme, elle te suit : attire-la dans un piège.'},
 {id='worm',name='Ver des profondeurs',art='worm_down',world=5,text='Il alterne déplacement sous terre et émergence. Ses sillons annoncent sa position ; sa tête est dangereuse lorsqu’il sort.'},
 {id='mole',name='Taupe fouisseuse',art='mole_down',world=5,text='Elle creuse vers ta dernière position, soulève la terre puis surgit et court brièvement. Quitte la motte avant son apparition. Si elle porte une larme, guide-la vers un piège.'},
 {id='gull',name='Mouette des vents',art='gull_down',world=6,text='Elle traverse le ciel en grandes courbes rapides. Une mouette porteuse de larme te suit : attire-la dans un piège. Les autres suivent leur propre trajectoire.'},
 {id='cloud',name='Nuage épais',art='cloud',world=6,text='Le traverser ralentit fortement l’araignée. Prévois une sortie avant l’arrivée de la pluie.'},
 {id='rain',name='Averse acérée',art='rain',world=6,text='Des cercles bleus annoncent les impacts. Une goutte frappant l’araignée au sol est mortelle.'}
}}
function B.load()
    local ok,data=pcall(json.decode,love.filesystem.read('bestiary.json') or '{}')
    B.seen=ok and type(data)=='table' and data.seen or {}; B.unread=ok and type(data)=='table' and data.unread or {}
    if type(B.seen)~='table' then B.seen={} end; if type(B.unread)~='table' then B.unread={} end
end
function B.save() if B.dirty then love.filesystem.write('bestiary.json',json.encode({seen=B.seen,unread=B.unread})); B.dirty=false end end
function B.discover(id)
    for _,e in ipairs(B.entries) do if e.id==id and not B.seen[id] then B.seen[id]=true; B.unread[id]=true; B.latest=id; B.dirty=true; return true end end
end
function B.pending() for _,value in pairs(B.unread) do if value then return true end end; return false end
function B.open()
    UI.bestReturn=App.state; UI.bestPage=1
    for i,e in ipairs(B.entries) do if e.id==B.latest then UI.bestSelected=i; UI.bestPage=math.floor((i-1)/8)+1 end end
    B.unread={}; B.dirty=true; B.save(); App.state='bestiary'
end
function B.encounter()
    for _,m in ipairs(mobs) do B.discover(m.type) end
    if Raven.active then B.discover('merle') end
    if Wasp.active then B.discover('wasp') end
    if #Hazards.lava>0 then B.discover('lava') end
    if Campaign.world==6 then B.discover('cloud'); B.discover('rain') end
    B.save()
end
return B
