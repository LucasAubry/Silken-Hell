-- Shared victory state: all encounters on this map must be over.
local A={cleared=false,sparks={}}
function A.reset() A.cleared=false;A.sparks={};A.lookTime=0 end
function A.ready()
    local present=Raven.active or Wasp.active or Hedgehog.active or Octopus.active or Storm.active or Abyss.boss or Bosses.hud().active
    return present and Campaign.canCollect()
end
function A.update(dt)
    if not A.cleared and A.ready() then
        A.cleared=true
        local seen={}
        local function vanish(list)
            for _,m in ipairs(list or {}) do if not seen[m] and m.x and m.y then
                seen[m]=true;A.sparks[#A.sparks+1]={x=m.x,y=m.y,age=0}
            end end
        end
        vanish(mobs);vanish(Realms.larvae)
        for _,b in ipairs({Raven,Wasp,Octopus,Abyss}) do vanish(b.minions);vanish(b.crabs);vanish(b.chicks);if b.bees then vanish(b.bees);b.bees={} end;b.minions={};b.crabs={};b.chicks={};b.projectiles={} end
        for _,item in ipairs(Bosses.items) do vanish(item.boss.minions);vanish(item.boss.crabs);vanish(item.boss.chicks);if item.boss.bees then vanish(item.boss.bees);item.boss.bees={} end;item.boss.minions={};item.boss.crabs={};item.boss.chicks={};item.boss.projectiles={} end
        mobs={};Campaign.carrier=nil;objet.larme_dropped=true
        Realms.larvae={};Realms.eggs={};Realms.bolts={};Burning.reset();Magma.reset()
        A.x,A.y=Arena.width/2,585
    end
    for i=#A.sparks,1,-1 do local s=A.sparks[i];s.age=s.age+dt;if s.age>1.1 then table.remove(A.sparks,i) end end
    if A.cleared then
        local dx,dy=A.x-player.x-15,A.y-player.y-12;local d=math.sqrt(dx*dx+dy*dy)
        A.near=d<115
        A.looking=A.near and (dx*(player.lastMoveX or 0)+dy*(player.lastMoveY or 1))/math.max(1,d)>.65
        A.lookTime=A.looking and A.lookTime+dt or 0
    end
end
function A.draw()
    local g=love.graphics;local c=Worlds.color(Campaign.biome).tear;g.push('all')
    for _,s in ipairs(A.sparks) do
        local t=s.age/1.1
        for i=1,8 do local a=i*math.pi/4+s.x;local d=t*(18+i*3)
            g.setColor(c[1],c[2],c[3],1-t);local x,y=s.x+math.cos(a)*d,s.y+math.sin(a)*d-t*18
            g.rectangle('fill',x,y,2,2)
        end
    end
    if A.cleared then
        g.setColor(c[1]*.5+.5,c[2]*.5+.5,c[3]*.5+.5,A.looking and .95 or .4+.1*math.sin(UI.clock*2))
        for i=-3,3 do local x=A.x+i*9
            g.line(x-2,A.y+3,x,A.y-3,x+2,A.y+3);g.line(x-2,A.y,x+2,A.y)
        end
        if A.near then g.setFont(UI.fonts.small);g.printf('Regarde les inscriptions',A.x-130,A.y-65,260,'center') end
        local story=(Story.worlds or {})[Campaign.world] or ''
        if A.lookTime>.6 and story~='' then
            g.setColor(.02,.025,.04,.9);g.rectangle('fill',A.x-220,65,440,130,8)
            g.setColor(1,.94,.8);g.printf(story,A.x-200,80,400,'center')
        end
    end
    g.pop()
end
return A
