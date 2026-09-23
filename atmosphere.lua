-- Decorative lighting stays separate from combat visibility and all hitboxes.
local A={}
local palettes={
    [1]={1,.86,.48},[2]={1,.23,.055},[3]={1,.36,.45},
    [4]={.22,.8,1},[5]={1,.76,.36},[6]={.64,.82,1}
}
local function glow(x,y,r,color,alpha)
    local g=love.graphics
    if not A.glow then
        local vertices={{0,0,0,0,1,1,1,1}}
        for i=0,32 do local a=i*math.pi/16; vertices[#vertices+1]={math.cos(a),math.sin(a),0,0,1,1,1,0} end
        A.glow=g.newMesh(vertices,'fan','static')
    end
    g.setColor(color[1],color[2],color[3],alpha); g.draw(A.glow,x,y,0,r,r*.7)
end
function A.settings(world,level)
    local depth=math.max(0,math.min(1,((level or 1)-1)/9))
    local rank=math.min(7,Worlds.rank(world))
    return {transmission=math.min(1,math.max(.12,1-(rank-1)*.13)*(1-depth*.42)+(world==2 and .06 or world==5 and .02 or world==4 and .25 or 0)),depth=depth,seed=(level or 1)*1.731+world*.43}
end
local function variation(seed)
    local v=math.sin(seed*127.1+311.7)*43758.5453
    return v-math.floor(v)
end
-- Quiet background drips: independent pauses, heights and accelerated falls.
function A.drawDrops()
    if Campaign.biome~=5 or Campaign.world==3 then return end
    local g=love.graphics;local t=UI.clock
    g.push('all');g.setShader();g.setBlendMode('alpha');g.setLineWidth(.6)
    for i=1,7 do
        local period=6+variation(i)*7
        local elapsed=t+variation(i+80)*period
        local cycle=math.floor(elapsed/period);local age=elapsed%period
        local seed=i*31+cycle*173
        local delay=variation(seed+1)*.8
        local duration=.65+variation(seed+2)*.6
        local u=(age-delay)/duration
        local x=40+variation(seed+3)*(Arena.width-80)
        local start=30+variation(seed+4)*18
        local floor=math.min(565,start+90+variation(seed+5)*210)
        local drift=(variation(seed+6)-.5)*7
        if u>=0 and u<1 then
            local y=start+(floor-start)*u*u
            x=x+drift*u+math.sin(u*math.pi)*1.2
            g.setColor(.52,.72,.77,.33);g.line(x,y,x,y+1.3)
        elseif u>=1 and age-delay-duration<.3 then
            local fade=(age-delay-duration)/.3
            g.setColor(.40,.65,.71,(1-fade)*.14)
            g.line(x+drift-1, floor, x+drift+1, floor)
        end
    end
    g.pop()
end
function A.draw()
    if Campaign.world==3 then return end
    if Graphics and not Graphics.effects then return end
    local world=Campaign.world==3 and 3 or Campaign.biome
    if world==7 then return end -- Abyss light also drives gameplay and keeps its own renderer.
    local g=love.graphics; local t=UI.clock; local c=palettes[world] or palettes[1]
    g.push('all'); g.setShader(); g.setColor(1,1,1)
    A.shader=A.shader or g.newShader('assets/atmosphere.glsl')
    local settings=A.settings(world,player.level)
    A.shader:send('transmission',settings.transmission); A.shader:send('levelSeed',settings.seed); A.shader:send('depth',settings.depth)
    A.shader:send('clock',t); A.shader:send('biome',world)
    A.shader:send('dimensions',{Arena.width,600}); A.shader:send('lightTint',c)
    local lights={}
    for _,m in ipairs(mobs) do
        if #lights>=8 then break end
        local radiant=(m.burnTime or 0)>0 or m.type=='imp' or m.type=='magma_larva' or m.type=='jelly' or (m.type=='gull' and m.electric)
        if radiant and not m.abyssHeld and not m.spent then lights[#lights+1]={m.x,m.y,72+math.sin(t*3+m.x)*8,.65} end
    end
    for _,p in ipairs(Hazards.lava) do if #lights<8 then lights[#lights+1]={p.x,p.y,math.max(p.rx,p.ry)*2,1} end end
    while #lights<8 do lights[#lights+1]={0,0,1,0} end
    A.shader:send('localLights',unpack(lights))
    g.setShader(A.shader); g.rectangle('fill',0,0,Arena.width,600); g.setShader()
    if world==5 then
        A.mist=A.mist or g.newShader('assets/cave_mist.glsl')
        A.mist:send('clock',t);A.mist:send('dimensions',{Arena.width,600})
        A.mist:send('traveler',{player.x+15,player.y+12})
        g.setShader(A.mist);g.setColor(1,1,1);g.rectangle('fill',0,0,Arena.width,600);g.setShader()
    end
    g.setBlendMode('add')
    -- Bounded, deterministic motes: no growing particle arrays or per-frame random state.
    local count=world==5 and 0 or world==6 and 38 or 76
    for i=1,count do
        local seed=i*2.39996323+settings.seed
        local speed=world==2 and 17 or world==4 and 7 or 3
        local x=(i*137.31+settings.seed*23+math.sin(t*.17+seed)*15+t*(world==6 and 9 or 1.5))%Arena.width
        local y=(i*79.73+settings.seed*47-t*speed+math.sin(t*.23+seed)*8)%600
        local pulse=.3+.7*(.5+.5*math.sin(seed+t*.8))
        local alpha=(world==1 and .28 or .48)*pulse
        if i%9==0 then glow(x,y,7,c,alpha*.4) end
        g.setColor(c[1],c[2],c[3],alpha)
        if world==4 then g.setLineWidth(.65); g.circle('line',x,y,1.1+i%3*.35)
        elseif world==2 then g.line(x,y,x+.6,y+2)
        else g.circle('fill',x,y,.55+i%3*.23) end
    end
    for _,m in ipairs(mobs) do
        if not m.abyssHeld and not m.spent then
            if m.type=='imp' or m.type=='magma_larva' then
                glow(m.x,m.y+7,28,{1,.2,.025},.22)
                for i=1,3 do local age=(t*1.2+i*.31)%1
                    g.setColor(1,.45,.1,(1-age)*.65); g.circle('fill',m.x+math.sin(i*7+t)*12,m.y-age*29,.8)
                end
            elseif m.type=='jelly' then glow(m.x,m.y,39,{.2,.7,1},.16+.1*math.sin(t*4)^2)
            elseif m.type=='gull' and m.electric then glow(m.x,m.y,28,{1,.85,.08},.22)
            elseif m.type=='worm' and Realms.wormPhase(m.age)=='surface' then
                glow(m.x,m.y+4,18,{.8,.5,.2},.09)
            end
        end
    end
    g.pop()
end
return A
