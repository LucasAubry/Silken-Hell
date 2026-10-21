local D={}
local descriptions={
 blackbird_chick='Déplacement : décrit une orbite elliptique autour de son point de patrouille.\n\nAttaque : son contact est mortel.',
 spinner='Déplacement : avance en ligne droite et rebondit contre les murs en tournoyant.\n\nAttaque : son contact est mortel.',
 jelly='Déplacement : dérive en ondulant.\n\nAttaque : émet régulièrement une couronne de projectiles électriques. Son contact est mortel.',
 light_jelly='Déplacement : dérive lentement dans les Abysses.\n\nAttaque : émet des décharges toutes les trois secondes. Son contact augmente votre charge lumineuse.',
 cloud_snail='Déplacement : parcourt le terrain en évitant les murs et les autres escargots.\n\nDanger : dévore les nuages sur son passage et laisse des trous permanents qui se rejoignent. Tombe dans les trous qu’il croise, y compris les siens.',
 cloud_beast='Déplacement : nage à la surface, plonge, puis ressort près du joueur.\n\nAttaque : prépare une charge en ligne droite. Le contact à la surface ou pendant la charge est mortel.',
 wind_bat='Déplacement : traverse le terrain en ligne droite, puis revient par le bord opposé.\n\nAttaque : son contact est mortel.',
 mist_moth='Déplacement : visite différents secteurs du terrain et se décale pendant son souffle.\n\nAttaque : vise le joueur, puis souffle deux secondes dans une direction fixe. Le vent repousse le joueur et les monstres ; les murs protègent du souffle.',
 fish='Déplacement : nage lentement en banc.\n\nAttaque : les poissons visent le joueur, puis chargent ensemble en ligne droite. Leur contact est mortel.'
}
function D.text(e)
 if descriptions[e.type] then return descriptions[e.type] end
 local id=e.type=='skeleton_head' and 'skeleton_fish' or e.type
 for _,entry in ipairs(require('bestiary').entries) do if entry.id==id then return entry.text end end
 return 'Créature immobile.'
end
return D
