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
function O.drawBubble(outline)
    if not O.active or player.abyssHeld or player.falling or player.tunnelTravel then return end
    local offsets={up={0,-9},down={0,10},left={-11,0},right={11,0}}
    local offset=offsets[direction] or offsets.down
    local x,y=player.x+15+offset[1],player.y+8+offset[2]
    local r=15+math.sin(O.clock*2.5)*.5
    local g=love.graphics
    g.push('all')
    if outline then
        g.setBlendMode('add');g.setLineWidth(1.2)
        g.setColor(.35,.7,.85,.28);g.circle('line',x,y,r)
        g.setColor(.65,.9,1,.35);g.arc('line','open',x,y,r,3.5,4.8)
        g.pop();return
    end
    g.setColor(.3,.8,1,.12); g.circle('fill',x,y,r)
    g.setLineWidth(1.3); g.setColor(.6,.94,1,.75); g.circle('line',x,y,r)
    g.setColor(1,1,1,.9); g.arc('line','open',x,y,r-3,3.5,4.8)
    g.setColor(.8,.95,1,.45); g.arc('line','open',x,y,r-2,.3,1.2)
    g.pop()
end
return O
