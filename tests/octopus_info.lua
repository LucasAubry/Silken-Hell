local T={}
function T.run()
    Online.start=function() end;LevelLayouts.disabled=true;Secret.duel=nil;App.sessionLayout=nil;App.singleLevel=false;Profile.name='QA';Profile.unlocked=7
    local function level(w) Campaign.select(w);player.level=10;reset_level();App.state='playing' end
    for w,id in pairs({[1]='merle',[2]='wasp',[4]='octopus',[5]='hedgehog',[6]='storm',[7]='skeleton_fish'}) do
        level(w);Bestiary.openBoss();assert(Bestiary.entries[UI.bestSelected].id==id and UI.bestCategory=='boss','Le bouton i cible '..id)
        love.draw();assert(UI.bestScrollMax>=0)
    end
    level(4);Bestiary.openBoss();love.draw();assert(UI.bestScrollMax>0)
    UI.scrollBestiary(99999);assert(UI.bestScroll==UI.bestScrollMax);UI.scrollBestiary(-99999);assert(UI.bestScroll==0)
    assert(Bestiary.description(Bestiary.entries[UI.bestSelected],true):find('pas encore disponible',1,true))
    Secret.open();Secret.hardcore=true;Secret.refresh();Secret.launch(Secret.portals[1]);Bestiary.openBoss();assert(UI.bestHardcore and Bestiary.entries[UI.bestSelected].id=='wasp')
    local tick=0;love.focus=function() end
    love.update=function()
        tick=tick+1
        if tick==1 then App.capture='bestiary-hardcore.png'
        elseif tick==5 then App.sessionLayout=nil;App.singleLevel=false;Secret.duel=nil;level(4);Bestiary.openBoss();App.capture='bestiary-octopus.png'
        elseif tick==9 then UI.scrollBestiary(9999);App.capture='bestiary-octopus-bottom.png'
        elseif tick==13 then print('PASS boss info: correct boss entry, clipped scrolling, normal/hardcore views');love.event.quit() end
    end
end
return T
