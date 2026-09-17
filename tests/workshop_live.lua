local T={}
function T.run()
    local done=false; local elapsed=0; App.state='workshop'
    Online.request('/v1/workshop?page=1',nil,function(data,code)
        assert(code==200 and type(data.maps)=='table','Workshop HTTPS inaccessible')
        Workshop.rows=data.maps; Workshop.status='Workshop en ligne'; done=true
    end)
    love.update=function(dt)
        elapsed=elapsed+dt; UI.clock=UI.clock+dt; Online.update(dt)
        assert(elapsed<30,'Délai du Workshop dépassé')
        if done then
            App.capture='workshop-live.png'
            print('PASS live Workshop: HTTPS, public listing and authenticated client')
            love.event.quit()
        end
    end
end
return T
