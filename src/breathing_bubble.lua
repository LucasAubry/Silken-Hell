local O={bubbles={}}
function O.reset(world)
    O.active=world==4 or world==7
    O.bubbles={}; O.clock=0; player.oxygen=nil
end
function O.update(dt)
    if O.active then O.clock=O.clock+dt end
end
function O.relayout()
    O.active=Campaign.biome==4 or Campaign.biome==7
    O.bubbles={}; player.oxygen=nil
end
function O.drawGround() end
-- Anchors follow the visible head, independently of the abdomen/accessories.
local heads={down={0,.08,.19},up={0,-.19,.195},left={-.25,.065,.185}}
local skinHeads={
 [3]={down={0,.08,.19},up={0,-.19,.195},left={-.25,.065,.185}},
 [6]={down={0,.22,.18},up={0,-.331,.188},left={-.23,.25,.175}},
 [8]={down={0,.08,.19},up={0,-.19,.195},left={-.25,.065,.185}},
 [11]={down={0,.08,.19},up={0,-.19,.195},left={-.25,.065,.185}},
}
function O.headPosition(x,y,width,dir,index)
    index=index or Characters.selected();index=Characters.crowned[index] or index
    local pose=dir=='right' and 'left' or dir
    local anchor=(skinHeads[index] or heads)[pose] or heads.down
    local mirror=dir=='right' and -1 or 1
    return x+anchor[1]*width*mirror,y+anchor[2]*width,anchor[3]*width
end
function O.bubblePosition()
    if not O.active or player.abyssHeld or player.falling or player.tunnelTravel or (Abyss and Abyss.playerHidden()) then return end
    return O.headPosition(player.x+15,player.y+8,Characters.playerWidth,direction)
end
function O.lanternPosition(x,y,r,clock,dir)

    local bob=math.sin((clock or 0)*2.5)*r*.02
    return x,y-r*1.20+bob
end
function O.lightPosition()
    if not Campaign or Campaign.biome~=7 then return end
    local x,y,r=O.bubblePosition()
    if not x then return end
    local lx,ly=O.lanternPosition(x,y,r,O.clock,direction)
    local dx,dy=require('render_motion').offset(player)
    return lx+dx,ly+dy
end
-- One anglerfish-lure design in every pose, mirrored only for the left view.
function O.drawLantern(x,y,r,clock,locked,alpha,dir)
    local g=love.graphics;alpha=alpha or 1
    local lx,ly=O.lanternPosition(x,y,r,clock,dir)
    local scale=r/12
    g.push('all');g.setShader();g.setBlendMode('alpha')
    if not locked and (not Graphics or Graphics.effects) then
        g.setBlendMode('add')
        for i=5,1,-1 do
            g.setColor(1,.77,.25,.035*alpha);g.circle('fill',lx,ly,(3+i*1.8)*scale)
        end
        g.setBlendMode('alpha')
    end
    -- Stepped pixel clusters match the spider's blue/lavender shell and gold.
    -- The luminous tip stays on the head's centerline in all three poses.
    g.translate(lx,ly);g.scale(scale)
    local stem={-1,7,-3,5,-5,2,-5,-2,-3,-5,0,-6,3,-5,4,-3,4,0,2,0,2,-3,0,-4,-2,-3,-3,-1,-3,2,-1,4,1,5,1,7}
    g.setColor(locked and 0 or .12,locked and 0 or .14,locked and 0 or .24,alpha)
    g.polygon('fill',stem)
    if not locked then
        g.setColor(.46,.51,.76,alpha)
        g.rectangle('fill',-3,0,1,3);g.rectangle('fill',-2,3,1,2)
        g.rectangle('fill',-3,-2,1,2);g.rectangle('fill',-2,-4,3,1)
        g.setColor(.72,.76,.94,alpha);g.rectangle('fill',-1,-5,2,1)
    end
    g.setColor(locked and 0 or .22,locked and 0 or .16,locked and 0 or .07,alpha)
    g.polygon('fill',-2,-4,2,-4,4,-2,4,2,2,4,-2,4,-4,2,-4,-2)
    if not locked then
        g.setColor(1,.72,.18,alpha);g.rectangle('fill',-2,-3,4,6);g.rectangle('fill',-3,-2,6,4)
        g.setColor(1,.94,.55,alpha);g.rectangle('fill',-2,-2,4,4)
        g.setColor(1,1,.94,alpha);g.rectangle('fill',-2,-2,3,3)
    end
    g.pop()
end
-- Shared overlay for the player's head, its skin and the marine world-map marker.
function O.drawAt(x,y,r,clock,lantern,outline,locked,alpha,dir)
    if lantern then O.drawLantern(x,y,r,clock,locked,alpha,dir) end
    r=r+math.sin((clock or 0)*2.5)*.5
    local g=love.graphics;alpha=alpha or 1
    g.push('all');g.setShader();g.setBlendMode('alpha')
    if locked then g.setColor(0,0,0,alpha);g.circle('fill',x,y,r);g.pop();return end
    if outline then
        g.setBlendMode('add');g.setLineWidth(1.2)
        g.setColor(.35,.7,.85,.28);g.circle('line',x,y,r)
        g.setColor(.65,.9,1,.35);g.arc('line','open',x,y,r,3.5,4.8)
        g.pop();return
    end
    local scale=r/15
    g.setColor(.3,.8,1,.12*alpha); g.circle('fill',x,y,r)
    g.setLineWidth(1.3*scale); g.setColor(.6,.94,1,.75*alpha); g.circle('line',x,y,r)
    g.setColor(1,1,1,.9*alpha); g.arc('line','open',x,y,r-3*scale,3.5,4.8)
    g.setColor(.8,.95,1,.45*alpha); g.arc('line','open',x,y,r-2*scale,.3,1.2)
    g.pop()
end
function O.drawBubble(outline)
    local x,y,r=O.bubblePosition()
    if not x then return end
    if require('integrated_skins').bubble(Characters.selected()) then
        if Campaign.biome==7 then O.drawLantern(x,y,r,O.clock,nil,nil,direction) end
        return
    end
    O.drawAt(x,y,r,O.clock,Campaign.biome==7,outline,nil,nil,direction)
end
return O
