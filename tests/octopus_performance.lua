local T={}
function T.run()
    Online.enabled=false;LevelLayouts.disabled=true
    Campaign.select(4);player.level=10;reset_level();App.state='playing'
    player.x=60;player.y=500;Octopus.enraged=true
    local start=love.timer.getTime()
    for i=1,4 do Octopus.releaseCrabs() end
    print(string.format('PERF spawn 64 crabs: %.3f ms',(love.timer.getTime()-start)*1000))
    start=love.timer.getTime()
    for frame=1,120 do for i=1,64 do
        local a=i*.71+frame*.01
        for _,radius in ipairs({190,205,240,300,350}) do Octopus.armAt(Octopus.x+math.cos(a)*radius,Octopus.y+math.sin(a)*radius) end
    end end
    print(string.format('PERF 320 arm collision probes/frame: %.3f ms',(love.timer.getTime()-start)*1000/120))
    local canvas=love.graphics.newCanvas(960,600);love.graphics.setCanvas(canvas)
    Octopus.draw();love.graphics.flushBatch()
    start=love.timer.getTime()
    for frame=1,60 do love.graphics.clear();Octopus.angle=frame*.01;Octopus.draw();love.graphics.flushBatch() end
    print(string.format('PERF octopus + 64 crabs draw CPU submission: %.3f ms/frame',(love.timer.getTime()-start)*1000/60))
    love.graphics.setCanvas();io.stdout:flush();love.event.quit(0)
end
return T
