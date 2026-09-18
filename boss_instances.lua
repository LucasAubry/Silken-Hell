-- Each custom encounter owns its state, including duplicates of the same boss.
local B={items={}}
local files={skeleton_head='abyss',storm='storm',merle='raven',wasp='wasp',hedgehog='hedgehog',octopus='octopus',skeleton_fish='abyss'}
function B.reset() B.items={} end
function B.any() return #B.items>0 end
function B.alive()
    for _,item in ipairs(B.items) do if item.boss.boss~=false and not item.boss.defeated then return true end end
    return false
end
function B.load(entries,nests,lights)
    B.reset()
    for _,e in ipairs(entries) do
        if e.type=="hellserpent" then e.type="wasp" end -- Older authored maps use the replacement boss.
        local file=files[e.type]
        if file then
            local saved={}; for k,v in pairs(MobBehaviors) do saved[k]=v end
            local boss=assert(love.filesystem.load(file..'.lua'))()
            for k in pairs(MobBehaviors) do MobBehaviors[k]=nil end
            for k,v in pairs(saved) do MobBehaviors[k]=v end
            local px,py=player.x,player.y; local count=#mobs
            if e.type=='skeleton_fish' or e.type=='skeleton_head' then
                boss.reset(7,e.type=='skeleton_head' and 10 or e.skeletonStage or (Campaign.biome==7 and player.level>=8 and player.level or 10)); boss.instance=true; boss.headOnly=e.type=='skeleton_head'; boss.origin={x=e.x,y=e.y}; boss.buildBones()
                boss.lightSites=#lights>0 and require('json').decode(require('json').encode(lights)) or {{x=90,y=110},{x=Arena.width-90,y=490}}
            else boss.reset(false); boss.active=true; boss.x=e.x; boss.y=e.y end
            while #mobs>count do table.remove(mobs) end
            player.x,player.y=px,py
            if e.type=='merle' then
                boss.nests=#nests>=2 and require('json').decode(require('json').encode(nests)) or {{x=90,y=130,rx=34,ry=25},{x=Arena.width-90,y=470,rx=34,ry=25}}
                local n=boss.nests[1]; boss.eggs={{x=n.x,y=n.y,spot=1,glow=.35}}
            end
            boss.movementRate=e.movementRate or 1; boss.attackRate=e.attackRate or 1
            B.items[#B.items+1]={kind=e.type=='skeleton_head' and 'skeleton_fish' or e.type,boss=boss}
        end
    end
    if B.alive() then objet.larme.taken=true end
end
function B.update(dt)
    for _,item in ipairs(B.items) do
        item.boss.update(dt)
        if player.reset then break end
    end
    if B.alive() then objet.larme.taken=true end
end
function B.contact()
    for _,item in ipairs(B.items) do
        if item.boss.contact then item.boss.contact() end
        if player.reset then return end
    end
end
function B.speed()
    local factor=1
    for _,item in ipairs(B.items) do if item.kind=='merle' then
        for _,n in ipairs(item.boss.nests) do if Hazards.inEllipse(player.x+15,player.y+12,n,0) then factor=.14 end end
    end end
    return factor
end
function B.riderInput(dx,dy,dash,dt)
    for _,item in ipairs(B.items) do if item.kind=='octopus' and item.boss.riderInput(dx,dy,dash,dt) then return true end end
    return false
end
function B.otherRider(boss)
    for _,item in ipairs(B.items) do if item.kind=='octopus' and item.boss~=boss and item.boss.rider then return true end end
    return false
end
function B.octopusFor(c)
    local found,distance
    for _,item in ipairs(B.items) do if item.kind=='octopus' and not item.boss.defeated then
        local d=(item.boss.x-c.x)^2+(item.boss.y-c.y)^2
        if not distance or d<distance then found,distance=item.boss,d end
    end end
    return found
end
function B.drawGround()
    for _,item in ipairs(B.items) do
        if item.boss.drawGround then item.boss.drawGround() end
        if item.kind=='skeleton_fish' then item.boss.drawSites() end
    end
end
function B.draw(over)
    for _,item in ipairs(B.items) do
        if item.kind=='wasp' then item.boss.draw(over)
        elseif item.kind=='skeleton_fish' then if over then item.boss.drawBones() end
        elseif not over then item.boss.draw()
        end
    end
end
function B.drawLights()
    for _,item in ipairs(B.items) do if item.kind=='skeleton_fish' then item.boss.drawLights() end end
end
function B.addLights(lights)
    for _,item in ipairs(B.items) do if item.kind=='skeleton_fish' then item.boss.addLights(lights) end end
end
function B.drawInk(w,h)
    for _,item in ipairs(B.items) do if item.kind=='octopus' then item.boss.drawInk(w,h) end end
end
function B.hud()
    if #B.items==1 then return B.items[1].boss.boss~=false and B.items[1].boss or {active=false} end
    local hp,maxHp,count=0,0,0
    for _,item in ipairs(B.items) do if item.boss.boss~=false then
        hp=hp+item.boss.hp; maxHp=maxHp+item.boss.maxHp; if not item.boss.defeated then count=count+1 end
    end end
    return {active=maxHp>0,defeated=count==0,hp=hp,maxHp=maxHp,flash=0,name=count..' boss · '..hp..' PV'}
end
function B.resize(ratio)
    for _,item in ipairs(B.items) do
        local b=item.boss
        if item.kind=='wasp' then b.resize(ratio) else
        if b.x then b.x=b.x*ratio end
        if b.head then b.head.x=b.head.x*ratio end
        if b.origin then b.origin.x=b.origin.x*ratio; b.buildBones() end
        for _,key in ipairs({'projectiles','strikes','nests','eggs','chicks','minions','pools','shots','skins','crabs','wounds','lightSites','threads','inkPools','blasts','eruptions'}) do
            for _,p in ipairs(b[key] or {}) do if p.x then p.x=p.x*ratio end; if p.cx then p.cx=p.cx*ratio end; if p.tx then p.tx=p.tx*ratio end; if p.fromX then p.fromX=p.fromX*ratio end end
        end
        end
    end
end
return B
