local C={status=''}
function C.open(confirmed)
    if not Profile.hasCompleted(1) then
        C.status='Termine le Paradis pour créer une carte.'
        if Workshop then Workshop.status=C.status end
        return false
    end
    local complete=true
    for _,world in ipairs(Worlds.order) do if not Profile.hasCompleted(world) then complete=false end end
    if not complete and confirmed~=true then
        C.returnState=App.state;App.state='creatorConfirm';UI.buttons={};Input.index=1
        return false
    end
    local ok=require('platform').launch('--editor')
    C.status=ok and 'Le concepteur de niveaux s’ouvre.' or 'Impossible d’ouvrir le concepteur.'
    if Workshop then Workshop.status=C.status end
    return ok
end
function C.draw()
    UI.panel(260,230,680,280)
    UI.text('Ouvrir le créateur de cartes ?',290,260,'heading',nil,620,'center')
    UI.text('Le créateur peut révéler des mondes et des créatures que tu n’as pas encore découverts. Souhaites-tu l’ouvrir ?',300,323,'body',nil,600,'center')
    UI.button('Retour',310,435,270,44,function()App.state=C.returnState or 'workshop' end)
    UI.button('Ouvrir',620,435,270,44,function()App.state=C.returnState or 'workshop';C.open(true) end)
end
return C
