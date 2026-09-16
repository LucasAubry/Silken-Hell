local T={}
function T.run()
    for _,n in ipairs({'spider','imp','serpent','merle','wasp','wasp_ground'}) do
        for _,d in ipairs({'down','up','left','right'}) do
            local data=love.image.newImageData('assets/sprites/directional/'..n..'_'..d..'.png')
            local _,_,_,a=data:getPixel(0,0)
            if a>0 then print('OPAQUE '..n..'_'..d) end
            data:release()
        end
    end
    print('ASSET SCAN DONE'); io.stdout:flush()
    local frames=0
    love.update=function() frames=frames+1; if frames>4 then love.event.quit() end end
    love.draw=function()
        love.graphics.clear(.16,.19,.23)
        for row,n in ipairs({'spider','imp','serpent','merle','wasp','wasp_ground'}) do
            love.graphics.setColor(1,1,1); love.graphics.print(n,20,30+(row-1)*115)
            for col,d in ipairs({'down','up','left','right'}) do
                local x,y=220+(col-1)*260,65+(row-1)*115
                love.graphics.setColor(1,1,1); Art.drawFacing(n,d,x,y,105)
                if row==1 then love.graphics.print(d,x-15,0) end
            end
        end
        if frames==2 then love.graphics.captureScreenshot('directions-v5-qa.png') end
    end
end
return T
