local T={}
local function level(w,n) App.start(w); player.level=n; reset_level(); timer=18.7 end
function T.run()
    for _,form in ipairs({'extended','folded'}) do
        local data=Art.imageData('assets/sprites/directional/octopus_'..form..'_up.png')
        local _,_,_,alpha=data:getPixel(0,0)
        assert(alpha==0,'Alpha vue de dos du poulpe'); data:release()
    end
    Profile.unlocked=6; local tick=0
    love.update=function(dt)
        tick=tick+1; UI.clock=UI.clock+dt
        if tick==1 then level(4,10); Octopus.angle=.2; App.capture='marine-octopus-extended.png' end
        if tick==5 then Octopus.phase='rest'; App.capture='marine-octopus-folded.png' end
        if tick==9 then Octopus.phase='attack'; Octopus.splash(); App.capture='marine-ink.png' end
        if tick==13 then level(7,8); App.capture='marine-abyss.png' end
        if tick==17 then level(4,8); App.capture='marine-coral.png' end
        if tick==21 then level(5,8); App.capture='marine-roots.png' end
        if tick==25 then level(6,8); App.capture='marine-clouds.png' end
        if tick==29 then
            local keys={}
            for _,kind in ipairs({'octopus_extended','octopus_folded','lanternfish'}) do for _,dir in ipairs({'down','up','left','right'}) do keys[#keys+1]=kind..'_'..dir end end
            for _,key in ipairs({'coral_snare','root_snare','cloud_snare','abyss_snare','ink_splatter'}) do keys[#keys+1]=key end
            local captured=false
            love.draw=function()
                local g=love.graphics; g.clear(.14,.17,.2); g.origin()
                local scale=math.min(g.getWidth()/1200,g.getHeight()/750); g.scale(scale)
                for i,key in ipairs(keys) do local x=120+((i-1)%5)*240; local y=87+math.floor((i-1)/5)*180
                    g.setColor(.26,.3,.33); g.rectangle('fill',x-106,y-68,212,136)
                    local a=Art.images[key]; local size=124/math.max(a.w,a.h)
                    g.setColor(1,1,1); g.draw(a.image,a.quad,x,y,0,size,size,a.w/2,a.h/2)
                    g.setFont(UI.fonts.small); g.printf(key,x-117,y+73,234,'center')
                end
                if not captured then captured=true; g.captureScreenshot('marine-assets.png') end
            end
        end
        if tick==33 then love.event.quit() end
    end
end
return T
