local C={}
function C.defaults(level) return {interval=math.max(3.6,6-(level or 1)*.2),delay=1.6} end
function C.valid(key,value)
 return (key=='interval' or key=='delay') and type(value)=='number' and value==value and value>=.1 and value<=120
end
function C.values(layout,level)
 local defaults=C.defaults(level);local saved=layout and layout.lightning or {}
 return saved.interval or defaults.interval,saved.delay or defaults.delay
end
function C.zones(layout,width)
 local zones={};if not layout then return zones end
 local scale=width/layout.width
 for _,e in ipairs(layout.entities or {}) do if e.kind=='lightning_zone' then zones[#zones+1]={x=e.x*scale,y=e.y,w=e.w*scale,h=e.h} end end
 return zones
end
function C.point(zone,index)
 local dx,dy=math.max(0,zone.w/2-34),math.max(0,zone.h/2-34)
 local offsets={{0,0},{0,-dy},{-dx,0},{0,dy},{dx,0}}
 local p=offsets[(index-1)%5+1];return zone.x+p[1],zone.y+p[2]
end
C.description='Dans chaque zone : milieu → haut → gauche → bas → droite, puis le cycle recommence. Toutes les zones suivent cet ordre en même temps.\n\nL’intervalle sépare les annonces ; le délai avant impact laisse le temps d’éviter l’éclair. Première annonce après 4 secondes.\n\nSans zone, les positions actuelles restent inchangées. Aucun tirage aléatoire.'
return C
