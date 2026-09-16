require 'player'
require 'world'
require 'objet'
require 'hit_box'
require 'level'
for i=1,10 do require('levels/level_'..i) end
require 'mob'
require 'effect'
local utf8=require 'utf8'
Worlds=require 'worlds'
Profile=require 'profile'
Audio=require 'audio'
Campaign=require 'campaign'
UI=require 'interface'
Online=require 'online'
Story=require 'story'
Art=require 'art'
Arena=require 'arena'
Raven=require 'raven'
Wasp=require 'wasp'
Hazards=require 'hazards'
Characters=require 'characters'
Bestiary=require 'bestiary'
Realms=require 'realms'
require 'infernal'
App={state='menu',selectedWorld=1}
mobs={}; larme_indexes={}; direction='down'
shader_effect_timer=0; shader_duration=0.3
local gameCanvas,hitShader
function activateShaderEffect() shader_effect_timer=shader_duration end
function isShaderActive() return shader_effect_timer>0 end
function App.openEntry(world)
    if not Worlds.canEnter(world) then return end
    App.selectedWorld=world; App.draftName=''
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
    if not Worlds.canEnter(world) then return end
    Arena.configure(love.graphics.getDimensions())
    gameCanvas=love.graphics.newCanvas(Arena.width,Arena.height)
    Campaign.starts={{},{},{},{},{},{}}; Campaign.lastSide=nil
    Campaign.select(world); App.selectedWorld=world
    timer=0; player.level=1; player.death=0; direction='down'
    shader_effect_timer=0; App.state='playing'; love.keyboard.setTextInput(false)
    reset_level()
    App.runSkin=Characters.selected()
    Online.start(world,Profile.name,App.runSkin)
end
function love.load()
    love.graphics.setDefaultFilter('linear','linear')
    font_demon=love.graphics.newFont('police.ttf',40)
    if os.getenv('SILKEN_TEST')=='1' then love.filesystem.setIdentity('silken-hell-tests')
    elseif os.getenv('SILKEN_ONLINE_TEST')=='1' then love.filesystem.setIdentity('silken-hell-online-tests') end
    Profile.load(); Bestiary.load(); Audio.load(); UI.load()
    load_level(); load_world(); load_player(); load_objet(); load_mob(); load_particles()
    Art.load(); Arena.configure(love.graphics.getDimensions())
    Campaign.install(); Campaign.select(1); reset_level()
    gameCanvas=love.graphics.newCanvas(Arena.width,Arena.height)
    hitShader=love.graphics.newShader('hyper_demon_shader.glsl')
    App.selectedWorld=1
    Online.init()
    if os.getenv('SILKEN_TEST')=='1' then require('tests.runtime').run()
    elseif os.getenv('SILKEN_ONLINE_TEST')=='1' then require('tests.online').run() end
end
local function move(dt)
    local k=Profile.keys
    local dx=(love.keyboard.isDown(k.right) and 1 or 0)-(love.keyboard.isDown(k.left) and 1 or 0)
    local dy=(love.keyboard.isDown(k.down) and 1 or 0)-(love.keyboard.isDown(k.up) and 1 or 0)
    player.has_moved=dx~=0 or dy~=0
    if dx~=0 then direction=dx>0 and 'right' or 'left'; player.last_mouve=dx>0 and 'player.x+' or 'player.x-' end
    if dy~=0 then direction=dy>0 and 'down' or 'up'; player.last_mouve=dy>0 and 'player.y+' or 'player.y-' end
    local length=math.sqrt(dx*dx+dy*dy)
    if length>0 then dx=dx/length; dy=dy/length end
    local speed=300*player.speed*Hazards.speed()
    player.dashing=love.keyboard.isDown(k.dash) and player.speed>0
    if love.keyboard.isDown(k.dash) then
        speed=speed*1.8
        if length==0 then dx=direction=='right' and 1 or direction=='left' and -1 or 0; dy=direction=='down' and 1 or direction=='up' and -1 or 0 end
    end
    player.moveX=dx; player.moveY=dy
    -- Substeps prevent a dash from crossing a thin wall on a slow frame.
    local steps=math.max(1,math.ceil(speed*dt/8))
    for _=1,steps do
        local x=math.max(23,math.min(Arena.width-53,player.x+dx*speed*dt/steps))
        local y=math.max(23,math.min(553,player.y+dy*speed*dt/steps))
        if not willCollide(x,player.y) then player.x=x end
        if not willCollide(player.x,y) then player.y=y end
        Hazards.contact(); if player.reset then break end
    end
    if player.has_moved then add_ghost(dt) end
end
function love.update(dt)
    UI.clock=UI.clock+dt
    Online.update(dt)
    if App.state=='story' and Story.text~='' then
        UI.storyOffset=math.min(UI.storyLimit or math.huge,(UI.storyOffset or 0)+dt*Story.speed)
    end
    Audio.update(Profile,App.selectedWorld==2)
    if App.state~='playing' then return end
    -- Bound physics only; the scored clock still measures real active play time.
    timer=timer+dt; dt=math.min(dt,0.05)
    larme_float_timer=larme_float_timer+dt
    player.venom=math.max(0,player.venom-dt)
    update_shadow_dash(dt); update_freezes(dt); move(dt); particleSystem:update(dt)
    Campaign.updateTear(dt)
    for _,m in ipairs(mobs) do
        local behavior=MobBehaviors[m.type]
        if behavior and behavior.update then behavior.update(m,dt) end
        if player.reset then break end
    end
    Realms.update(dt)
    Campaign.updateTear(0)
    if not player.reset then Raven.update(dt); Wasp.update(dt) end
    shader_effect_timer=math.max(0,shader_effect_timer-dt)
    if player.reset then Audio.play('death'); reset_level(); return end
    if Campaign.canCollect() and isTouching(player,objet.larme) then
        Audio.play('pick')
        Online.checkpoint(player.level,timer,player.death)
        if player.level==10 then
            Profile.complete(Campaign.world,timer,player.death)
            UI.boardWorld=Campaign.world; App.state='victory'
        else player.level=player.level+1; reset_level() end
    end
end
function love.draw()
    love.graphics.clear(0.013,0.025,0.035)
    if App.state=='playing' then
        love.graphics.setCanvas(gameCanvas); love.graphics.clear(); love.graphics.origin(); love.graphics.setColor(1,1,1)
        draw_level()
        -- Draw all floor traps first, regardless of their spawn order.
        for _,m in ipairs(mobs) do if m.type=='piege' then Campaign.drawMob(m) end end
        draw_shadow_dash()
        for _,m in ipairs(mobs) do if m.type~='piege' then Campaign.drawMob(m) end end
        Raven.draw(); Wasp.draw(false); love.graphics.setColor(1,1,1); draw_player(direction); Wasp.draw(true)
        love.graphics.setCanvas()
    end
    local w,h=love.graphics.getDimensions()
    if App.state=='playing' then
        -- Extend the world artwork over the entire desktop, preserving the arena's proportions.
        local backdrop=Campaign.world==1 and world.background_lv or Campaign.world==2 and Campaign.floor or Realms.floor
        local fill=math.max(w/backdrop:getWidth(),h/backdrop:getHeight())
        love.graphics.setColor(1,1,1)
        love.graphics.draw(backdrop,(w-backdrop:getWidth()*fill)/2,(h-backdrop:getHeight()*fill)/2,0,fill,fill)
        local scale,x,y=App.viewport(w,h)
        if isShaderActive() then hitShader:send('time',UI.clock); hitShader:send('screen_size',{Arena.width,Arena.height}); love.graphics.setShader(hitShader) end
        love.graphics.draw(gameCanvas,x,y,0,scale,scale); love.graphics.setShader()
    else
        UI.shader:send('time',UI.clock); UI.shader:send('inferno',App.selectedWorld==2 and 1 or 0)
        love.graphics.setShader(UI.shader); love.graphics.setColor(1,1,1); love.graphics.draw(UI.pixel,0,0,0,w,h); love.graphics.setShader()
    end
    local s=math.min(w/1200,h/750)
    love.graphics.push(); love.graphics.translate((w-1200*s)/2,(h-750*s)/2); love.graphics.scale(s)
    UI.draw(); love.graphics.pop()
    if App.capture then
        local path=App.capture; App.capture=nil
        love.graphics.captureScreenshot(function(data) data:encode('png',path) end)
    end
end
function love.mousepressed(x,y,button)
    if button==1 then local vx,vy=UI.mouse(x,y); UI.click(vx,vy) end
end
function love.textinput(text)
    if App.state~='entry' then return end
    text=text:gsub('[%c]','')
    local name=App.draftName..text
    if (utf8.len(name) or 99)<=16 then App.draftName=name end
    App.error=nil
end
function love.keypressed(key)
    if key=='f11' then App.toggleFullscreen(); return end
    if UI.binding then
        if key=='escape' then UI.binding=nil; return end
        if key=='unknown' then return end
        local old=Profile.keys[UI.binding]
        for action,value in pairs(Profile.keys) do if value==key then Profile.keys[action]=old end end
        Profile.keys[UI.binding]=key; UI.binding=nil; Profile.save(); return
    end
    if key=='escape' then
        if App.state=='playing' then App.state='pause'
        elseif App.state=='pause' then App.state='playing'
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
    if not focused and App.state=='playing' then App.state='pause' end
end

function App.viewport(w,h)
    local scale=math.min(w/Arena.width,h/Arena.height)
    return scale,(w-Arena.width*scale)/2,(h-Arena.height*scale)/2
end
function App.toggleFullscreen()
    love.window.setFullscreen(not love.window.getFullscreen(),'desktop')
end
function love.wheelmoved(_,y)
    if App.state=='story' and Story.text~='' then
        UI.storyOffset=math.max(0,math.min(UI.storyLimit or math.huge,(UI.storyOffset or 0)-y*35))
    end
end
function love.quit() Online.quit() end

function love.resize(w,h)
    -- Reflow a running arena when its window shape changes; retain progress and boss health.
    if not player or not Campaign.data or not gameCanvas then return end
    local oldW=Arena.width; Arena.configure(w,h)
    if oldW==Arena.width then return end
    local ratio=Arena.width/oldW
    player.x=player.x*ratio
    local level=levels[player.level]
    level.player_position.x=level.player_position.x*ratio
    for _,p in ipairs(level.larme_position) do p.x=p.x*ratio end
    objet.larme.x=objet.larme.x*ratio
    for _,m in ipairs(mobs) do m.x=m.x*ratio end
    Arena.build(level.player_position,level.larme_position,Raven.active or Wasp.active)
    player.x,player.y=Arena.clearSpot(player.x,player.y,30,24)
    if Raven.active then
        Raven.x=Arena.width/2
        for _,list in ipairs({Raven.spots,Raven.feathers,Raven.projectiles,Raven.nests}) do for _,p in ipairs(list) do p.x=p.x*ratio end end
    end
    for _,p in ipairs(Hazards.lava) do p.x=p.x*ratio end
    if Wasp.active then
        Wasp.x=Wasp.x*ratio
        for _,list in ipairs({Wasp.projectiles,Wasp.minions}) do for _,p in ipairs(list) do p.x=p.x*ratio end end
    end
    if Campaign.world>=4 then
        local rain,clock=Realms.rain,Realms.clock
        for _,p in ipairs(rain) do p.x=p.x*ratio end
        Realms.reset(Campaign.world,player.level); Realms.rain=rain; Realms.clock=clock
    end
    gameCanvas=love.graphics.newCanvas(Arena.width,Arena.height)
end

if os.getenv('SILKEN_TEST')=='1' then
    function love.errorhandler(message)
        io.stderr:write(tostring(message)..'\n'..debug.traceback()..'\n'); io.stderr:flush(); os.exit(1)
    end
end
