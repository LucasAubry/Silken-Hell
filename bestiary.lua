local json=require 'json'
local B={seen={},unread={},dirty=false,entries={
 {id='ange',name='Ange gardien',art='catalog_ange',world=1,text='Il poursuit l’araignée. Certains anges portent une larme : attire-les dans un piège pour la faire tomber.'},
 {id='snake',name='Serpent céleste',art='catalog_snake',world=1,text='Il avance lorsque tu bouges. Les pièges peuvent l’immobiliser ; le toucher est mortel.'},
 {id='scie',trap=true,name='Roue enchaînée',art='wheel',world=1,text='Sa lame tourne au bout d’une chaîne. Évite la tête mobile et traverse lorsque son passage est libre.'},
 {id='piege',trap=true,name='Piège de capture',art='catalog_trap',world=1,text='Il immobilise brièvement sa première victime. Un monstre porteur piégé lâche sa larme. Le piège se réarme après six secondes.'},
 {id='merle',boss=true,name='Le Merle noir',art='merle_down',world=1,text='Il tire sans pause et accélère tous les deux PV perdus. À quatre PV, chaque salve comporte trois plumes. Guide-les vers l’unique œuf dans un nid éloigné. Un œuf brisé lui retire une vie, libère un petit merle et fait apparaître un nouvel œuf. Les nids ralentissent et divisent les tirs.'},
 {id='magma_spawner',trap=true,name='Nid de larves',art='magma_nest',world=2,text='Un petit nid d’œufs qui fait naître des larves de magma. Tu peux marcher dessus sans danger : seules les larves et leurs explosions sont mortelles. Les œufs remuent avant une éclosion.'},
 {id='magma_larva',name='Larve de magma',art='magma_larva',world=2,text='Elle te poursuit très vite et contourne les murs. Elle clignote avant d’exploser après quelques secondes, ou dès qu’elle te touche. Son explosion est mortelle à proximité, sans laisser de flaque.'},
 {id='imp',name='Goule de braise',art='imp_down',world=2,text='Elle poursuit sa cible, puis accélère pendant trois secondes. Elle contourne les murs.'},
 {id='spinner',name='Serpent tournoyant',art='serpent_down',world=2,text='Il tourne sur lui-même et se déplace indépendamment de toi. Il rebondit sur les murs sans poursuivre le joueur.'},
 {id='wasp',boss=true,name='Les Trois Sœurs de braise',art='wasp_down',world=2,text='Trois abeilles chargent en séquence après avoir annoncé leur trajectoire. Une seule se fatigue à la fois : touche-la au sol pour lui enlever une vie. Chacune résiste à trois coups. Chaque sœur éliminée accélère les survivantes ; la dernière devient extrêmement rapide et invoque des petites abeilles. Les lacs de lave déclenchent des éruptions annoncées.'},
 {id='waspling',name='Petite guêpe',art='waspling_down',world=2,text='Petite guêpe cuivrée aux yeux verts, invoquée uniquement par la dernière sœur survivante. Elle reste présente jusqu’à la fin du niveau, même après la mort du boss. Son contact est mortel.'},
 {id='storm',boss=true,name='Séraphin des orages',art='storm_down',world=6,text='Ce papillon céleste survole les nuages, lance des éclats et annonce ses frappes de foudre au sol. Après une tempête, ses ailes se posent et une lumière dorée apparaît : touche son corps pendant cette accalmie pour lui retirer une vie. Il reprend ensuite son envol.'},
 {id='hedgehog',boss=true,name='Hérisson des profondeurs',art='hedgehog_down',world=5,text='Il lance douze piques rapides et espacées en cercle. La première manche commence avec une taupe et un rebond. Chaque nouvelle manche ajoute une taupe et un rebond, avec un maximum de deux rebonds et cinq taupes. Il a sept vies. Chaque série terminée lui coûte une vie. Il rebondit sans pause contre les murs et est brièvement étourdi uniquement lorsqu’il perd une vie.'},
 {id='octopus',boss=true,name='Le Poulpe des marées',art='octopus_extended_down',world=4,text='Il lance des vagues de nombreux crabes qui te poursuivent. Touche une tentacule pour t’y accrocher et accélérer sa rotation : ses bras détruisent les crabes, mais toucher toi-même un crabe reste mortel. Un dash avec une direction te décroche ; sinon, tu es libéré après un court tour. Chaque tentacule supporte huit impacts de crabes. Elle rougit puis disparaît définitivement ; le poulpe perd alors une vie et inverse sa rotation. Détruis les huit tentacules. Son corps central reste dangereux. Il invoque des crabes régulièrement et projette son encre au sol. Les crabes encrés s’agitent puis explosent, propulsant leurs voisins.'},
 {id='crab',name='Crabe des marées',art='crab_open',world=4,text='Il est lancé vers ta position, annoncée au sol, puis te poursuit en te regardant. Il court plus vite quand tu es couvert d’encre. Lorsque tu es accroché au poulpe, il garde sa direction au lieu de te suivre. Il évite les tentacules : utilise les explosions des crabes encrés pour le projeter dessus. Toucher une tentacule le tue. Son contact est mortel même lorsque tu es accroché. Il contourne naturellement le poulpe. Chaque collision abîme une tentacule ; huit impacts la détruisent.'},
 {id='abyss_fish',name='Gueule des profondeurs',art='abyss_fish',world=7,text='Il t’évite dans le noir. Il charge tant que tu es éclairé : sur un cercle, ou pendant les six secondes qui suivent une électrocution.'},
 {id='light_jelly',name='Pieuvre abyssale',art='abyss_octopus',world=7,text='Elle ondule en nageant et crache des fils de lumière. Ils ne tuent pas directement : ils illuminent ton corps pendant six secondes et attirent tous les poissons.'},
 {id='skeleton_fish',boss=true,name='Léviathan d’ivoire',art='skeleton_head',world=7,text='Sa queue apparaît au niveau 8, ses os au niveau 9, puis sa tête au niveau 10 pour le combat. Sa tête reste fixe et son corps ondule. Sa bouche aspire avec force et te protège des autres ennemis pendant l’aspiration, mais pas des os. Il recrache ses prises sur toute l’arène ; ses os se mettent alors à tourner. Fais-toi électrocuter par un fil bleu, puis entre dans sa bouche ouverte : elle te recrache et perd une vie. Les cercles éclairent seulement tant que tu restes dessus et ne chargent pas ton corps. Sans charge électrique, la bouche et les os sont mortels.'},
 {id='electric_gull',name='Mouette électrique',art='gull_down',world=6,text='Frappée par la foudre, elle devient jaune et conserve une petite aura jaune mortelle. Son passage laisse une traînée électrique qui tue au contact et disparaît après 2,2 secondes.'},
 {id='lanternfish',name='Poisson-lanterne',art='lanternfish_down',world=7,text='Sa lanterne éclaire les Abysses. Il t’évite dans le noir, mais te charge si une méduse t’illumine.'},
 {id='cloud_snare',trap=true,name='Tornade',art='cloud_snare',world=6,text='Elle tourne sans arrêt. La toucher fait tournoyer l’araignée, puis la projette très violemment vers un bord. Attention aux trous et aux bords !'},
 {id='earth_tunnel',trap=true,name='Tunnel de terre',art='earth_tunnel',world=5,text='Le joueur et les monstres peuvent emprunter ce terrier et ressortent par le tunnel relié après une courte animation. Éloigne-toi de la sortie avant de rentrer à nouveau pour faire le chemin inverse.'},
 {id='lava',trap=true,name='Flaque de lave',art='lava',world=2,text='Une flaque mortelle pour toi. Les monstres la traversent, s’embrasent et laissent du feu derrière eux.'},
 {id='fish',name='Poisson-lame',art='fish_down',world=4,text='Il nage en banc très lentement, puis tout le banc fonce vers ta position en un dash. Écarte-toi au moment de la charge.'},
 {id='jelly',name='Méduse électrique',art='jelly_down',world=4,text='Elle s’illumine puis lance de petits fils électriques bleus dans toutes les directions. Passe entre les éclairs.'},
 {id='worm',name='Ver des profondeurs',art='worm_down',world=5,text='Son corps ondule en zigzag. Il se dirige vers toi. Une minuscule ombre indique sa position sous terre. Il émerge et crache des œufs : lorsqu’ils touchent un mur, de minuscules vers apparaissent et te poursuivent.'},
 {id='mole',name='Taupe fouisseuse',art='mole_down',world=5,text='Elle creuse pour s’enfouir, devient invisible, puis une motte annonce sa remontée animée : éloigne-toi avant qu’elle surgisse. Elle se déplace rapidement et contourne les murs.'},
 {id='gull',name='Mouette des vents',art='gull_down',world=6,text='Elle se dirige vers la larme puis tourne autour. Le vent la pousse ; la foudre peut la transformer en mouette électrique.'},
 {id='rain',trap=true,name='Averse acérée',art='rain',world=6,text='Des averses frappent des emplacements fixes. Les ombres bleues annoncent les impacts. Évite également les trous et le bord du sol de nuages.'},
 {id='larva',name='Minuscule ver',art='worm_down',world=5,text='Né d’un œuf projeté contre un mur, il poursuit simplement l’araignée. Petit, mais mortel au contact.'},
 {id='blackbird_chick',name='Petit merle noir',art='merle_down',world=1,text='Il apparaît lorsqu’un œuf est brisé, puis tourne autour de son nid d’origine. Son contact est mortel.'}
}}
function B.load()
    local ok,data=pcall(json.decode,love.filesystem.read('bestiary.json') or '{}')
    B.seen=ok and type(data)=='table' and data.seen or {}; B.unread=ok and type(data)=='table' and data.unread or {}
    if type(B.seen)=='table' and B.seen.hellserpent then B.seen.hellserpent=nil; B.dirty=true end
    if type(B.unread)=='table' and B.unread.hellserpent then B.unread.hellserpent=nil; B.dirty=true end
    if type(B.seen)~='table' then B.seen={} end; if type(B.unread)~='table' then B.unread={} end
end
function B.save() if B.dirty then love.filesystem.write('bestiary.json',json.encode({seen=B.seen,unread=B.unread})); B.dirty=false end end
function B.discover(id)
    for _,e in ipairs(B.entries) do if e.id==id and not B.seen[id] then B.seen[id]=true; B.unread[id]=true; B.latest=id; B.dirty=true; return true end end
end
function B.pending() for _,value in pairs(B.unread) do if value then return true end end; return false end
function B.category(entry) return entry.boss and 'boss' or entry.trap and 'traps' or 'creatures' end
function B.list(category)
    local rows={}
    for i,e in ipairs(B.entries) do if B.category(e)==category then rows[#rows+1]={index=i,entry=e} end end
    return rows
end
function B.open()
    UI.bestReturn=App.state; UI.bestPage=1; UI.bestCategory=UI.bestCategory or 'creatures'
    for i,e in ipairs(B.entries) do if e.id==B.latest then UI.bestSelected=i; UI.bestCategory=B.category(e) end end
    for i,row in ipairs(B.list(UI.bestCategory)) do if row.index==UI.bestSelected then UI.bestPage=math.floor((i-1)/8)+1 end end
    B.unread={}; B.dirty=true; B.save(); App.state='bestiary'
end
function B.encounter()
    if Magma and #Magma.spawners>0 then B.discover('magma_spawner') end
    if Bosses then for _,item in ipairs(Bosses.items) do B.discover(item.kind) end end
    for _,m in ipairs(mobs) do B.discover(m.capture and m.art or m.type) end
    if Raven.active then B.discover('merle') end
    if Storm.active then B.discover('storm') end
    if Wasp.active then B.discover('wasp') end
    if Hedgehog.active then B.discover('hedgehog') end
    if Octopus.active then B.discover('octopus') end
    if #Hazards.lava>0 then B.discover('lava') end
    if Campaign.biome==6 then if player.level>=5 then B.discover('rain') end; B.discover('cloud_snare') end
    if Campaign.biome==5 then B.discover('earth_tunnel') end
    B.save()
end
return B
