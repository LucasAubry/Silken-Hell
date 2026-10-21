function load_player()
	player = {}
	player.level = 1
	player.death = 0
	player.x = 0--init dans levle
	player.y = 0--idem
	player.size = 0.14
	player.speed = 1
	player.has_moved = true
	player.last_mouve = "player.y+"
	player.img_up = require("art_filter").image("assets/skins/base_marron/up.png")
	player.img_down = require("art_filter").image("assets/skins/base_marron/down.png")
	player.img_left = require("art_filter").image("assets/skins/base_marron/profil.png")
	player.img_right = require("art_filter").image("assets/skins/base_marron/profil.png")
	player.hitBox_width = 60
	player.hitBox_height = 30
	player.hitBox_offset_x = 5
	player.hitBox_offset_y = 10
	player.reset = false

end


-- Presentation-only pose: flutter the existing leg rig without changing gameplay state.
local flightPose={walkMoving=true,sanctuaryPlayer=true}
local function drawPlayer(direction)
    if require('sky_weather').playerHidden() then return end
    if Abyss and (Abyss.playerHidden() or Abyss.playerVisibility()==0) then return end
    if player.abyssHeld then
        local s=player.abyssHeld.swallowed; local scale=math.max(0,1-(s and s.time or 0)/.25)
        love.graphics.setColor(.5,.9,1,scale); Characters.draw(player.x+15,player.y+8,Characters.playerWidth*scale,direction)
        love.graphics.setColor(1,1,1); return
    end
    if player.tunnelTravel then
        local scale,dy=Realms.travelPose(player); love.graphics.setColor(1,1,1,scale)
        Characters.draw(player.x+15,player.y+8+dy,Characters.playerWidth*scale,direction)
        love.graphics.setColor(1,1,1); return
    end
    if player.whirl or player.skyWhirl then
        local w=player.whirl
        local age=w and math.max(0,.65-w.time) or 0
        local u=math.min(1,age/.24);local ease=u*u*(3-2*u)
        local rotation=w and (w.entryRotation or 0)+7*age+11*(age<.24 and .24*(u*u*u-.5*u*u*u*u) or age-.12) or Realms.clock*18
        local lift=w and (w.entryLift or 0)*(1-ease) or 0
        local g=love.graphics;g.push('all');g.translate(player.x+15,player.y+12-lift);g.rotate(rotation)
        flightPose.walkPhase=(w and w.entryLegPhase or 0)+age*22
        g.setColor(1,1,1);Characters.draw(0,0,Characters.playerWidth,direction,flightPose);g.pop();return
    end
    if player.falling then
        local scale=math.max(.05,(player.fallTimer or .32)/.32)
        love.graphics.setColor(.45,.55,.7,scale)
        Characters.draw(player.x+15,player.y+8+(1-scale)*20,Characters.playerWidth*scale,direction)
        love.graphics.setColor(1,1,1); return
    end
    if player.throw and not player.reset then
        local flight=player.throw
        local age=1.5-flight.time
        local angle=math.atan2(flight.vy,flight.vx)
        local g=love.graphics
        g.push('all')
        g.translate(player.x+15,player.y+8)
        g.rotate(angle)
        -- Analytic streamlines: no particle allocation or gameplay RNG in rendering.
        g.setLineWidth(1.6)
        for i=1,14 do
            local phase=(age*2.4+i*.618)%1
            local side=(i%2==0 and 1 or -1)*(10+i%5*5)
            local x=18-phase*115
            g.setColor(.75,.91,1,math.sin(phase*math.pi)*.5)
            g.line(x,side,x-12-i%4*5,side*.94)
        end
        g.rotate(-angle)
        -- A lifted body and a light flutter keep the flight readable over gaps.
        local lift=9+math.sin(age*12)*2.5
        g.translate(0,-lift)
        g.rotate(age*7+math.sin(age*15)*.13+math.cos(angle)*.14)
        g.scale(1+math.sin(age*18)*.025,1-math.sin(age*18)*.025)
        g.setColor(1,1,1)
        flightPose.walkPhase=age*22
        Characters.draw(0,0,Characters.playerWidth,direction,flightPose)
        g.pop()
        return
    end
    Characters.shadow(player.x+15,player.y+8,Characters.playerWidth,direction,player)
    if (player.venom or 0)>0 then
        love.graphics.setColor(.24,1,.14,.2+.1*math.sin(larme_float_timer*10))
        love.graphics.ellipse('fill',player.x+15,player.y+14,34,22)
        love.graphics.setColor(.42,1,.32)
    else love.graphics.setColor(1,1,1) end
    local g=love.graphics
    local r,green,b,alpha=g.getColor()
    local visibility=Abyss.playerVisibility()*require('sky_weather').playerVisibility()
    g.setColor(r*visibility,green*visibility,b*visibility,alpha)
    Characters.draw(player.x+15,player.y+8,Characters.playerWidth,direction,player,Campaign.biome)
    love.graphics.setColor(1,1,1)
end

function draw_player(direction)
    require('render_motion').draw(player,drawPlayer,direction)
end

local function drawBeacon()
    if require('sky_weather').playerHidden() then return end
    if Abyss and Abyss.playerHidden() then return end
    if Campaign.biome==7 or Abyss.encounterActive() then
        local x,y,r=Ocean.bubblePosition()
        if x then Ocean.drawLantern(x,y,r,Ocean.clock,nil,nil,direction) end
        return
    end
    if Campaign.biome==4 or Campaign.biome==7 then Ocean.drawBubble() end
end
function draw_player_beacon()
    require('render_motion').draw(player,drawBeacon)
end
return player
