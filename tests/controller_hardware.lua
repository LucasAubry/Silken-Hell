local T={}
function T.run()
    io.stdout:setvbuf('no');love.focus=function() end
    Online.enabled=false;Replay.playing=false;Replay.input=nil
    local B=require('controller_usb')
    assert(B.ready,'USB backend unavailable: '..tostring(B.failed))
    local frames=0
    love.update=function(dt)
        frames=frames+1
        App.state='settings';UI.settingsPage='shortcuts';UI.bindingTab='pad';UI.bindingPage=1
        Input.update(dt)
        if frames==10 then
            Input.scan()
            assert(Input.pad,'Physical controller not delivered to LÖVE')
            local j=Input.pad
            assert(j:isConnected() and j:isGamepad(),'Physical controller must be usable')
            local vendor,product=j:getDeviceInfo()
            assert(vendor==0x0f0d and product==0x00dc,'This hardware check expects the connected HORIPAD S')
            print('PHYSICAL_PAD='..j:getName())
            print('USB_ID='..string.format('%04x:%04x',vendor,product))
            print('GAMEPAD='..tostring(j:isGamepad()))
            local _,instance=j:getID();assert(B.instances[instance],'Physical HID is forwarded through the new backend')
            assert(j:getGamepadAxis('triggerleft')<.05 and j:getGamepadAxis('triggerright')<.05,'Triggers must rest at zero')
            App.capture='horipad-s-detected.png'
        elseif frames==20 then
            local j=Input.pad
            B.quit()
            assert(not j:isConnected(),'Stopping backend disconnects virtual controller')
            App.state='playing';Input.scanAt=0;Input.update(.02)
            assert(App.state=='pause','Loss of the USB controller pauses gameplay')
        elseif frames==35 then
            Input.scan();assert(Input.pad and Input.pad:isConnected(),'Backend can reacquire physical controller without unplugging')
            print('PASS real HORIPAD S detected in LÖVE, mapped controls, neutral triggers, release/reacquire, disconnect pause')
            love.event.quit()
        end
    end
end
return T
