local T={}
T.specs={
 merle={{'firstShot','Premier tir',.22,0},{'shotInterval','Intervalle des tirs',.32},{'featherLife','Durée des plumes',3.5}},
 wasp={{'firstRound','Première salve',.25,0},{'aim','Visée des charges',.2},{'larvaAim','Visée des larves',.5},{'reboundAim','Visée après rebond',.18},{'fatigue','Durée du KO',1.65},{'roundRest','Repos entre salves',.04},{'hiding','Durée du retrait',.22}},
 hedgehog={{'firstRoll','Première roulade',1.35,0},{'nextRoll','Avant la roulade',.65},{'firstShot','Premiers piquants',.28,0},{'shotInterval','Intervalle des piquants',1.25},{'stun','Durée de récupération',.45}},
 octopus={{'firstInk','Premier jet d’encre',2,0},{'inkInterval','Intervalle de l’encre',1.25},{'rageInk','Encre en furie',.85},{'firstCrabs','Premiers crabes',1.2,0},{'crabInterval','Intervalle des crabes',3.2},{'rageCrabs','Crabes en furie',2.5},{'barrage','Durée du barrage',3},{'barrageInterval','Tirs du barrage',.16}},
 storm={{'hidden','Avant la charge',.9},{'turnInterval','Intervalle des virages',2.1},{'huntDuration','Durée de la poursuite',18},{'riseDuration','Envol des escargots',.65},{'returnDelay','Avant le retour',.7}},
 skeleton_head={{'intro','Avant l’attaque',1.2,0},{'openingSpit','Premier souffle',.9},{'rest','Repos',.9},{'roar','Durée du rugissement',1.1},{'bones','Durée des os',5.5},{'suction','Durée d’aspiration',6.5},{'spit','Durée du rejet',.85},{'recover','Récupération',1},{'bombRain','Pluie de bombes',4.2}}
}
T.specs.skeleton_fish=T.specs.skeleton_head
function T.spec(e) return e.kind=='boss' and T.specs[e.type] end
function T.valid(e,key,value)
 if e.type=='storm' and ({firstBolt=true,salvoRest=true,boltInterval=true,volleyInterval=true,firstShot=true,shotInterval=true,orbitDuration=true,tornadoInterval=true,growthDuration=true})[key] then return type(value)=='number' and value==value and value>=0 and value<=120 end
 for _,row in ipairs(T.spec(e) or {}) do if row[1]==key then return type(value)=='number' and value==value and value>=(row[4] or .01) and value<=120 end end
 return false
end
function T.get(b,key,default) return b.bossTimings and b.bossTimings[key] or default end
function T.configure(b,e)
 if not e.bossTimings then return end
 b.bossTimings=require('json').decode(require('json').encode(e.bossTimings))
 local get=T.get
 if e.type=='merle' then b.shotClock=get(b,'firstShot',b.shotClock)
 elseif e.type=='wasp' then b.rest=get(b,'firstRound',b.rest)
 elseif e.type=='hedgehog' then b.phaseTime=get(b,'firstRoll',b.phaseTime);b.shot=get(b,'firstShot',b.shot)
 elseif e.type=='octopus' then b.shot=get(b,'firstInk',b.shot);b.summon=get(b,'firstCrabs',b.summon)
 elseif e.type=='storm' then b.phaseTime=get(b,'hidden',b.phaseTime) end
end
return T
