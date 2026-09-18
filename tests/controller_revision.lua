local T={}
function T.run()
    local function near(a,b) assert(math.abs(a-b)<1e-8,tostring(a)..' != '..tostring(b)) end
    print('PHYSICAL_GAMEPADS='..#love.joystick.getJoysticks())
    local j={axes={},buttons={},connected=true}
    function j:isConnected() return self.connected end
    function j:isGamepad() return true end
    function j:getName() return 'Test gamepad' end
    function j:getGamepadAxis(a) return self.axes[a] or 0 end
    function j:isGamepadDown(...) for _,b in ipairs({...}) do if self.buttons[b] then return true end end;return false end
    Input.pad=nil;Input.add(j);assert(Input.pad==j)
    j.axes.leftx=.1;near(Input.axes(),0)
    j.axes.leftx=1;local x,y=Input.move();near(x,1);near(y,0)
    j.axes.lefty=1;x,y=Input.move();near(math.sqrt(x*x+y*y),1)
    j.axes={};j.buttons.dpleft=true;x,y=Input.move();near(x,-1)
    j.buttons={a=true};assert(Input.slow());j.buttons={};j.axes.triggerright=.7;assert(Input.slow());j.axes={}
    App.state='menu';Input.state=nil;Input.update(0);love.draw();Input.active=true
    local called=false;UI.buttons={{x=0,y=0,w=20,h=20,run=function() end},{x=100,y=0,w=20,h=20,run=function() called=true end},{x=40,y=0,w=20,h=20,disabled=true}}
    Input.index=1;Input.navigate(1,0);assert(Input.index==2);Input.press(j,'a');assert(called)
    App.state='playing';Input.press(j,'start');assert(App.state=='pause');Input.press(j,'start');assert(App.state=='playing')
    Input.remove(j);assert(App.state=='pause','Déconnexion met en pause')
    Input.pad=j;Input.active=true;App.openEntry(1);App.draftName='';love.draw();Input.index=1;Input.press(j,'a');assert(App.draftName=='A');Input.press(j,'x');assert(App.draftName=='')
    Profile.name='QA';Secret.open();assert(App.state=='bossWorld' and App.selectedWorld==8 and Worlds.canEnter(8))
    local oy=Secret.y;j.axes.lefty=1;Secret.update(.02);assert(Secret.y>oy,'Mouvement vertical dans le monde hardcore');j.axes={}
    for i,p in ipairs(Secret.portals) do Secret.open();Secret.cooldown=0;Secret.x,Secret.y=Secret.position(i);Secret.update(0);assert(Campaign.world==p.world and App.state=='playing') end
    local flags={};Achievements.check({world=1,time=552.731,deaths=95},flags);assert(not flags.maxance)
    Achievements.check({world=1,time=552.732,deaths=95},flags);assert(flags.maxance)
    flags={};Achievements.check({world=1,time=600,deaths=94},flags);assert(not flags.maxance)
    local oldArc=love.graphics.arc;local calls=0;love.graphics.arc=function(...) calls=calls+1;return oldArc(...) end
    player.abyssHeld=nil;player.tunnelTravel=nil;player.falling=nil
    Campaign.biome=1;draw_player_beacon();assert(calls==0)
    Campaign.biome=7;local lit,charges=player.illuminated,player.charges;draw_player_beacon();assert(calls==1 and player.illuminated==lit and player.charges==charges)
    love.graphics.arc=oldArc
    local frames=0;love.focus=function() end
    love.update=function()
        frames=frames+1
        if frames==1 then Secret.open();Input.active=false;App.capture='sanctuary-world.png'
        elseif frames==5 then App.state='worlds';App.capture='sanctuary-selection.png'
        elseif frames==9 then App.openEntry(1);Input.active=true;App.capture='controller-keyboard.png'
        elseif frames==13 then print('PASS controller/hub: mappings, analog deadzone, menus, text input, disconnect pause, six encounters, Maxance thresholds, cosmetic-only helmet');love.event.quit() end
    end
end
return T
