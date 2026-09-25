local T={}
local function level(w,n)
    Campaign.select(w); player.level=n; reset_level(); App.state='playing'
end
local function damageBird()
    local f=Raven.eggs[1]; local previous=f.spot
    Raven.projectiles={{x=f.x,y=f.y,vx=0,vy=0,life=1}}; Raven.shot=100
    local hp=Raven.hp; Raven.update(.01); assert(Raven.hp==hp-1)
    if not Raven.defeated then assert(f.spot~=previous) end
end
function T.run()
    if os.getenv("SILKEN_ABYSS_PATTERNS_TEST")=="1" then require("tests.abyss_patterns").run();return end
    if os.getenv("SILKEN_ABYSS_WHIP_TEST")=="1" then require("tests.abyss_whip").run();return end
    if os.getenv("SILKEN_LOCALIZATION_TEST")=="1" then require("tests.localization").run();return end
    if os.getenv("SILKEN_REPLAY_TOOLS_TEST")=="1" then require("tests.replay_tools").run();return end
    if os.getenv("SILKEN_REPLAY_COMPAT_TEST")=="1" then require("tests.replay_compat").run();return end
    if os.getenv("SILKEN_STORM_LIGHT_TEST")=="1" then require("tests.storm_light").run();return end
    if os.getenv("SILKEN_REBIRTH_TEST")=="1" then require("tests.rebirth").run();return end
    if os.getenv("SILKEN_SKY_MERLE_TEST")=="1" then require("tests.sky_merle").run();return end
    if os.getenv("SILKEN_ABYSS_LASER_TEST")=="1" then require("tests.abyss_laser_cycle").run();return end
    if os.getenv("SILKEN_ABYSS_MINES_TEST")=="1" then require("tests.abyss_mines").run();return end
    if os.getenv("SILKEN_BOSS_RELOAD_TEST")=="1" then require("tests.boss_reload").run();return end
    if os.getenv("SILKEN_ABYSS_LEFT_TEST")=="1" then require("tests.abyss_left").run();return end
    if os.getenv("SILKEN_EARTH_CAGES_TEST")=="1" then require("tests.earth_cages").run();return end
    if os.getenv("SILKEN_MAP_REFINE_TEST")=="1" then require("tests.hardcore_map_refine").run();return end
    if os.getenv("SILKEN_HARDCORE_TEST")=="1" then require("tests.request_hardcore").run();return end
    if os.getenv("SILKEN_POLISH_TEST")=="1" then require("tests.polish").run();return end
    if os.getenv("SILKEN_GPU_TEST")=="1" then require("tests.perf_poulpe").run();return end
    if os.getenv("SILKEN_SEPT23_TEST")=="1" then require("tests.sept23").run();return end
    if os.getenv("SILKEN_BOSSES_TEST")=="1" then require("tests.bosses_three_phase").run();return end
    if os.getenv("SILKEN_EGG_TEN_TEST")=="1" then require("tests.egg_ten").run();return end
    if os.getenv("SILKEN_REFINEMENT_TEST")=="1" then require("tests.balance_refinement").run();return end
    if os.getenv("SILKEN_NEST_TEST")=="1" then require("tests.nest_revision").run();return end
    if os.getenv("SILKEN_PERFORMANCE_TEST")=="1" then require("tests.performance_revision").run();return end
    if os.getenv("SILKEN_OCEAN_TEST")=="1" then require("tests.ocean_revision").run();return end
    if os.getenv("SILKEN_HUD_TEST")=="1" then require("tests.boss_hud").run();return end
    if os.getenv("SILKEN_REPLAY_TEST")=="1" then require("tests.replay_revision").run();return end
    if os.getenv("SILKEN_OCTOPUS_PERF")=="1" then require("tests.octopus_performance").run();return end
    if os.getenv("SILKEN_GOAL_TEST")=="1" then require("tests.goal_revision").run();return end
    if os.getenv("SILKEN_REWORK_TEST")=="1" then require("tests.octopus_rework").run();return end
    if os.getenv("SILKEN_OCTOPUS_INFO_TEST")=="1" then require("tests.octopus_info").run();return end
    if os.getenv("SILKEN_STATS_TEST")=="1" then require("tests.stats_light").run();return end
    if os.getenv("SILKEN_FINAL_TEST")=="1" then require("tests.final_revision").run();return end
    if os.getenv("SILKEN_PAD_TEST")=="1" then require("tests.controller_revision").run();return end
    if os.getenv("SILKEN_CONTROLS_TEST")=="1" then require("tests.controls_revision").run();return end
    if os.getenv("SILKEN_SECRET_TEST")=="1" then require("tests.secret_revision").run();return end
    if os.getenv("SILKEN_SECRET_QA")=="1" then require("tests.secret_revision").visual();return end
    if os.getenv("SILKEN_ABYSS_EDITOR_TEST")=="1" then require("tests.abyss_editor").run();love.event.quit();return end
    if os.getenv("SILKEN_REQUEST_QA")=="1" then require("tests.requested_bosses").visual();return end
    if os.getenv("SILKEN_REQUEST_TEST")=="1" then require("tests.requested_bosses").run();return end
    if os.getenv("SILKEN_TRIO_QA")=="1" then require("tests.wasp_trio").visual();return end
    if os.getenv("SILKEN_INK_LAVA_QA")=="1" then require("tests.ink_lava").visual(); return end
    if os.getenv("SILKEN_DEPTH_QA")=="1" then require("tests.fire_scoring").visual(); return end
    if os.getenv("SILKEN_ATMOSPHERE_QA")=="1" then require("tests.abyss_atmosphere").visual(); return end
    if os.getenv("SILKEN_RENAISSANCE_QA")=="1" then require("tests.renaissance").visual(); return end
    if os.getenv("SILKEN_ABYSS_BREATH_QA")=="1" then require("tests.abyss_breath").visual(); return end
    if os.getenv("SILKEN_MAGMA_QA")=="1" then require("tests.magma").visual(); return end
    if os.getenv('SILKEN_WORKSHOP_QA')=='1' then require('tests.workshop_editor').visual(); return end
    if os.getenv('SILKEN_FISH_DEATH_TEST')=='1' then require('tests.fish_death').run(); love.event.quit(); return end
    if os.getenv("SILKEN_EXPANSION_QA")=="1" then require("tests.expansion").visual(); return end
    if os.getenv('SILKEN_WORLD_QA')=='1' then require('tests.world_revision').visual(); return end
    if os.getenv('SILKEN_OCTOPUS_QA')=='1' then require('tests.octopus_revision').visual(); return end
    if os.getenv('SILKEN_REFINEMENTS_QA')=='1' then require('tests.refinements').visual(); return end
    if os.getenv('SILKEN_TRAVERSAL_QA')=='1' then require('tests.traversal').visual(); return end
    if os.getenv('SILKEN_TERRAIN_TEST')=='1' then require('tests.terrain_serpent').run(); love.event.quit(); return end
    if os.getenv('SILKEN_TERRAIN_QA')=='1' then require('tests.terrain_visual').run(); return end
    if os.getenv('SILKEN_MARINE_QA')=='1' then require('tests.marine_visual').run(); return end
    if os.getenv('SILKEN_BIOME_QA')=='1' then require('tests.biomes_visual').run(); return end
    if os.getenv('SILKEN_ENCOUNTER_QA')=='1' then require('tests.encounters_visual').run(); return end
    if os.getenv('SILKEN_VISUAL_QA')=='1' then require('tests.visual_release').run(); return end
    if os.getenv("SILKEN_ASSET_QA")=="1" then require("tests.assets").run(); return end
    Profile.unlocked=2; Profile.scores={}; Profile.name='Test'; Profile.country='FR'; Online.country='FR'
    App.start(1)
    require("tests.wasp_trio").run()
    require("tests.ink_lava").run()
    require("tests.editor_rates").run()
    require("tests.fire_scoring").run()
    require("tests.abyss_atmosphere").run()
    require("tests.renaissance").run()
    require("tests.abyss_breath").run()
    require("tests.magma").run()
    require("tests.gameplay_v5").run()
    require('tests.release').run()
    require('tests.encounters').run()
    require('tests.bosses_rankings').run()
    require('tests.ocean_progression').run()
    require('tests.marine_revision').run()
    require('tests.terrain_serpent').run()
    require('tests.traversal').run()
    require('tests.refinements').run()
    require('tests.octopus_revision').run()
    require('tests.world_revision').run()
    require('tests.expansion').run()
    require('tests.workshop_editor').run()
    for _,name in ipairs({'nest','lava','black_feather'}) do
        local d=love.image.newImageData('assets/sprites/'..name..'.png')
        local _,_,_,a=d:getPixel(0,0); assert(a==0,'PNG transparent '..name); d:release()
    end
    for _,name in ipairs({'spider','imp','serpent','merle','wasp','wasp_ground','hell_spider','ocean_spider','crown_spider','jelly','fish','worm','mole','gull'}) do
        for _,dir in ipairs({'down','up','left','right'}) do
            local d=Art.imageData('assets/sprites/directional/'..name..'_'..dir..'.png')
            local _,_,_,a=d:getPixel(0,0); assert(a==0,'Alpha directionnel '..name..'_'..dir); d:release()
        end
    end
    for w=1,2 do for n=1,10 do
        level(w,n); assert((w==1 and #Arena.interior==0) or (w==2 and #Arena.interior>0),'Murs par monde')
        assert(not willCollide(player.x,player.y),'Spawn libre')
        for _,p in ipairs(levels[n].larme_position) do assert(p.x>=22 and p.x+30<Arena.width-22 and p.y>=22 and p.y<553) end
        love.draw()
        if Campaign.carrier then
            assert(not Campaign.canCollect(),'Larme portée non collectable')
            local m=Campaign.carrier; local trap
            for _,other in ipairs(mobs) do if other.type=='piege' then trap=other; break end end
            assert(trap,'Piège pour chaque porteur')
            player.x=60; player.y=300
            m.x=trap.x; m.y=trap.y
            MobBehaviors[m.type].update(m,0)
            assert(objet.larme_dropped and Campaign.canCollect(),'Le piège libère la larme')
            local x,y=objet.larme.x,objet.larme.y; Campaign.updateTear(4)
            assert(objet.larme.x==x and objet.larme.y==y,'La larme déposée reste au sol')
        end
    end end
    level(1,10)
    assert(Raven.name=='Le Merle noir' and Raven.interval()<.3)
    local x,y=Raven.x,Raven.y; Raven.update(.01); assert(Raven.x==x and Raven.y==y)
    local nest=Raven.nests[2]
    player.x=nest.x-15; player.y=nest.y-12; assert(Hazards.speed()<.2,'Nid ralentit fortement')
    player.x=60; player.y=500
    Raven.projectiles={{x=nest.x,y=nest.y,vx=300,vy=0,life=4}}; Raven.shot=100; Raven.update(.01)
    assert(#Raven.projectiles==2,'Deux fragments exactement')
    local a,b=Raven.projectiles[1],Raven.projectiles[2]
    assert(a.vx>290 and b.vx>290 and a.vy*b.vy<0,'Directions proches et divergentes')
    Raven.update(.01); assert(#Raven.projectiles==2,'Pas de division récursive dans le même nid')
    Raven.projectiles={{x=player.x+15,y=player.y+12,vx=0,vy=0,life=2}}
    local deaths=player.death; Raven.update(.01); assert(player.reset and player.death==deaths+1)
    reset_level(); assert(Raven.hp==12 and #Raven.projectiles==0)
    for _=1,12 do damageBird() end
    assert(Raven.defeated and Campaign.canCollect())
    level(2,10); Wasp.reset(true)
    Wasp.projectiles={{x=player.x+15,y=player.y+12,vx=0,vy=0,life=1,kind='venom'}}
    Wasp.update(.01);assert(player.venom==3 and not player.reset,'Venin hérité ralentit sans tuer')
    require('tests.wasp_trio').defeat(Wasp);assert(Wasp.defeated and Campaign.canCollect())
    level(2,3); local p=Hazards.lava[1]; player.x=p.x-15; player.y=p.y-12; Hazards.contact(); assert(player.reset,'Lave mortelle')
    reset_level(); assert(player.venom==0 and not player.reset)
    -- Progression and scores still finish each world once.
    Profile.scores={}
    for w=1,2 do App.start(w)
        for n=1,10 do
            player.level=n; reset_level(); mobs={}; Campaign.carrier=nil; objet.larme_dropped=true
            if Raven.active then for _=1,12 do damageBird() end end
            if Wasp.active then
                require('tests.wasp_trio').defeat(Wasp)
            end
            player.x=objet.larme.x; player.y=objet.larme.y; love.update(.01)
        end
        assert(App.state=='victory' and #Profile.scores==w,'Progression et score monde '..w)
    end
    for _,state in ipairs({'menu','entry','settings','worlds','boards','pause','victory','story','bestiary'}) do App.state=state; App.draftName='Test'; love.draw() end
    level(1,10); local hp=Raven.hp; love.resize(1600,900); assert(Raven.hp==hp); love.resize(love.graphics.getDimensions())
    print('PASS v4: 20 niveaux, porteurs/pièges, merle, fragments/nids, guêpe vol/sol/contact/venin/invocations, lave, PNG alpha, progression et écrans'); io.stdout:flush()
    local ticks=0
    love.update=function(dt)
        ticks=ticks+1; UI.clock=UI.clock+dt
        if ticks==1 then level(1,10); local n=Raven.nests[1]; Raven.projectiles={{x=n.x,y=n.y,vx=-240,vy=-100,life=4}}; Raven.shot=100; Raven.update(.01); for _,p in ipairs(Raven.projectiles) do p.x=p.x+p.vx*.35; p.y=p.y+p.vy*.35 end; App.capture='merle-v4-qa.png' end
        if ticks==5 then level(2,10); Wasp.reset(true); Wasp.phase='landed'; Wasp.x=Arena.width/2; Wasp.y=300; Wasp.fire('venom'); for _,p in ipairs(Wasp.projectiles) do p.x=p.x+p.vx*.65; p.y=p.y+p.vy*.65 end; App.capture='wasp-ground-v4-qa.png' end
        if ticks==9 then Wasp.phase='flying'; Wasp.summon=0; Wasp.update(.05); App.capture='wasp-air-v4-qa.png' end
        if ticks==13 then level(2,7); App.capture='hell-v5-qa.png' end
        if ticks==17 then level(1,5); App.capture='carrier-v4-qa.png' end
        if ticks==21 then love.event.quit(0) end
    end
end
return T
