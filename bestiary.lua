local json=require 'json'
local B={seen={},unread={},dirty=false,entries={
 {id='ange',name='Ange gardien',art='catalog_ange',world=1,text='Il poursuit l’araignée. Certains anges portent une larme : attire-les dans un piège pour la faire tomber.'},
 {id='snake',name='Serpent céleste',art='catalog_snake',world=1,text='Il avance lorsque tu bouges. Les pièges peuvent l’immobiliser ; le toucher est mortel.'},
 {id='scie',trap=true,name='Roue enchaînée',art='wheel',world=1,text='Sa lame tourne au bout d’une chaîne. Évite la tête mobile et traverse lorsque son passage est libre.'},
 {id='piege',trap=true,name='Piège de capture',art='catalog_trap',world=1,text='Il immobilise brièvement sa première victime. Un monstre porteur piégé lâche sa larme. Le piège se réarme après six secondes.'},
 {id='merle',boss=true,name='L’Œuf du Merle',art='merle_down',world=1,text='Fonce dans le gros œuf central pour lui retirer une vie, puis éloigne-toi avant le prochain coup. Chaque impact brise un petit œuf dans chacun des six nids fixes. Trois oiseaux tirent immédiatement une plume puis tournent près de leur nid avec des tirs espacés ; trois autres chargent sans ligne d’avertissement. Leurs points de départ sont toujours les mêmes. Brise la coquille en six impacts pour libérer la larme.'},
 {id='magma_spawner',trap=true,name='Nid de larves',art='magma_nest',world=2,text='Un petit nid d’œufs qui fait naître des larves de magma. Tu peux marcher dessus sans danger : seules les larves et leurs explosions sont mortelles. Les œufs remuent avant une éclosion.'},
 {id='magma_larva',name='Larve de magma',art='magma_larva',world=2,text='Elle te poursuit très vite et contourne les murs. Elle clignote avant d’exploser après quelques secondes, ou dès qu’elle te touche. Son explosion est mortelle à proximité, sans laisser de flaque.'},
 {id='imp',name='Goule de braise',art='imp_down',world=2,text='Elle poursuit sa cible, puis accélère pendant trois secondes. Elle contourne les murs.'},
 {id='spinner',name='Serpent tournoyant',art='serpent_down',world=2,text='Il tourne sur lui-même et se déplace indépendamment de toi. Il rebondit sur les murs sans poursuivre le joueur.'},
 {id='wasp',boss=true,name='Les Trois Sœurs de braise',art='wasp_down',world=2,text='Trois abeilles, trois vies chacune. Elles s’alignent horizontalement ou verticalement attendent 0,4 seconde puis chargent tout droit, sans annoncer leur trajectoire. Un choc contre un mur les met KO : touche-les pour retirer une vie. Depuis les coins, une, deux puis trois sœurs lancent des larves de magma identiques à celles des nids. Les transitions sont rapides et deux sœurs ne chargent jamais dans le même sens en même temps. Chaque sœur éliminée accélère les survivantes et laisse un corps mortel au sol. La dernière lâche deux larves de magma au début de chaque attaque. Leur vol est très rapide et leur contact est mortel sauf pendant le KO.'},
 {id='waspling',name='Petite guêpe',art='waspling_down',world=2,text='Petite guêpe cuivrée aux yeux verts, invoquée uniquement par la dernière sœur survivante. Elle reste présente jusqu’à la fin du niveau, même après la mort du boss. Son contact est mortel.'},
 {id='storm',boss=true,name='Séraphin des orages',art='storm_down',world=6,text='Ce papillon céleste survole les nuages, lance des éclats et annonce ses frappes de foudre au sol. Après une tempête, ses ailes se posent et une lumière dorée apparaît : touche son corps pendant cette accalmie pour lui retirer une vie. Il reprend ensuite son envol.'},
 {id='hedgehog',boss=true,name='Hérisson des profondeurs',art='hedgehog_down',world=5,text='Il lance douze piques rapides et espacées en cercle. La première manche commence avec une taupe et un rebond. Chaque nouvelle manche ajoute une taupe et un rebond, avec un maximum de deux rebonds et cinq taupes. Il a sept vies. Chaque série terminée lui coûte une vie. Il rebondit sans pause contre les murs et est brièvement étourdi uniquement lorsqu’il perd une vie.'},
 {id='octopus',boss=true,name='Le Poulpe des marées',art='octopus_extended_down',world=4,text='Il lance trois crabes par vague, avec huit secondes entre les vagues, et des flaques d’encre qui durent sept secondes. Un crabe encré devient noir et erre sans te suivre. Fonce sur un crabe noir pour le propulser à l’opposé du point de contact. Un mur le fait exploser ; un tentacule le fait exploser et étourdit le poulpe pendant trois secondes, sans lui retirer de vie. Pendant ce délai, fonce sur une extrémité lumineuse pour t’y attacher, puis entraîne-la dans un coin éclairé afin de l’arracher. Sinon, le poulpe se réveille et le lien se détache. Chaque tentacule arraché retire une vie : il faut arracher les huit. Son corps reste mortel ; ses tentacules sont mortels quand il tourne. À quatre vies, il accélère fortement et projette une rafale d’encre pendant trois secondes. Les crabes ordinaires sont mortels ; les noirs se repoussent uniquement en fonçant.'},
 {id='crab',name='Crabe des marées',art='crab_open',world=4,text='Il te poursuit jusqu’à toucher de l’encre : devenu noir, il erre au hasard. Fonce sur lui pour le propulser à l’opposé du contact ; sans élan, il reste mortel. Il explose contre un mur ou un tentacule. Un impact sur un tentacule étourdit le poulpe trois secondes. Une explosion repousse les crabes voisins, mais les crabes n’explosent pas simplement en se touchant.'},
 {id='abyss_fish',name='Gueule des profondeurs',art='abyss_fish',world=7,text='Il t’évite dans le noir. Il charge tant que tu es éclairé : sur un cercle, ou pendant les six secondes qui suivent une électrocution.'},
 {id='light_jelly',name='Pieuvre abyssale',art='abyss_octopus',world=7,text='Son contact et chaque éclair ajoutent une charge, jusqu’à trois, pour six secondes, renouvelées à chaque impact. Plus tu accumules de charges, plus tu brilles, plus les poissons te repèrent de loin et plus ils te poursuivent vite.'},
 {id='skeleton_fish',boss=true,name='Léviathan d’ivoire',art='skeleton_head',world=7,text='Sa queue apparaît au niveau 8, ses os au niveau 9, puis sa tête au niveau 10 pour le combat. Il possède dix vies. Sa tête flotte doucement, ses yeux te suivent et son corps ondule. Sa bouche aspire avec force et te rend invulnérable jusqu’au rejet. Il recrache ses prises sur toute l’arène ; ses os se mettent alors à tourner. Fais-toi électrocuter par un fil bleu, puis entre dans sa bouche ouverte : elle te recrache et perd une vie par charge avalée. Toucher sa queue avec une charge la consomme et déclenche son aspiration. Les cercles éclairent seulement tant que tu restes dessus et ne chargent pas ton corps. Sans charge électrique, être avalé ne blesse pas le boss. Hors aspiration, les os sont mortels.'},
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
 {id='blackbird_chick',name='Petit merle noir',art='merle_down',world=1,text='Il éclot dans un nid quand le gros œuf est frappé. Certains tournent et tirent des plumes, les autres visent puis chargent. Son contact est mortel.'}
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
    if Replay and Replay.playing then return false end
    for _,e in ipairs(B.entries) do if e.id==id and not B.seen[id] then B.seen[id]=true; B.unread[id]=true; B.latest=id; B.dirty=true; return true end end
end
function B.pending() for _,value in pairs(B.unread) do if value then return true end end; return false end
function B.category(entry) return entry.boss and 'boss' or entry.trap and 'traps' or 'creatures' end
function B.list(category)
    local rows={}
    for i,e in ipairs(B.entries) do if B.category(e)==category then rows[#rows+1]={index=i,entry=e} end end
    return rows
end
function B.currentBoss()
    local found,distance
    for _,item in ipairs(Bosses.items) do local b=item.boss
        if b.active and b.boss~=false and not b.defeated then
            local x,y=b.x or (b.origin and b.origin.x) or 0,b.y or (b.origin and b.origin.y) or 0
            local d=(player.x-x)^2+(player.y-y)^2
            if not distance or d<distance then found,distance=item,d end
        end
    end
    if found then return found.kind,found.boss end
    for _,pair in ipairs({{'merle',Raven},{'storm',Storm},{'wasp',Wasp},{'hedgehog',Hedgehog},{'octopus',Octopus},{'skeleton_fish',Abyss}}) do
        local b=pair[2];if b.active and b.boss~=false and not b.defeated and (pair[1]~='skeleton_fish' or b.boss) then return pair[1],b end
    end
end
function B.openBoss()
    local id,boss=B.currentBoss()
    if id then B.discover(id);B.save() end
    B.open(id,boss and boss.hardcore)
end
function B.description(e,hardcore)
    if not démon then return e.text end
    if e.id=='wasp' then
        return 'LES SŒURS DE LAVE — MODE DÉMON\n\nTrois sœurs noires et rouges, trois vies chacune. Elles gardent les vitesses originales : 4 % de plus que les sœurs normales, et environ 14 % de plus pour la dernière survivante.\n\n'..e.text..'\n\nAccès : porte droite du Sanctuaire. Ce combat dispose de son propre classement. Gillou récompense trois touches pendant un même KO des sœurs.'
    end
    return 'Cette version démon n’est pas encore disponible. Pour le moment, seules les Sœurs de lave se trouvent derrière la porte démon du Sanctuaire.\n\nVERSION NORMALE\n\n'..e.text
end
function B.open(id,hardcore)
    UI.bestScroll=0;UI.bestHardcore=hardcore or false
    UI.bestReturn=App.state; UI.bestPage=1; UI.bestCategory=UI.bestCategory or 'creatures'
    for i,e in ipairs(B.entries) do if e.id==(id or B.latest) then UI.bestSelected=i; UI.bestCategory=B.category(e) end end
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
