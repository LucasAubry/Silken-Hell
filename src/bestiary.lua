local json=require 'json'
local B={seen={},unread={},dirty=false,entries={
 {id='ange',name='Ange gardien',art='catalog_ange',world=1,text='La soie de l’Œuf a figé sa volonté. Il te poursuit sans relâche et abandonne sa larme dans un piège.'},
 {id='snake',name='Serpent céleste',art='catalog_snake',world=1,text='Premier captif du Paradis, il ne sait plus choisir sa route. Il avance avec tes pas ; un piège peut rompre sa poursuite.'},
 {id='scie',trap=true,name='Roue enchaînée',art='wheel',world=1,text='Les gardiens ont lié une lame au fil de leur maîtresse. Elle tourne sans repos ; son extrémité tranche tout sur son passage.'},
 {id='piege',trap=true,name='Piège de capture',art='catalog_trap',world=1,text='Ces mâchoires retenaient autrefois les serviteurs rebelles. Elles immobilisent encore les captifs et leur font lâcher leurs larmes.'},
 {id='merle',boss=true,name='L’Œuf du Merle',art='merle_egg',world=1,text='La Gardienne a cousu une promesse dans cet œuf. Frappe-le en fonçant et évite ses oiseaux. Lorsque la coquille cède, leurs fils se brisent et la larme est libérée.'},
 {id='magma_spawner',trap=true,name='Nid de larves',art='magma_nest',world=2,text='Les Guêpes brûlées pondent pour nourrir une armée qui ne leur appartient pas. Les œufs remuent avant de libérer leurs larves.'},
 {id='magma_larva',name='Larve de magma',art='magma_larva',world=2,text='Née sous les fils des Guêpes, elle brûle de rage avant même de grandir. Elle te poursuit puis explose, au contact ou à bout de souffle.'},
 {id='imp',name='Goule de braise',art='imp_down',world=2,text='Les Guêpes ont fait de sa colère une laisse. Elle te traque entre les murs et accélère par accès de fureur.'},
 {id='spinner',name='Serpent tournoyant',art='serpent_down',world=2,text='Il tourne depuis que les Guêpes lui ont arraché le repos. Il rebondit sur les murs, incapable de choisir une cible.'},
 {id='wasp',boss=true,name='Les Guêpes brûlées',art='wasp_down',world=2,text='La Gardienne a brûlé leurs ailes sans couper ses fils. Leurs charges finissent contre les murs : touche-les pendant leur KO. Les survivantes deviennent plus rapides.'},
 {id='waspling',name='Petite guêpe',art='waspling_down',world=2,text='Dernière enfant des Guêpes, déjà prisonnière à sa naissance. Elle poursuit l’intrus et reste dangereuse même lorsque ses maîtresses tombent.'},
 {id='storm',boss=true,name='Merle noir',art='merle_flight_down',world=6,text='Il croyait le ciel hors de portée de la Gardienne. Renvoie ses plumes dorées : il charge après trois blessures, puis deux, puis chacune. Son bec annonce une seule traversée ; ses tirs s’accélèrent.'},
 {id='hedgehog',boss=true,name='Hérisson Brise-Roche',art='hedgehog_down',world=5,text='La Gardienne a noué ses fils entre ses piquants. Il les projette, puis roule et rebondit jusqu’à se blesser lui-même, entraînant ses taupes terrifiées.'},
 {id='octopus',boss=true,name='Pieuvre des Larmes Noires',art='octopus_extended_down',world=4,text='Elle garde l’Océan pour celle qui tient ses huit bras. Projette un crabe encré sur un tentacule, puis profite de son étourdissement pour tirer une extrémité lumineuse vers un coin.'},
 {id='crab',name='Crabe des marées',art='crab_open',world=4,text='Esclave de la Pieuvre, il cherche à mourir pour rompre ses fils. L’encre le rend frénétique : projette-le contre un mur ou un tentacule pour le faire exploser.'},
 {id='abyss_fish',name='Gueule des profondeurs',art='abyss_fish',world=7,text='Le Monstre d’os lui a appris à craindre la lumière. Il t’évite dans le noir, puis te charge dès que tu brilles.'},
 {id='light_jelly',name='Pieuvre abyssale',art='abyss_octopus',world=7,text='Le Monstre d’os se sert de sa lueur pour marquer ses proies. Ses décharges te font briller davantage et attirent les poissons.'},
 {id='skeleton_fish',boss=true,name='Le Monstre d’os',art='skeleton_head',world=7,text='Esquive ses paires d’os rapides. Son aspiration te recrache sans te blesser. Pendant sa nage, attire-le vers les bombes pour les lui faire avaler. Leur contact est mortel pour toi.'},
 {id='electric_gull',name='Mouette électrique',art='gull_down',world=6,text='La foudre du Merle a resserré ses liens. Son aura jaune et la traînée électrique qu’elle abandonne sont mortelles.'},
 {id='lanternfish',name='Poisson-lanterne',art='lanternfish_down',world=7,text='Sa lampe n’éclaire plus que les chasses du Monstre d’os. Il fuit ton ombre mais fonce sur toi lorsque l’électricité te révèle.'},
 {id='cloud_snare',trap=true,name='Tornade',art='cloud_snare',world=6,text='Le Merle emprisonne dans ces vents les fils tombés du ciel. Ils t’emportent en spirale avant de te projeter vers le bord.'},
 {id='earth_tunnel',trap=true,name='Tunnel de terre',art='earth_tunnel',world=5,text='Les taupes creusent ces passages pour fuir leur maître. Entre dans l’un pour ressortir par son jumeau ; leurs poursuivants savent aussi les emprunter.'},
 {id='lava',trap=true,name='Flaque de lave',art='lava',world=2,text='Les Guêpes y ont perdu leurs ailes. Le feu te tue, mais leurs serviteurs le traversent et le traînent derrière eux.'},
 {id='fish',name='Poisson-lame',art='fish_down',world=4,text='La Pieuvre les a liés les uns aux autres. Le banc avance lentement, puis tous chargent ensemble ta dernière position.'},
 {id='jelly',name='Méduse électrique',art='jelly_down',world=4,text='La Pieuvre a fait de sa peur une arme. Elle s’illumine avant de répandre ses fils électriques : glisse-toi entre eux.'},
 {id='worm',name='Ver des profondeurs',art='worm_down',world=5,text='Le Hérisson lui ordonne de creuser toujours plus loin. Il ondule sous terre, émerge et crache des œufs qui deviennent de petits poursuivants contre les murs.'},
 {id='mole',name='Taupe fouisseuse',art='mole_down',world=5,text='Elle ne te hait pas : elle a peur du Hérisson et de ses fils. Elle se cache sous terre ; une motte trahit l’endroit où elle ose remonter.'},
 {id='gull',name='Mouette des vents',art='gull_down',world=6,text='Le Merle lui a confié une larme qu’elle n’a pas le droit de rendre. Elle tourne autour ; la foudre peut la changer en sentinelle électrique.'},
 {id='rain',trap=true,name='Éclair du Ciel',art='rain',world=6,text='Un signe doré annonce la foudre : quitte la zone avant l’impact. Une mouette frappée devient électrique ; sa traînée est dangereuse.'},
 {id='larva',name='Minuscule ver',art='worm_down',world=5,text='Le Hérisson réclame des serviteurs toujours plus jeunes. À peine sorti de son œuf, ce petit ver te poursuit sans comprendre pourquoi.'},
 {id='blackbird_chick',name='Petit merle noir',art='merle_down',world=1,text='L’Œuf les a fait éclore dans une cage de soie. Les oiseaux clairs tirent ; les sombres poursuivent. Quand la coquille cède, leurs liens se brisent ensemble.'}
 ,{id='final_spider',boss=true,name='La Gardienne de la Soie',art='final_queen',world=3,text='Elle tient les gardiens, qui tiennent leurs créatures. Toute cette descente était sa toile. Attire sa charge vers ses enfants : chaque bébé écrasé lui coûte une vie, et les œufs touchés se fissurent.'}
 ,{id='queen_child',name='Enfant de la Soie',art='final_baby_red',world=3,text='La Gardienne noue ses propres enfants avant leur premier pas. Ils te poursuivent. La charge de leur mère peut les écraser, même sans toile, et lui retire alors une vie.'}
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
    if id=='skeleton_head' then id='skeleton_fish' end
    if Replay and Replay.playing then return false end
    if App.state=='playing' then B.levelIds=B.levelIds or {};B.levelIds[id]=true end
    for _,e in ipairs(B.entries) do if e.id==id and not B.seen[id] then B.seen[id]=true; B.unread[id]=true; B.latest=id; B.dirty=true;require('discovery_notice').enqueue(e);return true end end
end
function B.pending() for _,entry in ipairs(B.entries) do if B.unread[entry.id] then return true end end; return false end
function B.category(entry) return entry.boss and 'boss' or entry.trap and 'traps' or 'creatures' end
function B.list(category)
    local rows={}
    for i,e in ipairs(B.entries) do if B.category(e)==category and (not B.worldFilter or e.world==B.worldFilter) and (not B.levelFilter or B.levelFilter[e.id]) then rows[#rows+1]={index=i,entry=e} end end
    table.sort(rows,function(a,b)local x,y=Worlds.rank(a.entry.world),Worlds.rank(b.entry.world);if x==y then return a.index<b.index end;return x<y end)
    return rows
end
function B.currentBoss()
    local queen=require('final_spider');if queen.active and not queen.defeated then return 'final_spider',queen end
    local found,distance
    for _,item in ipairs(Bosses.items) do local b=item.boss
        if b.active and b.boss~=false and not b.defeated then
            local x,y=b.x or (b.origin and b.origin.x) or 0,b.y or (b.origin and b.origin.y) or 0
            local d=(player.x-x)^2+(player.y-y)^2
            if not distance or d<distance then found,distance=item,d end
        end
    end
    if found then return found.kind=='skeleton_head' and 'skeleton_fish' or found.kind,found.boss end
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
    if not hardcore then return e.text end
    if e.id=='wasp' then return 'HARDCORE — La soie a noirci leurs ailes. Leurs charges accélèrent ; frappe les trois sœurs pendant le même KO pour relever le défi.\n\n'..e.text end
    return e.text
end
function B.openLevel()
    local id,boss=B.currentBoss()
    local ids={};for key in pairs(B.levelIds or {}) do ids[key]=true end
    if id then ids[id]=true end
    B.open(id,boss and boss.hardcore,ids)
end
function B.open(id,hardcore,filter)
    B.levelFilter=filter;B.worldFilter=nil
    UI.bestSelected=nil;UI.bestScroll=0;UI.bestHardcore=hardcore or false
    UI.bestReturn=App.state; UI.bestPage=1; UI.bestCategory=UI.bestCategory or 'creatures'
    for i,e in ipairs(B.entries) do if e.id==(id or B.latest) and (not filter or filter[e.id]) then UI.bestSelected=i; UI.bestCategory=B.category(e) end end
    if not UI.bestSelected then
        for i,e in ipairs(B.entries) do if (not filter or filter[e.id]) and B.seen[e.id] then UI.bestSelected=i;UI.bestCategory=B.category(e);break end end
    end
    for i,row in ipairs(B.list(UI.bestCategory)) do if row.index==UI.bestSelected then UI.bestPage=math.floor((i-1)/8)+1 end end
    B.unread={}; B.dirty=true; B.save(); App.state='bestiary'
end
function B.encounter()
    B.levelIds={}
    if Magma and #Magma.spawners>0 then B.discover('magma_spawner') end
    if Bosses then for _,item in ipairs(Bosses.items) do B.discover(item.kind) end end
    for _,m in ipairs(mobs) do B.discover(m.capture and m.art or m.type) end
    if require('final_spider').active then B.discover('final_spider') end
    if Raven.active then B.discover('merle') end
    if Storm.active then B.discover('storm') end
    if Wasp.active then B.discover('wasp') end
    if Hedgehog.active then B.discover('hedgehog') end
    if Octopus.active then B.discover('octopus') end
    if Abyss.active and Abyss.boss then B.discover('skeleton_fish') end
    if #Hazards.lava>0 then B.discover('lava') end
    if #Realms.rainSites>0 then B.discover('rain') end
    if #Realms.tornadoes>0 then B.discover('cloud_snare') end
    if #Realms.tunnels>0 then B.discover('earth_tunnel') end
    B.save()
end
return B
