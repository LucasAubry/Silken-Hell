if os.getenv('SILKEN_TEST')=='1' then
    io.stdout:setvbuf('no')
    function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
end
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
Graphics=require 'graphics_settings'
local Psyche=require 'psychedelic_fx'
local Prism=require 'prism_material'
local OldTV=require 'old_tv'
local RunStart=require 'run_start'
local GameFeedback=require 'game_feedback'
RunDetails=require 'run_details'
Meadow=require 'meadow'
Renaissance=require 'renaissance'
Ending=require 'ending'
Hardcore=require 'hardcore'
require 'mobs.infernal'
Magma=require 'mobs.magma_larva.init'
Burning=require 'burning'
App={state='menu',selectedWorld=1}
mobs={}; larme_indexes={}; direction='down'
shader_effect_timer=0; shader_duration=0.3
local gameCanvas,polishShader
function activateShaderEffect()
    shader_effect_timer=shader_duration
    Psyche.death(player.x+15,player.y+12)
end
function isShaderActive() return shader_effect_timer>0 end
function App.openEntry(world,hardcore,fromWorld)
    App.entryFromWorld=fromWorld
    if hardcore and world~=8 and not Hardcore.available(world) then return false end
    App.hardcore=hardcore==true;WorldMap.hardcore=App.hardcore;UI.boardHardcore=App.hardcore;Hardcore.notice=nil
    if world==8 and not hardcore then if Worlds.canEnter(8) then Secret.open(false) end;return end
    Secret.duel=nil;App.practice=nil;App.sessionLayout=nil; App.singleLevel=false; App.workshopMap=nil
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
    App.entryFromWorld=nil
end
function App.start(world)
    if App.hardcore and not Replay.playing and not Hardcore.available(world) then return false end
    if world==8 and not App.hardcore then if Worlds.canEnter(8) then Secret.open(false) end;return end
    if not App.sessionLayout and not Worlds.canEnter(world) and not App.preview and os.getenv('SILKEN_TEST')~='1' and not Replay.playing then return end
    require('demo_progress').played()
    Achievements.level=nil
    if not App.historyPreview then Profile.record('attempts',world) end
    Arena.configure(love.graphics.getDimensions())
    if Replay.playing then Arena.width=Replay.data.width end
    gameCanvas=love.graphics.newCanvas(Arena.width,Arena.height)
    Campaign.starts={{},{},{},{},{},{},{}}; Campaign.lastSide=nil
    Campaign.select(world); App.selectedWorld=world
    Hardcore.notice=nil;timer=0;RunDetails.reset();UI.showRunDetails=false; player.level=App.practice or (App.sessionLayout and App.sessionLayout.level) or 1; player.death=0; direction='down'
    shader_effect_timer=0;Psyche.reset(); App.state='playing'; love.keyboard.setTextInput(false)
    if Audio.paradise then Audio.paradise:stop() end
    local notices=require('discovery_notice');notices.queue={};notices.active=nil
    if not App.historyPreview then Replay.begin(world) end
    reset_level()
    Replay.leave()
    App.runSkin=Characters.selected();App.runEffects=require('skin_effects').snapshot()
    App.custom=os.getenv('SILKEN_PREVIEW_WORLD')~=nil or require('platform').flag('--preview')
    for _,layout in pairs(LevelLayouts.read()) do if layout.world==world then App.custom=true end end
    if Worlds.isSecret(world) then App.custom=false end
    if not App.historyPreview and not App.singleLevel then Online.start(world,Profile.name,App.runSkin,App.hardcore) elseif not App.historyPreview then Online.current=nil end
    if world==1 and not Replay.playing and not App.historyPreview then require('sky_arrival').clearSource() end
    if world==6 and not Replay.playing and not App.historyPreview then require('earth_arrival').clearSource() end
    GameFeedback.reset();RunStart.begin()
    require("workshop_stats").begin()
end
function love.load()
    love.graphics.setDefaultFilter('linear','linear')
    local preload=require('texture_preload');preload.begin()
    font_demon=love.graphics.newFont('assets/fonts/police.ttf',40)
    if os.getenv('SILKEN_TEST')=='1' then love.filesystem.setIdentity('silken-hell-tests')
    elseif os.getenv('SILKEN_ONLINE_TEST')=='1' then love.filesystem.setIdentity('silken-hell-online-tests')
    elseif os.getenv('SILKEN_WORKSHOP_LIVE_TEST')=='1' then love.filesystem.setIdentity('silken-hell-workshop-tests') end
    App.preview=tonumber(os.getenv('SILKEN_PREVIEW_WORLD'))~=nil or require('platform').flag('--preview')
    local request=App.preview and PreviewBridge.request()
    local previewLayout=request and request.layout
    if previewLayout then App.sessionLayout=previewLayout;App.singleLevel=true;App.custom=true end
    Profile.load();require('app_icon').install();Hardcore.load();Graphics.load(); Input.load(); Bestiary.load(); Audio.load(); Audio.focus(love.window.hasFocus()); UI.load()
    load_level(); load_world(); load_player(); load_objet(); load_mob(); load_particles()
    local assetStart=love.timer.getTime(); Art.load(not not previewLayout);preload.load(previewLayout)
    if os.getenv('SILKEN_EXPORT_ICONS') then require('tools.export_icons').run(os.getenv('SILKEN_EXPORT_ICONS'));return end
    if os.getenv('SILKEN_BENCH')=='1' then print(string.format('ASSET_LOAD_SECONDS=%.3f',love.timer.getTime()-assetStart)) end
    if os.getenv('SILKEN_EXPORT_ART')=='1' then local f=assert(io.open(os.getenv('SILKEN_ART_PATH'),'wb')); f:write(require('json').encode(Art.metadata)); f:close(); love.event.quit(); return end
    Arena.configure(love.graphics.getDimensions())
    Campaign.install()
    local resetReplayLevel=reset_level
    reset_level=function(options) require('render_motion').reset();Replay.beforeLevelReset();Achievements.enterLevel();return resetReplayLevel(options) end
    Campaign.select(previewLayout and previewLayout.world or 1)
    if previewLayout then player.level=previewLayout.level;App.state='playing' else reset_level() end
    gameCanvas=love.graphics.newCanvas(Arena.width,Arena.height)
    polishShader=love.graphics.newShader('assets/shaders/polish.glsl')
    OldTV.load()
    Psyche.load()
    Prism.load()
    App.selectedWorld=1
    require('skin_unlock').init()
    require('achievement_notice').init()
    require('menu_preload').load()
    Online.init()
    if os.getenv('SILKEN_EXPORT_LEVELS')=='1' then require('designer.export').run(); love.event.quit(); return end
    local preview=tonumber(os.getenv('SILKEN_PREVIEW_WORLD'))
    if preview or require('platform').flag('--preview') then
        App.preview=true;PreviewBridge.update(.2)
    end
    if os.getenv('SILKEN_TEST')~='1' and os.getenv('SILKEN_ONLINE_TEST')~='1' and os.getenv('SILKEN_WORKSHOP_LIVE_TEST')~='1' and require('prologue').shouldStart() then require('prologue').open(false) end
    if os.getenv('SILKEN_WORKSHOP_LIVE_TEST')=='1' then require('tests.workshop_live').run()
    elseif os.getenv('SILKEN_TEST')=='1' then require('tests.runtime').run()
    elseif os.getenv('SILKEN_ONLINE_TEST')=='1' then require('tests.online').run() end
end
function App.move(dt)
    player.walkMoving=false
    player.has_moved=false
    local walkStartX,walkStartY=player.x,player.y
    if require('abyss_gate').closing and require('abyss_gate').active then player.dashing=false;player.has_moved=false;return end
    if Ending.locked() then player.dashing=false;player.has_moved=false;return end
    if Abyss.cagePlayer() then return end
    if player.abyssKnock or player.abyssHeld or player.abyssSpit or player.whirl or player.throw or player.skyWhirl or player.skyThrow or player.tunnelTravel then player.has_moved=false; player.dashing=false; return end
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
    local openEdges=require('sky').openEdges()
    for _=1,steps do
        local x,y=player.x+dx*speed*dt/steps,player.y+dy*speed*dt/steps
        if not openEdges then x=math.max(23,math.min(Arena.width-53,x));y=math.max(23,math.min(553,y)) end
        if not willCollide(x,player.y) then player.x=x end
        if not willCollide(player.x,y) then player.y=y end
        Hazards.contact();Octopus.contact()
        for _,item in ipairs(Bosses.items) do if item.kind=='octopus' then item.boss.contact() end end
        if player.reset or player.abyssKnock or Abyss.cagePlayer() then break end
    end
    player.has_moved=player.x~=walkStartX or player.y~=walkStartY
    require('brown_walk').advance(player,math.sqrt((player.x-walkStartX)^2+(player.y-walkStartY)^2),dt)
    if player.has_moved then add_ghost(dt) end
end
function App.respawn()
    local queen=require('final_spider')
    local resumeQueen=queen.active and queen.engaged and not queen.defeated
    -- Keep the dying level intact until its fall animation has finished.
    local retryWorld,retryLevel=Campaign.world,player.level
    Hardcore.death()
    Audio.play('death')
    reset_level({retry=Campaign.world==retryWorld and player.level==retryLevel})
    if resumeQueen and queen.active then
        queen.engaged=true;queen.phase='webs';queen.phaseTime=0;queen.shot=.65;queen.contactGrace=.35
    end
    require('retry_wait').begin()
end
function App.resolveDeath()
    if not player.reset then return false end
    if Replay.ghost then Replay.ghostRetry=true;return true end
    if player.falling and (player.fallTimer or 0)>0 then return true end
    require("workshop_stats").death()
    RunDetails.death()
    if player.falling then player.fallTimer=.32 else App.respawn() end
    return true
end
function love.update(dt)
    if App.quitDelay then App.quitDelay=App.quitDelay-dt;if App.quitDelay<=0 then love.event.quit() end;return end
    PreviewBridge.update(dt)
    require('creator_bridge').update(dt)
    UI.clock=UI.clock+dt
    UI.updatePress(dt)
    require('achievement_notice').update(dt)
    require('discovery_notice').update(dt)
    require('skin_unlock').update(dt)
    Online.update(dt)
    require("workshop_stats").update(dt)
    Input.update(dt)
    if App.state=='worlds' then WorldMap.update(dt) end
    if App.state=='story' and Story.text~='' then
        UI.storyOffset=math.min(UI.storyLimit or math.huge,(UI.storyOffset or 0)+dt*Story.speed)
    end
    Audio.update(Profile,App.selectedWorld==2 and App.state~='credits')
    if App.state=='credits' then Ending.updateCredits(dt);return end
    if App.state=='prologue' then require('prologue').update(dt);return end
    if App.state=='bossWorld' then Secret.update(dt);return end
    if App.state~='playing' then
        RunStart.suspend()
        if App.state=='victory' or App.state=='customVictory' then Psyche.update(dt) end
        Replay.accumulator=0;return
    end
    if Replay.recovery then Replay.update(dt,App.simulate);return end
    dt=RunStart.advance(dt)
    if dt<=0 then Replay.accumulator=0;return end
    Replay.update(dt,App.simulate)
    Story.updateWall(dt)
    GameFeedback.update(dt)
end
function App.simulate(dt)
    if (Replay.input and Replay.input[4]) or Replay.restartRequested then
        Replay.restartRequested=nil
        if not player.reset then player.death=player.death+1;Profile.record('deaths');RunDetails.death();require('workshop_stats').death() end
        App.respawn()
        require('retry_wait').reset()
    end
    require('render_motion').capture()
    Psyche.update(dt)
    if require('retry_wait').update(dt) then return end
    local liberation=require('boss_liberation')
    if liberation.busy() then liberation.update(dt);return end

    local arrival=require('mobs.bosses.abyss.arrival')
    if arrival.current and arrival.update(arrival.current,dt) then timer=timer+dt;RunDetails.tick(dt);return end
    require('abyss_gate').update(dt)
    Secret.updateDuel(dt);if App.state~='playing' then return end
    if Ending.active then
        update_shadow_dash(dt)
        shader_effect_timer=math.max(0,shader_effect_timer-dt)
        timer=timer+dt;RunDetails.tick(dt);dt=math.min(dt,.05)
        App.move(dt);Ending.update(dt)
        if App.state=='playing' then App.resolveDeath() end
        return
    end
    if player.falling and player.fallTimer>0 then
        timer=timer+dt;RunDetails.tick(dt); player.fallTimer=math.max(0,player.fallTimer-dt)
        if player.fallTimer==0 then App.respawn() end
        return
    end
    -- Bound physics only; the scored clock still measures real active play time.
    timer=timer+dt;RunDetails.tick(dt); dt=math.min(dt,0.05)
    larme_float_timer=larme_float_timer+dt
    player.venom=math.max(0,player.venom-dt)
    player.ink=math.max(0,(player.ink or 0)-dt)
    Abyss.updatePlayer(dt)
    Aftermath.update(dt)
    update_shadow_dash(dt); update_freezes(dt); App.move(dt)
    if liberation.busy() or App.resolveDeath() then return end
    particleSystem:update(dt)
    Abyss.refreshLight()
    Campaign.updateTear(dt)
    for _,m in ipairs(mobs) do
        if m.type~='piege' and m.type~='scie' then Realms.capture(m) end
        local behavior=MobBehaviors[m.type]
        if not m.abyssHeld and not Abyss.inSuctionShelter(m.x,m.y) and behavior and behavior.update then behavior.update(m,dt) end
        if player.reset then break end
    end
    if liberation.busy() or App.resolveDeath() then return end
    Burning.update(dt)
    if liberation.busy() or App.resolveDeath() then return end
    Magma.update(dt)
    if liberation.busy() or App.resolveDeath() then return end
    Renaissance.update(dt)
    if liberation.busy() or App.resolveDeath() then return end
    Realms.update(dt)
    if liberation.busy() or App.resolveDeath() then return end
    Ocean.update(dt)
    Campaign.updateTear(0)
    for _,boss in ipairs({Raven,Wasp,Hedgehog,Octopus,Storm,Bosses}) do
        boss.update(dt)
        Aftermath.update(0)
        if liberation.busy() or App.resolveDeath() then return end
    end
    Abyss.refreshLight()
    BossFX.update(dt)
    shader_effect_timer=math.max(0,shader_effect_timer-dt)
    if liberation.busy() or App.resolveDeath() then return end
    if Ending.checkHellVictory() then return end
    local collected=require('abyss_gate').ready or (Renaissance.active and Renaissance.collect())
    if not player.tunnelTravel and (collected or (not Renaissance.active and Campaign.canCollect() and Aftermath.canEnter() and isTouching(player,objet.larme))) then
        Psyche.collect(Renaissance.active and player.x+15 or objet.larme.x+15,
            Renaissance.active and player.y+12 or objet.larme.y+20,player.x+15,player.y+12)
        Achievements.finishLevel()
        if not Renaissance.active then Profile.record('tears') end
        if not App.singleLevel then Online.checkpoint(player.level,timer,player.death) end
        if App.singleLevel then App.state='customVictory';if not Replay.playing then Replay.finish() end
        elseif player.level==Worlds.levelCount(Campaign.world) then
            if App.hardcore then Hardcore.complete(Campaign.world) elseif not App.singleLevel then Profile.complete(Campaign.world,timer,player.death) end
            require('victory_screen').enter()
        else player.level=player.level+1;Hardcore.notify((Campaign.world==8 and 'Boss ' or 'Niveau ')..player.level..' · Rencontre suivante');if not App.hardcore then Profile.levelReached(Campaign.world,player.level) end; reset_level() end
    end
end
-- Render illustrated actors at display density in every biome and the sanctuary.
local function refreshSceneResolution()
    local g=love.graphics
    local density=1
    if App.state=='playing' or App.state=='bossWorld' then
        local w,h=g.getDimensions();local pw,ph=g.getPixelDimensions()
        local viewportScale=App.viewport(w,h)
        density=math.max(1,math.min(4,viewportScale*ph/h))
    end
    if math.abs(gameCanvas:getDPIScale()-density)>.001 then
        gameCanvas:release()
        gameCanvas=g.newCanvas(Arena.width,Arena.height,{dpiscale=density})
        gameCanvas:setFilter('linear','linear')
    end
    App.scenePixelHeight=gameCanvas:getPixelHeight()
    App.scenePixelDensity=density
end
function love.draw()
    if Replay.recovery then require('replay_recovery').draw(Replay);return end
    if Replay.legacy then
        local ok,err=xpcall(Replay.legacy.draw,debug.traceback)
        if not ok then require('retry_wait').endDraw();love.graphics.reset();Replay.fail(err) end
        return
    end
    require('retry_wait').beginDraw()
    local sceneCanvas=gameCanvas
    love.graphics.clear(0.013,0.025,0.035)
    if App.state=='playing' then
        refreshSceneResolution()
        love.graphics.setCanvas(gameCanvas); love.graphics.clear(); love.graphics.origin(); love.graphics.setColor(1,1,1)
        Prism.beginScene(gameCanvas)
        draw_level()
        if RunStart.arrival and RunStart.scene() and RunStart.scene().captureEnvironment then RunStart.scene().captureEnvironment(gameCanvas) end
        local queenScene=Ending.active and require('final_spider').active
        if queenScene then require('final_spider').drawGround() end

        if not Secret.inArena() then Atmosphere.drawDrops() end
        -- Draw all floor traps first, regardless of their spawn order.
        for _,m in ipairs(mobs) do if m.type=='piege' or m.ground then Campaign.drawMob(m) end end
        if Campaign.tearCarried() or Renaissance.active then Campaign.drawTear() end
        draw_shadow_dash()
        -- The former carrier stays behind its dropped tear; other creatures pass in front.
        local droppedCarrier=not Renaissance.active and objet.larme_dropped and Campaign.carrier or nil
        if droppedCarrier then
            for _,m in ipairs(mobs) do if m==droppedCarrier and m.type~='piege' and not m.ground then Campaign.drawMob(m) end end
            Campaign.drawTear()
        end
        for _,m in ipairs(mobs) do if m~=droppedCarrier and m.type~='piege' and not m.ground then Campaign.drawMob(m) end end
        Realms.drawCreatures(); Raven.draw(); Hedgehog.draw(); Octopus.draw(); Storm.draw(); Wasp.draw(false); Bosses.draw(false)
        Wasp.draw(true); Bosses.draw(true); Abyss.drawBones(); AbyssTerrain.draw()
        require('sky_weather').drawAtmosphere()
        Burning.drawMobs(); if not Secret.inArena() then Atmosphere.draw() end;require('biome_radiance').motes()
        if not Secret.inArena() then Realms.drawDarkness(); Realms.drawFireflies(); Realms.drawAnemoneElectric() end
        Abyss.drawLights(); Bosses.drawLights();require('earth_light').draw();require('abyss_gate').draw(); BossFX.draw();Aftermath.draw();require('boss_liberation').draw()
        -- Boss rewards remain readable above the arena effects.
        if not queenScene and not Campaign.tearCarried() and not droppedCarrier and not Renaissance.active then Campaign.drawTear(true) end
        local function drawFrame()
        Story.drawDecor(function()
            require('renaissance_frame').draw()
            require('earth_frame').draw()
            require('paradise_frame').draw()
            require('hell_frame').draw()
            require('biome_edge_life').draw()
        end)
        end
        if queenScene then drawFrame() end
        require('sky_arrival').captureSource(gameCanvas,not queenScene and drawFrame or nil)
        require('earth_arrival').captureSource(gameCanvas,not queenScene and drawFrame or nil)
        love.graphics.setColor(1,1,1)
        if RunStart.arrival then RunStart.drawArrivalActor();if Ending.active then Ending.drawFamily() end elseif Ending.active then Ending.drawPlayer();Ending.drawFamily() elseif not (require('abyss_gate').active and require('abyss_gate').closing and require('abyss_gate').age>.22) then draw_player(direction) end
        if not (RunStart.arrival and RunStart.scene()) and not (require('abyss_gate').active and require('abyss_gate').closing) then draw_player_beacon() end;if not Abyss.playerHidden() then Replay.drawGhost() end
        if not queenScene then drawFrame() end
        if queenScene then Campaign.drawTear(true) end
        Story.drawWallMessage()
        Prism.endScene();love.graphics.setCanvas()
        sceneCanvas=require('world_lighting').apply(gameCanvas)
    elseif App.state=='bossWorld' then
        refreshSceneResolution()
        sceneCanvas=gameCanvas
        love.graphics.setCanvas(gameCanvas);love.graphics.origin();love.graphics.clear();Prism.beginScene(gameCanvas);Secret.drawWorld();require('biome_radiance').motes();Prism.endScene();love.graphics.setCanvas()
        sceneCanvas=require('world_lighting').apply(gameCanvas)
    end
    local w,h=love.graphics.getDimensions()
    if App.state=='playing' or App.state=='bossWorld' then
        local scale,x,y=App.viewport(w,h)
        local shakeX,shakeY=BossFX.offset();if App.state=='playing' then local gx,gy=require('abyss_gate').shake();shakeX,shakeY=shakeX+gx,shakeY+gy end;if App.state=='bossWorld' then shakeX,shakeY=0,0 end
        -- The arena normally covers the desktop. Render its backdrop only
        -- when letterboxing or camera shake actually exposes it.
        if x>.5 or y>.5 or shakeX~=0 or shakeY~=0 then
            BiomeFloor.draw(App.state=='bossWorld' and 8 or (Campaign.world==3 and 3 or Campaign.biome),w,h,UI.clock)
        end
        love.graphics.setColor(1,1,1)
        local psychedelic=App.state=='playing' and Psyche.bind()
        if not psychedelic and Graphics.effects and Graphics.quality>1 and App.state=='playing' then polishShader:send('strength',Campaign.biome==7 and .18 or .65);love.graphics.setShader(polishShader) end
        if RunStart.arrival and RunStart.scene() and App.state=='playing' then RunStart.scene().draw(sceneCanvas,w,h)
        else love.graphics.draw(sceneCanvas,x+shakeX*scale,y+shakeY*scale,0,scale,scale) end; love.graphics.setShader()
        if App.state=='playing' then Octopus.drawInk(w,h); Bosses.drawInk(w,h) end
    elseif App.state=='prologue' then
        require('prologue').draw(w,h)
    elseif App.state=='skinUnlock' then
        love.graphics.clear(.008,.015,.027)
    elseif App.state=='credits' then
        Ending.drawCredits(w,h)
    elseif App.state=='worlds' then
        WorldMap.drawBackground(w,h)
    else
        UI.theme()
        love.graphics.setShader(UI.shader); love.graphics.setColor(1,1,1); love.graphics.draw(UI.pixel,0,0,0,w,h); love.graphics.setShader()
    end
    if App.state=='playing' then
        local scale,x,y=App.viewport(w,h)
        love.graphics.push('all');love.graphics.translate(x,y);love.graphics.scale(scale)
        Psyche.draw();GameFeedback.drawWorld();love.graphics.pop()
    end
    local s=math.min(w/1200,h/750)
    love.graphics.push(); love.graphics.translate((w-1200*s)/2,(h-750*s)/2); love.graphics.scale(s)
    local sceneArrival=App.state=='playing' and RunStart.arrival and RunStart.scene()~=nil
    if sceneArrival or App.historyPreview and App.state=='playing' then UI.buttons={};RunStart.draw()
    elseif App.state~='credits' then UI.draw();Input.draw();if App.state~='prologue' then require('discovery_notice').draw();RunStart.draw() end end
    if App.historyPreview then require('history').drawBack()
    elseif App.state~='prologue' then require('achievement_notice').draw();require('skin_unlock').drawToast() end;love.graphics.pop()
    -- The final collectible also celebrates over the results screen.
    if App.state=='victory' or App.state=='customVictory' then
        local scale,x,y=App.viewport(w,h)
        love.graphics.push('all');love.graphics.translate(x,y);love.graphics.scale(scale)
        Psyche.draw();love.graphics.pop()
    end
    if App.state=='playing' then Ending.drawOverlay(w,h) end
    Hardcore.drawBorder(w,h)
    if App.state~='credits' and App.state~='skinUnlock' and App.state~='prologue' and not Ending.active and not sceneArrival then
        love.graphics.push('all');love.graphics.origin();love.graphics.setShader()
        local cleanScreen=App.state=='settings' or App.state=='graphics' or App.state=='bestiary' or App.state=='bossWorld' or App.state=='achievements' or App.state=='history'
        love.graphics.setFont(cleanScreen and UI.fonts.body or UI.fonts.tiny)
        if not cleanScreen then love.graphics.setColor(.78,.78,.71,.7);love.graphics.print('v'..require('version'),12,h-18) end
        if Graphics.showFPS then love.graphics.setColor(.7,1,.8,.8);love.graphics.print(tostring(love.timer.getFPS())..' FPS',12,h-(cleanScreen and 26 or 33)) end
        love.graphics.pop()
    end
    OldTV.draw(w,h)
    if App.state=='playing' then require('abyss_gate').blackout() end
    if App.capture then
        local path=App.capture; App.capture=nil
        love.graphics.captureScreenshot(function(data) data:encode('png',path) end)
    end
    Graphics.pace()
    require('retry_wait').endDraw()
end
function love.mousepressed(x,y,button)
    Input.active=false
    if App.historyPreview and button==1 then local vx,vy=UI.mouse(x,y);if UI.click(vx,vy) then return end end
    if UI.binding then if UI.bindingDevice~='pad' then Input.bind('mouse:'..button) elseif button==1 then local vx,vy=UI.mouse(x,y);UI.click(vx,vy) end;return end
    if Replay.playing then
        if button==1 then local vx,vy=UI.mouse(x,y);if UI.click(vx,vy) then return end end
        Replay.key('mouse:'..button);return
    end
    if RunStart.press('mouse:'..button) then return end
    if not Replay.playing and Input.action('mouse:'..button) then return end
    if App.state=='playing' and not Replay.playing then for _,key in pairs(Profile.keys) do if key=='mouse:'..button then return end end end
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
function love.keypressed(key,scancode,isrepeat)
    Input.active=false
    if require('controller_setup').wizard then
        if key=='escape' then require('controller_setup').cancel() end
        return
    end
    if key=='escape' and not isrepeat then Audio.play('back') end
    if App.historyPreview and key=='escape' then require('history').close();return end
    if App.state=='history' and require('history').key(key) then return end
    if App.state=='prologue' then require('prologue').key(key);return end
    if App.state=='bossWorld' and Secret.key(key,isrepeat) then return end
    if key=='escape' and App.state=='victory' and require('podium_celebration').closePreview() then return end
    if App.state=='skinUnlock' then
        if not isrepeat and (key=='escape' or key=='return' or key=='space') then require('skin_unlock').close() end
        return
    end
    if App.state=='credits' then Ending.creditKey(key,isrepeat);return end
    if Replay.playing then Replay.key(key);return end
    if App.state=='worlds' then
        if key=='down' then WorldMap.step(1);return elseif key=='up' then WorldMap.step(-1);return elseif key=='right' then WorldMap.branch(true);return elseif key=='left' then WorldMap.branch(false);return elseif key=='return' then Audio.play('selection');App.openEntry(App.selectedWorld,WorldMap.hardcore);return end
    end
    if App.state=='achievements' then
        if key=='left' or key=='pageup' then Audio.play('go');require('achievements_screen').step(-1);return end
        if key=='right' or key=='pagedown' then Audio.play('go');require('achievements_screen').step(1);return end
        if key=='up' or key=='down' then Input.active=true;Input.navigate(0,key=='up' and -1 or 1);return end
        if key=='tab' then Input.active=true;Input.index=Input.index%math.max(1,#UI.buttons)+1;return end
        if key=='return' or key=='kpenter' or key=='space' then
            local b=UI.buttons[Input.index];if b then UI.click(b.x+b.w/2,b.y+b.h/2) end;return
        end
    end
    if App.state=='bestiary' then
        if key=='down' or key=='pagedown' then UI.scrollBestiary(key=='down' and 40 or 140);return end
        if key=='up' or key=='pageup' then UI.scrollBestiary(key=='up' and -40 or -140);return end
    end
    if App.state=='workshop' and Workshop.dropdown and key=='escape' then Workshop.dropdown=nil;Input.index=1;return end
    if App.state=='workshop' and Workshop.focus then Workshop.key(key); return end
    if key=='f11' then App.toggleFullscreen(); return end
    if UI.binding then
        if key=='escape' then Input.cancelBinding(); return end
        if UI.bindingDevice=='pad' then return end
        if key=='unknown' then return end
        Input.bind(key);return
    end
    if RunStart.press(key,isrepeat) then return end
    if Input.action(key) then return end
    if key=='escape' then
        if App.state=='menu' then App.state='quitConfirm'
        elseif App.state=='quitConfirm' then App.state='menu'
        elseif App.state=='playing' then App.state='pause'
        elseif App.state=='pause' then App.state='playing'
        elseif App.state=='customVictory' and Secret.duel then Secret.open()
        elseif App.state=='bossWorld' then WorldMap.hardcore=Secret.hardcore;WorldMap.open()
        elseif App.state=='workshop' or App.state=='customVictory' then App.leaveCustom()
        elseif App.state=='playerProfile' then require('player_profile').close()
        elseif App.state=='rankings' and RunDetails.view then RunDetails.view=nil
        elseif App.state=='rankings' then UI.backRankings()
        elseif App.state=='bestiary' then App.state=UI.bestReturn or 'menu'
        elseif App.state=='statistics' then App.state='achievements'
        elseif App.state=='topRecords' then App.state='achievements'
        elseif App.state=='graphics' then App.state='settings'
        elseif App.state=='settings' then App.state=UI.returnTo or 'menu'
        else App.state='menu'; love.keyboard.setTextInput(false) end
    elseif App.state=='entry' then
        if key=='return' or key=='kpenter' then Audio.play('selection');App.submit()
        elseif key=='backspace' then
            local field='draftName'
            local offset=utf8.offset(App[field],-1)
            if offset then App[field]=App[field]:sub(1,offset-1) end
        end
    end
end
function love.focus(focused)
    if focused and App.state=='workshop' then Workshop.reloadLocal() end
    Audio.focus(focused)
    if not focused and App.state=='prologue' then require('prologue').paused=true end
    if not focused and App.state=='playing' then if Replay.playing then if not Replay.recovery then Replay.paused=true end else App.state='pause' end end
end

function App.practiceLevel(world,n)
    if not Worlds.canEnter(world) or n<1 or n>math.max(1,(Profile.levels or {})[world] or 1) or n>Worlds.levelCount(world) then return false end
    App.hardcore=false;App.practice=n;App.singleLevel=true;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
    Online.current=nil;App.start(world);return true
end
function App.leaveCustom()
    Replay.recording=false;Replay.input=nil;Workshop.validationRun=nil
    Workshop.focus=nil; love.keyboard.setTextInput(false)
    App.hardcore=false;Hardcore.notice=nil;Secret.duel=nil;App.practice=nil;App.sessionLayout=nil; App.singleLevel=false; App.workshopMap=nil; App.state='menu'
end
function App.restartCurrent()
    local trainingRetry=App.state=='customVictory' and App.practice and not Secret.duel
    if Secret.duel then Secret.duel.time=0 end
    App.start(Campaign.world)
    if trainingRetry then
        RunStart.arrival=nil;RunStart.arrivalKind=nil;RunStart.arrivalPractice=false
        RunStart.waitForInput()
    elseif Secret.duel then RunStart.waitForInput() end
end
function App.restartLevel()
    if App.state~='playing' or Replay.playing or RunStart.arrival then return end
    Replay.restartRequested=true
end
function App.restartWorld()
    local training=App.practice~=nil or App.singleLevel
    App.practice=training and 1 or nil;App.singleLevel=training;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
    App.start(Campaign.world)
end
function App.practiceWorld(delta)
    if not App.practice and not App.singleLevel then return false end
    local world=delta>0 and Worlds.next(Campaign.world) or Worlds.previous(Campaign.world)
    if not world or not Worlds.canEnter(world) then return false end
    return App.practiceLevel(world,1)
end
function App.viewport(w,h)
    if Replay.playing then
        local ui=math.min(w/1200,h/750);local available=h-155*ui
        local scale=math.min(w/Arena.width,available/Arena.height)
        return scale,(w-Arena.width*scale)/2,65*ui+(available-Arena.height*scale)/2
    end
    local scale=math.min(w/Arena.width,h/Arena.height)
    return scale,(w-Arena.width*scale)/2,(h-Arena.height*scale)/2
end
function App.toggleFullscreen()
    love.window.setFullscreen(not love.window.getFullscreen(),'desktop')
end
function love.wheelmoved(_,y)
    if App.state=='achievements' then if y~=0 then Audio.play('go');require('achievements_screen').move(-y) end;return end
    if App.state=='worlds' then WorldMap.wheel(y);return end
    if App.state=='bestiary' then UI.scrollBestiary(-y*42);return end
    if App.state=='story' and Story.text~='' then
        UI.storyOffset=math.max(0,math.min(UI.storyLimit or math.huge,(UI.storyOffset or 0)-y*35))
    end
end
function love.quit() require('controller_usb').quit();if App.preview then love.filesystem.remove('preview-heartbeat.txt') end; Online.quit() end

function love.resize(w,h)
    require('render_motion').reset()
    require('biome_borders').key=nil
    for _,surface in ipairs(require('biome_floor').surfaces or {}) do surface.tick=nil end
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
    Ending.resize(ratio)
    require("abyss_gate").resize()
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
    for _,p in ipairs(Hazards.lava) do require('ground_holes').resize(p,ratio) end
    for _,p in ipairs(Hazards.electric) do require('ground_holes').resize(p,ratio) end
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
        local illuminated=player.illuminated
        local rain,clock,bolts,eggs,larvae=Realms.rain,Realms.clock,Realms.bolts,Realms.eggs,Realms.larvae
        for _,list in ipairs({rain,bolts,eggs,larvae}) do for _,p in ipairs(list) do p.x=p.x*ratio end end
        Realms.reset(Campaign.biome,(Campaign.world==3 or Worlds.isSecret(Campaign.world)) and 10 or player.level); Realms.custom=custom
        Realms.rain=rain; Realms.clock=clock; Realms.bolts=bolts; Realms.eggs=eggs; Realms.larvae=larvae
        if custom then
            for key,list in pairs(zones) do for _,p in ipairs(list) do require('ground_holes').resize(p,ratio) end; Realms[key]=list end
        end
        if Abyss.active then
            Abyss.resize(ratio)
        end
        Ocean.relayout()
        player.illuminated=illuminated
        if Abyss.giant then Abyss.buildBones() end
    end
    local spit=player.abyssSpit; if spit then spit.fromX=spit.fromX*ratio; spit.toX=spit.toX*ratio end
    Renaissance.resize(ratio)
    require('sky_weather').resize(ratio)
    Magma.resize(ratio); Burning.resize(ratio)
    if Storm.active then Storm.resize(ratio) end
    AbyssTerrain.resize(ratio or 1)
    Bosses.resize(ratio or 1)
    gameCanvas=love.graphics.newCanvas(Arena.width,Arena.height)
end

local defaultErrorHandler=love.errorhandler
function love.errorhandler(message)
    local trace=tostring(message)..'\n'..debug.traceback()
    if os.getenv('SILKEN_TEST')=='1' then
        io.stderr:write(trace..'\n'); io.stderr:flush(); os.exit(1)
    end
    -- Preserve the normal error screen and keep diagnostic context across restarts.
    pcall(function()
        local context=string.format('%s | state=%s world=%s level=%s reset=%s falling=%s hardcore=%s\n',
            os.date('%Y-%m-%d %H:%M:%S'),tostring(App and App.state),tostring(Campaign and Campaign.world),
            tostring(player and player.level),tostring(player and player.reset),tostring(player and player.falling),tostring(App and App.hardcore))
        love.filesystem.write('last-crash.log',context..trace..'\n')
    end)
    return defaultErrorHandler(message)
end

function love.joystickadded(j) if Input then Input.add(j) end end
function love.joystickremoved(j) Input.remove(j) end
function love.gamepadpressed(j,b) Input.press(j,b) end
function love.gamepadaxis(j,axis,value) Input.axis(j,axis,value) end
