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
	player.img_up = require("art_filter").image("assets/skins/soie/up.png")
	player.img_down = require("art_filter").image("assets/skins/soie/down.png")
	player.img_left = require("art_filter").image("assets/skins/soie/profil.png")
	player.img_right = require("art_filter").image("assets/skins/soie/profil.png")
	player.hitBox_width = 60
	player.hitBox_height = 30
	player.hitBox_offset_x = 5
	player.hitBox_offset_y = 10
	player.reset = false

end


-- One reusable soft ellipse anchors the player without blurring its artwork.
local playerShadow
local function draw_player_shadow()
    local g=love.graphics
    if not playerShadow then
        local vertices={}
        local function vertex(angle,radius,alpha)
            vertices[#vertices+1]={math.cos(angle)*radius,math.sin(angle)*radius,0,0,1,1,1,alpha}
        end
        for i=0,39 do
            local a,b=i*math.pi/20,(i+1)*math.pi/20
            vertex(a,0,1);vertex(a,.6,.8);vertex(b,.6,.8)
            vertex(a,.6,.8);vertex(a,1,0);vertex(b,1,0)
            vertex(a,.6,.8);vertex(b,1,0);vertex(b,.6,.8)
        end
        playerShadow=g.newMesh(vertices,'triangles','static')
    end
    local width=Characters.playerWidth
    g.push('all');g.setShader();g.setBlendMode('alpha')
    g.setColor(.018,.025,.03,.64)
    g.draw(playerShadow,player.x+18,player.y+28,0,width*.56,width*.25)
    g.pop()
end

function draw_player(direction)
    if Abyss and Abyss.playerHidden() then return end
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
        local g=love.graphics; g.push(); g.translate(player.x+15,player.y+12); g.rotate(Realms.clock*18)
        g.setColor(1,1,1); Characters.draw(0,0,Characters.playerWidth,direction); g.pop(); return
    end
    if player.falling then
        local scale=math.max(.05,(player.fallTimer or .32)/.32)
        love.graphics.setColor(.45,.55,.7,scale)
        Characters.draw(player.x+15,player.y+8+(1-scale)*20,Characters.playerWidth*scale,direction)
        love.graphics.setColor(1,1,1); return
    end
    draw_player_shadow()
    if (player.venom or 0)>0 then
        love.graphics.setColor(.24,1,.14,.2+.1*math.sin(larme_float_timer*10))
        love.graphics.ellipse('fill',player.x+15,player.y+14,34,22)
        love.graphics.setColor(.42,1,.32)
    else love.graphics.setColor(1,1,1) end
    local g=love.graphics
    local previousShader=g.getShader()
    if (player.charges or 0)>0 and Abyss and Abyss.encounterActive() then
        player.chargeShader=player.chargeShader or g.newShader([[vec4 effect(vec4 color, Image image, vec2 uv, vec2 px) {
            vec4 tex=Texel(image,uv);
            float light=dot(tex.rgb,vec3(.299,.587,.114));
            return vec4(vec3(.12,.65,1.0)*(.25+light*.95),tex.a)*color;
        }]])
        g.setColor(1,1,1);g.setShader(player.chargeShader)
    end
    Characters.draw(player.x+15,player.y+8,Characters.playerWidth,direction,player)
    g.setShader(previousShader)
    love.graphics.setColor(1,1,1)
end

function draw_player_beacon()
    if Abyss and Abyss.playerHidden() then return end
    if Campaign.biome==7 then Ocean.drawBubble(true) end
end
return player
