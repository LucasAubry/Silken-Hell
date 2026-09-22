require 'player'
require 'world'
require 'objet'
require 'hit_box'
require 'level'
for i=1,10 do require('levels/level_'..i) end
require 'mobs'
require 'effect'
local utf8=require 'utf8'
Worlds=require 'worlds'
Scoring=require 'scoring'
Achievements=require 'achievements'
Profile=require 'profile'
Audio=require 'audio'
Campaign=require 'campaign'
UI=require 'interface'
Online=require 'online'
Story=require 'story'
Art=require 'art'
Arena=require 'arena'
Raven=require 'mobs.bosses.raven.init'
Wasp=require 'mobs.bosses.wasp.init'
Storm=require 'mobs.bosses.storm.init'
BossFX=require 'boss_fx'
Hedgehog=require 'mobs.bosses.hedgehog.init'
Octopus=require 'mobs.bosses.octopus.init'
Ocean=require 'breathing_bubble'
Hazards=require 'hazards'
Characters=require 'characters'
Bestiary=require 'bestiary'
Realms=require 'realms'
BiomeFloor=require 'biome_floor'
Atmosphere=require 'atmosphere'
Aftermath=require 'aftermath'
WorldMap=require 'world_map'
LevelLayouts=require 'level_layouts'
Abyss=require 'mobs.bosses.abyss.init'
AbyssTerrain=require 'abyss_terrain'
Bosses=require 'mobs.bosses.instances'
LayoutSchema=require 'layout_schema'
PreviewBridge=require 'preview_bridge'
Workshop=require 'workshop'
Creator=require 'creator'
Secret=require 'secret'
Input=require 'input'
Replay=require 'replay'
require 'mobs.infernal'
Magma=require 'mobs.magma_larva.init'
Burning=require 'burning'
App={state='menu',selectedWorld=1}
mobs={}; larme_indexes={}; direction='down'
shader_effect_timer=0; shader_duration=0.3
local gameCanvas,hitShader
function activateShaderEffect() shader_effect_timer=shader_duration end
function isShaderActive() return shader_effect_timer>0 end
function App.openEntry(world)
    if world==8 then if Worlds.canEnter(8) then Secret.open() end;return end
    App.practice=nil;App.sessionLayout=nil; App.singleLevel=false; App.workshopMap=nil
    if not Worlds.canEnter(world) then return end
    App.selectedWorld=world; App.draftName=Profile.name or ''
    App.error=nil; UI.focus='name'; App.state='entry'
    love.keyboard.setTextInput(true)
end
function App.submit()
    local name=App.draftName:match('^%s*(.-)%s*$')
    if name=='' then App.error='Entre un pseudo pour commencer.'; return end
    Profile.name=name; Profile.country=Online.country; Profile.save()
    App.start(App.selectedWorld)
end
function App.start(world)
    if world==8 then if Worlds.canEnter(8) then Secret.open() end;return end
    if not App.sessionLayout and not Worlds.canEnter(world) and not App.preview and os.getenv('SILKEN_TEST')~='1' and not Replay.playing then return end
    Profile.record('attempts')
    Arena.configure(love.graphics.getDimensions())
    if Replay.playing then Arena.width=Replay.data.width end
    gameCanvas=love.graphics.newCanvas(Arena.width,Arena.height)
    Campaign.starts={{},{},{},{},{},{},{}}; Campaign.lastSide=nil
    Campaign.select(world); App.selectedWorld=world
    timer=0; player.level=App.practice or (App.sessionLayout and App.sessionLayout.level) or 1; player.death=0; direction='down'
    shader_effect_timer=0; App.state='playing'; love.keyboard.setTextInput(false)
    Replay.begin(world)
    reset_level()
    Replay.leave()
    App.runSkin=Characters.selected()
    App.custom=os.getenv('SILKEN_PREVIEW_WORLD')~=nil
    for _,layout in pairs(LevelLayouts.read()) do if layout.world==world then App.custom=true end end
    if Worlds.isSecret(world) then App.custom=false end
    if not App.singleLevel then Online.start(world,Profile.name,App.runSkin) end
end
function love.load()
    love.graphics.setDefaultFilter('linear','linear')
    font_demon=love.graphics.newFont('police.ttf',40)
    if os.getenv('SILKEN_TEST')=='1' then love.filesystem.setIdentity('silken-hell-tests')
    elseif os.getenv('SILKEN_ONLINE_TEST')=='1' then love.filesystem.setIdentity('silken-hell-online-tests')
    elseif os.getenv('SILKEN_WORKSHOP_LIVE_TEST')=='1' then love.filesystem.setIdentity('silken-hell-workshop-tests') end
    Profile.load(); Input.load(); Bestiary.load(); Audio.load(); UI.load()
    load_level(); load_world(); load_player(); load_objet(); load_mob(); load_particles()
    local assetStart=love.timer.getTime(); Art.load()
    if os.getenv('SILKEN_BENCH')=='1' then print(string.format('ASSET_LOAD_SECONDS=%.3f',love.timer.getTime()-assetStart)) end
    if os.getenv('SILKEN_EXPORT_ART')=='1' then local f=assert(io.open(os.getenv('SILKEN_ART_PATH'),'wb')); f:write(require('json').encode(Art.metadata)); f:close(); love.event.quit(); return end
    Arena.configure(love.graphics.getDimensions())
    Campaign.install(); Campaign.select(1); reset_level()
    gameCanvas=love.graphics.newCanvas(Arena.width,Arena.height)
    hitShader=love.graphics.newShader('hyper_demon_shader.glsl')
    App.selectedWorld=1
    Online.init()
    if os.getenv('SILKEN_EXPORT_LEVELS')=='1' then require('designer.export').run(); love.event.quit(); return end
    local preview=tonumber(os.getenv('SILKEN_PREVIEW_WORLD'))
    if preview then
        Profile.unlocked=7; App.start(preview); player.level=tonumber(os.getenv('SILKEN_PREVIEW_LEVEL')) or 1; reset_level(); App.preview=true
    end
    if os.getenv('SILKEN_WORKSHOP_LIVE_TEST')=='1' then require('tests.workshop_live').run()
    elseif os.getenv('SILKEN_TEST')=='1' then require('tests.runtime').run()
    elseif os.getenv('SILKEN_ONLINE_TEST')=='1' then require('tests.online').run() end
end
function App.move(dt)
    if player.abyssHeld or player.abyssSpit or player.whirl or player.throw or player.tunnelTravel then player.has_moved=false; player.dashing=false; return end
    local k=Profile.keys
    local dx,dy=Input.move()
    player.has_moved=dx~=0 or dy~=0
    if dx~=0 then direction=dx>0 and 'right' or 'left'; player.last_mouve=dx>0 and 'player.x+' or 'player.x-' end
    if dy~=0 then direction=dy>0 and 'down' or 'up'; player.last_mouve=dy>0 and 'player.y+' or 'player.y-' end
    local length=math.sqrt(dx*dx+dy*dy)
    if length>0 then  player.lastMoveX=dx; player.lastMoveY=dy end
    local speed=300*player.speed*Hazards.speed()
    player.dashing=not Input.slow() and player.speed>0 and length>0
    if Bosses.riderInput(dx,dy,Input.slow(),dt) or (Octopus.active and Octopus.riderInput(dx,dy,Input.slow(),dt)) then
        player.has_moved=false; player.dashing=false; return
    end
    if player.dashing then speed=speed*1.8 end
    player.has_moved=(dx~=0 or dy~=0) and speed>0
    player.moveX=dx; player.moveY=dy
    -- Substeps prevent a dash from crossing a thin wall on a slow frame.
    local steps=math.max(1,math.ceil(speed*dt/8))
    for _=1,steps do
        local x=math.max(23,math.min(Arena.width-53,player.x+dx*speed*dt/steps))
        local y=math.max(23,math.min(553,player.y+dy*speed*dt/steps))
        if not willCollide(x,player.y) then player.x=x end
        if not willCollide(player.x,y) then player.y=y end
        Hazards.contact();Octopus.contact()
        for _,item in ipairs(Bosses.items) do if item.kind=='octopus' then item.boss.contact() end end
        if player.reset then break end
    end
    if player.has_moved then add_ghost(dt) end
end
function App.resolveDeath()
    if not player.reset then return false end
    if player.falling then player.fallTimer=.32 else Audio.play('death');reset_level() end
    return true
end
function love.update(dt)
    if App.quitDelay then App.quitDelay=App.quitDelay-dt;if App.quitDelay<=0 then love.event.quit() end;return end
    PreviewBridge.update(dt)
    UI.clock=UI.clock+dt
    Online.update(dt)
    Input.update(dt)
    if App.state=='worlds' then WorldMap.update(dt) end
    if App.state=='story' and Story.text~='' then
        UI.storyOffset=math.min(UI.storyLimit or math.huge,(UI.storyOffset or 0)+dt*Story.speed)
    end
    Audio.update(Profile,App.selectedWorld==2)
    if App.state=='bossWorld' then Secret.update(dt);return end
    if App.state~='playing' then Replay.accumulator=0;return end
    Replay.update(dt,App.simulate)
end
function App.simulate(dt)
    Secret.updateDuel(dt);if App.state~='playing' then return end
    if player.falling and player.fallTimer>0 then
        timer=timer+dt; player.fallTimer=math.max(0,player.fallTimer-dt)
        if player.fallTimer==0 then Audio.play('death'); reset_level() end
        return
    end
    -- Bound physics only; the scored clock still measures real active play time.
    timer=timer+dt; dt=math.min(dt,0.05)
    larme_float_timer=larme_float_timer+dt
    player.venom=math.max(0,player.venom-dt)
    player.ink=math.max(0,(player.ink or 0)-dt)
    Abyss.updatePlayer(dt)
    Aftermath.update(dt)
    update_shadow_dash(dt); update_freezes(dt); App.move(dt)
    if App.resolveDeath() then return end
    particleSystem:update(dt)
    Abyss.refreshLight()
    Campaign.updateTear(dt)
    for _,m in ipairs(mobs) do
        if m.type~='piege' and m.type~='scie' then Realms.capture(m) end
        local behavior=MobBehaviors[m.type]
        if not m.abyssHeld and behavior and behavior.update then behavior.update(m,dt) end
        if player.reset then break end
    end
    if App.resolveDeath() then return end
    Burning.update(dt)
    if App.resolveDeath() then return end
    Magma.update(dt)
    if App.resolveDeath() then return end
    Realms.update(dt)
    if App.resolveDeath() then return end
    Ocean.update(dt)
    Campaign.updateTear(0)
    for _,boss in ipairs({Raven,Wasp,Hedgehog,Octopus,Storm,Bosses}) do
        boss.update(dt)
        Aftermath.update(0)
        if App.resolveDeath() then return end
    end
    Abyss.refreshLight()
    BossFX.update(dt)
    shader_effect_timer=math.max(0,shader_effect_timer-dt)
    if App.resolveDeath() then return end
    if not player.tunnelTravel and Campaign.canCollect() and isTouching(player,objet.larme) then
        Audio.play('pick');Profile.record('tears')
        if not App.singleLevel then Online.checkpoint(player.level,timer,player.death) end
        if App.singleLevel then App.state='customVictory';if not Replay.playing then Replay.finish() end
        elseif player.level==Worlds.levelCount(Campaign.world) then
            if not App.singleLevel then Profile.complete(Campaign.world,timer,player.death) end
            UI.boardWorld=Campaign.world; App.state='victory'
        else player.level=player.level+1;Profile.levelReached(Campaign.world,player.level); reset_level() end
    end
end
function love.draw()
    love.graphics.clear(0.013,0.025,0.035)
    if App.state=='playing' then
        love.graphics.setCanvas(gameCanvas); love.graphics.clear(); love.graphics.origin(); love.graphics.setColor(1,1,1)
        draw_level()
        Atmosphere.drawDrops()
        -- Draw all floor traps first, regardless of their spawn order.
        for _,m in ipairs(mobs) do if m.type=='piege' or m.ground then Campaign.drawMob(m) end end
        draw_shadow_dash()
        for _,m in ipairs(mobs) do if m.type~='piege' and not m.ground then Campaign.drawMob(m) end end
        Realms.drawCreatures(); Raven.draw(); Hedgehog.draw(); Octopus.draw(); Storm.draw(); Wasp.draw(false); Bosses.draw(false); love.graphics.setColor(1,1,1); draw_player(direction); Ocean.drawBubble(); Wasp.draw(true); Bosses.draw(true); Abyss.drawBones(); AbyssTerrain.draw()
        Burning.drawMobs(); Atmosphere.draw()
        Realms.drawDarkness(); Realms.drawFireflies(); Abyss.drawLights(); Bosses.drawLights(); draw_player_beacon(); BossFX.draw();Aftermath.draw()
        love.graphics.setCanvas()
    elseif App.state=='bossWorld' then
        love.graphics.setCanvas(gameCanvas);love.graphics.origin();love.graphics.clear();Secret.drawWorld();love.graphics.setCanvas()
    end
    local w,h=love.graphics.getDimensions()
    if App.state=='playing' or App.state=='bossWorld' then
        local scale,x,y=App.viewport(w,h)
        local shakeX,shakeY=BossFX.offset();if App.state=='bossWorld' then shakeX,shakeY=0,0 end
        -- The arena normally covers the desktop. Render its backdrop only
        -- when letterboxing or camera shake actually exposes it.
        if x>.5 or y>.5 or shakeX~=0 or shakeY~=0 then
            if App.state=='playing' and Campaign.world==6 then
                local backdrop=Realms.floor
                local fill=math.max(w/backdrop:getWidth(),h/backdrop:getHeight())
                love.graphics.setColor(1,1,1)
                love.graphics.draw(backdrop,(w-backdrop:getWidth()*fill)/2,(h-backdrop:getHeight()*fill)/2,0,fill,fill)
            else BiomeFloor.draw(App.state=='bossWorld' and 8 or Campaign.biome,w,h,UI.clock) end
        end
        love.graphics.setColor(1,1,1)
        if App.state=='playing' and isShaderActive() then hitShader:send('time',UI.clock); hitShader:send('screen_size',{Arena.width,Arena.height}); love.graphics.setShader(hitShader) end
        love.graphics.draw(gameCanvas,x+shakeX*scale,y+shakeY*scale,0,scale,scale); love.graphics.setShader()
        if App.state=='playing' then Realms.drawWind(w,h); Octopus.drawInk(w,h); Bosses.drawInk(w,h) end
    elseif App.state=='worlds' then
        WorldMap.drawBackground(w,h)
    else
        UI.theme()
        love.graphics.setShader(UI.shader); love.graphics.setColor(1,1,1); love.graphics.draw(UI.pixel,0,0,0,w,h); love.graphics.setShader()
    end
    local s=math.min(w/1200,h/750)
    love.graphics.push(); love.graphics.translate((w-1200*s)/2,(h-750*s)/2); love.graphics.scale(s)
    UI.draw(); Input.draw(); love.graphics.pop()
    if App.capture then
        local path=App.capture; App.capture=nil
        love.graphics.captureScreenshot(function(data) data:encode('png',path) end)
    end
end
function love.mousepressed(x,y,button)
    Input.active=false
    if button==1 then local vx,vy=UI.mouse(x,y); UI.click(vx,vy) end
end
function love.textinput(text)
    if App.state=='workshop' then Workshop.text(text); return end
    if App.state~='entry' then return end
    text=text:gsub('[%c]','')
    local name=App.draftName..text
    if (utf8.len(name) or 99)<=16 then App.draftName=name end
    App.error=nil
end
function love.keypressed(key)
    Input.active=false
    if Replay.playing then
        if key=='escape' then Replay.stop()
        elseif key=='space' then Replay.paused=not Replay.paused
        elseif key=='right' then Replay.speed=math.min(4,Replay.speed*2)
        elseif key=='left' then Replay.speed=math.max(.5,Replay.speed/2) end
        return
    end
    if App.state=='worlds' then
        if key=='down' then WorldMap.step(1);return elseif key=='up' then WorldMap.step(-1);return end
    end
    if App.state=='bestiary' then
        if key=='down' or key=='pagedown' then UI.scrollBestiary(key=='down' and 40 or 140);return end
        if key=='up' or key=='pageup' then UI.scrollBestiary(key=='up' and -40 or -140);return end
    end
    if App.state=='workshop' and Workshop.focus then Workshop.key(key); return end
    if key=='f11' then App.toggleFullscreen(); return end
    if UI.binding then
        if key=='escape' then UI.binding=nil; return end
        if key=='unknown' then return end
        local old=Profile.keys[UI.binding]
        for action,value in pairs(Profile.keys) do if value==key then Profile.keys[action]=old end end
        Profile.keys[UI.binding]=key; UI.binding=nil; Profile.save(); return
    end
    if key=='escape' then
        Audio.play('back')
        if App.state=='menu' then App.state='quitConfirm'
        elseif App.state=='quitConfirm' then App.state='menu'
        elseif App.state=='playing' then App.state='pause'
        elseif App.state=='pause' then App.state='playing'
        elseif App.state=='workshop' or App.state=='customVictory' then App.leaveCustom()
        elseif App.state=='bestiary' then App.state=UI.bestReturn or 'menu'
        elseif App.state=='settings' then App.state=UI.returnTo or 'menu'
        else App.state='menu'; love.keyboard.setTextInput(false) end
    elseif App.state=='entry' then
        if key=='return' or key=='kpenter' then App.submit()
        elseif key=='backspace' then
            local field='draftName'
            local offset=utf8.offset(App[field],-1)
            if offset then App[field]=App[field]:sub(1,offset-1) end
        end
    end
end
function love.focus(focused)
    if not focused and App.state=='playing' then if Replay.playing then Replay.paused=true else App.state='pause' end end
end

function App.practiceLevel(world,n)
    if not Worlds.canEnter(world) or n<1 or n>math.max(1,(Profile.levels or {})[world] or 1) or n>Worlds.levelCount(world) then return false end
    App.practice=n;App.singleLevel=true;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
    Online.current=nil;App.start(world);return true
end
function App.leaveCustom()
    Replay.recording=false;Replay.input=nil;Workshop.validationRun=nil
    Workshop.focus=nil; love.keyboard.setTextInput(false)
    Secret.duel=nil;App.practice=nil;App.sessionLayout=nil; App.singleLevel=false; App.workshopMap=nil; App.state='menu'
end
function App.restartCurrent()
    if Secret.duel then Secret.duel.time=0 end
    App.start(Campaign.world)
end
function App.viewport(w,h)
    local scale=math.min(w/Arena.width,h/Arena.height)
    return scale,(w-Arena.width*scale)/2,(h-Arena.height*scale)/2
end
function App.toggleFullscreen()
    love.window.setFullscreen(not love.window.getFullscreen(),'desktop')
end
function love.wheelmoved(_,y)
    if App.state=='worlds' then WorldMap.wheel(y);return end
    if App.state=='bestiary' then UI.scrollBestiary(-y*42);return end
    if App.state=='story' and Story.text~='' then
        UI.storyOffset=math.max(0,math.min(UI.storyLimit or math.huge,(UI.storyOffset or 0)-y*35))
    end
end
function love.quit() if App.preview then love.filesystem.remove('preview-heartbeat.txt') end; Online.quit() end

function love.resize(w,h)
    if Replay and (Replay.playing or Replay.recording) then return end
    -- Reflow a running arena when its window shape changes; retain progress and boss health.
    if not player or not Campaign.data or not gameCanvas then return end
    local custom=Realms.custom or LevelLayouts.read()[Campaign.world..':'..player.level]~=nil
    local customWalls=Arena.interior
    local zones={holes=Realms.holes,tunnels=Realms.tunnels,tornadoes=Realms.tornadoes,current=Realms.current,rainSites=Realms.rainSites,vents=Realms.vents}
    local oldW=Arena.width; Arena.configure(w,h)
    if oldW==Arena.width then return end
    local ratio=Arena.width/oldW
    player.x=player.x*ratio
    local level=levels[player.level]
    level.player_position.x=level.player_position.x*ratio
    for _,p in ipairs(level.larme_position) do p.x=p.x*ratio end
    objet.larme.x=objet.larme.x*ratio
    for _,m in ipairs(mobs) do m.x=m.x*ratio end
    Arena.build(level.player_position,level.larme_position,Raven.active or Wasp.active or Hedgehog.active or Octopus.active or Storm.active)
    if custom then
        Arena.interior=customWalls; while #Arena.walls>4 do table.remove(Arena.walls) end
        for _,r in ipairs(customWalls) do r.x=r.x*ratio; r.w=r.w*ratio; Arena.walls[#Arena.walls+1]=r end
    end
    player.x,player.y=Arena.clearSpot(player.x,player.y,30,24)
    if Raven.active then
        Raven.x=Raven.x*ratio
        for _,list in ipairs({Raven.eggs,Raven.projectiles,Raven.nests}) do for _,p in ipairs(list) do p.x=p.x*ratio end end
        for _,m in ipairs(Raven.chicks) do m.cx=m.cx*ratio; m.x=m.x*ratio end
    end
    for _,p in ipairs(Hazards.lava) do p.x=p.x*ratio end
    if Wasp.active then Wasp.resize(ratio) end
    if not custom then Arena.reconcile() end
    if Hedgehog.active then
        Hedgehog.x=Hedgehog.x*ratio
        local x,y=Arena.clearSpot(Hedgehog.x-32,Hedgehog.y-32,64,64); Hedgehog.x=x+32; Hedgehog.y=y+32
        for _,p in ipairs(Hedgehog.projectiles) do p.x=p.x*ratio end
    end
    if Octopus.active then
        Octopus.x=Octopus.x*ratio
        for _,list in ipairs({Octopus.projectiles,Octopus.crabs,Octopus.wounds,Octopus.inkPools,Octopus.blasts}) do for _,p in ipairs(list) do p.x=p.x*ratio; if p.tx then p.tx=p.tx*ratio end; if p.fromX then p.fromX=p.fromX*ratio end end end
    end
    for _,b in ipairs(Ocean.bubbles) do b.x=b.x*ratio end
    if Campaign.biome>=4 or custom then
        local wind=Realms.wind; local illuminated=player.illuminated; local lightning=Realms.lightning; local lightningClock=Realms.lightningClock
        local rain,clock,bolts,eggs,larvae=Realms.rain,Realms.clock,Realms.bolts,Realms.eggs,Realms.larvae
        for _,list in ipairs({rain,bolts,eggs,larvae}) do for _,p in ipairs(list) do p.x=p.x*ratio end end
        Realms.reset(Campaign.biome,(Campaign.world==3 or Worlds.isSecret(Campaign.world)) and 10 or player.level); Realms.custom=custom
        Realms.wind=wind; Realms.rain=rain; Realms.clock=clock; Realms.bolts=bolts; Realms.eggs=eggs; Realms.larvae=larvae
        if custom then
            for key,list in pairs(zones) do for _,p in ipairs(list) do p.x=p.x*ratio end; Realms[key]=list end
        end
        if Abyss.active then
            Abyss.origin.x=Abyss.origin.x*ratio
            if Abyss.head then Abyss.head.x=Abyss.head.x*ratio end
            for _,p in ipairs(Abyss.lightSites) do p.x=p.x*ratio end
        end
        Ocean.relayout()
        player.illuminated=illuminated; Realms.lightning=lightning; Realms.lightningClock=lightningClock
        if Abyss.giant then Abyss.buildBones() end
    end
    local spit=player.abyssSpit; if spit then spit.fromX=spit.fromX*ratio; spit.toX=spit.toX*ratio end
    Magma.resize(ratio); Burning.resize(ratio)
    if Storm.active then
        Storm.x=Storm.x*ratio
        for _,list in ipairs({Storm.projectiles,Storm.strikes}) do for _,p in ipairs(list) do p.x=p.x*ratio end end
    end
    AbyssTerrain.resize(ratio or 1)
    Bosses.resize(ratio or 1)
    gameCanvas=love.graphics.newCanvas(Arena.width,Arena.height)
end

if os.getenv('SILKEN_TEST')=='1' then
    function love.errorhandler(message)
        io.stderr:write(tostring(message)..'\n'..debug.traceback()..'\n'); io.stderr:flush(); os.exit(1)
    end
end

function love.joystickadded(j) if Input then Input.add(j) end end
function love.joystickremoved(j) Input.remove(j) end
function love.gamepadpressed(j,b) Input.press(j,b) end
function love.gamepadaxis(j,axis,value) if math.abs(value)>.3 then Input.use(j) end end
