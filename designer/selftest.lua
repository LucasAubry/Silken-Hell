local T={}
function T.run(M,state,select,apply,preview)
    local count=0
    for key,l in pairs(M.defaults.levels) do
        count=count+1; local ok,msg=M.validate(l); assert(ok,key..': '..tostring(msg))
    end
    assert(count==66,'Les soixante-six niveaux doivent être importés')
    for n=1,10 do
        local found=false; for _,e in ipairs(M.defaults.levels['2:'..n].entities) do if e.kind=='magma_spawner' then found=true end end
        assert(found,'Flaques Enfer importées dans l’éditeur')
    end
    for n,kind in ipairs({'merle','storm','hedgehog','octopus','skeleton_fish','wasp'}) do
        local found=false
        for _,e in ipairs(M.defaults.levels['3:'..n].entities) do if e.kind=='boss' and e.type==kind then found=true end end
        assert(found,'Boss Renaissance importé : '..kind)
    end
    for n=8,10 do
        local found=false; for _,e in ipairs(M.defaults.levels['7:'..n].entities) do if e.type=='skeleton_fish' then assert(e.skeletonStage==n); found=true end end
        assert(found,'Squelette progressif importé')
    end
    select(7,10)
    local head,parts=false,0
    for _,e in ipairs(M.layout.entities) do
        assert(e.type~='skeleton_fish','Ancien squelette séparé')
        if e.type=='skeleton_head' then head=true elseif e.kind=='abyss_part' then parts=parts+1 end
    end
    assert(head and parts>1,'Tête boss et terrain séparés dans le modèle')
    local part=M.add({kind='abyss_part',type='skeleton_rib',w=24,h=120,rotation=90},400,320)
    assert(M.validate(M.layout));M.undo(false);M.undo(true)
    assert(M.layout.entities[#M.layout.entities].rotation==90,'Rotation conservée par annuler/rétablir')
    select(4,1); M.add({kind='magma_spawner',rx=31,ry=23,spawnDelay=.5,spawnInterval=2},180,220); M.add({kind='mob',type='magma_larva',speed=245},280,220); assert(M.validate(M.layout)); M.undo(false); M.undo(false)
    select(2,10)
    local found=false; for _,e in ipairs(M.layout.entities) do if e.kind=='boss' then assert(e.type=='wasp'); found=true end end
    assert(found,'Abeille importée comme boss de l’Enfer')
    local oldDraft=M.drafts['2:10']; local legacy=M.clone(M.layout)
    for _,e in ipairs(legacy.entities) do if e.kind=='boss' then e.type='hellserpent' end end
    M.drafts['2:10']=legacy; select(2,10)
    for _,e in ipairs(M.layout.entities) do if e.kind=='boss' then assert(e.type=='wasp','Ancien brouillon converti') end end
    M.drafts['2:10']=oldDraft
    select(1,10); M.add({kind='nest',rx=34,ry=25},200,300); assert(M.validate(M.layout)); M.undo(false)
    select(5,1)
    local mole=M.add({kind='mob',type='mole',speed=111,startUnderground=true},320,260)
    assert(M.validate(M.layout));M.undo(false);M.undo(true)
    assert(M.layout.entities[#M.layout.entities].startUnderground,'Underground option persists through history')
    M.selected=M.layout.entities[#M.layout.entities]
    state.input='templateName';state.inputText='Taupe de quartz';love.keypressed('return')
    assert(M.selected.customName=='Taupe de quartz' and state.templates[#state.templates].speed==111,'Named creature keeps its tuning')
    assert(require('json').decode(love.filesystem.read('creature-templates.json'))[#state.templates].startUnderground,'Creation library persists')
    select(4,4); local before=#M.layout.entities
    M.add({kind='mob',type='crab',speed=123},100,300)
    assert(#M.layout.entities==before+1)
    M.undo(false); assert(#M.layout.entities==before)
    M.undo(true); assert(#M.layout.entities==before+1)
    local oldProject,oldSave=M.project,M.save
    M.project=love.filesystem.getSaveDirectory(); M.save=M.project
    local ok,msg=M.apply(); assert(ok,msg)
    local data=assert(love.filesystem.read('custom_levels.json'))
    local saved=require('json').decode(data); assert(#saved.levels['4:4'].entities==before+1)
    assert(saved.levels['4:4'].entities[#saved.levels['4:4'].entities].speed==123)
    local invalid=M.clone(M.layout); invalid.entities[#invalid.entities+1]={kind='vent',x=invalid.entities[2].x,y=invalid.entities[2].y,rx=35,ry=25}
    assert(M.validate(invalid),'Création libre : les chevauchements sont autorisés')
    invalid.entities[#invalid.entities+1]={kind='boss',type='wasp',x=300,y=300}
    invalid.entities[#invalid.entities+1]={kind='boss',type='wasp',x=600,y=300}
    assert(M.validate(invalid),'Boss multiples et créatures étrangères autorisés')
    local execute=os.execute; local launches=0
    os.execute=function() launches=launches+1; return 0 end
    love.filesystem.write('preview-heartbeat.txt',tostring(os.time()))
    preview(); assert(launches==0,'La fenêtre chaude est réutilisée')
    local request=require('json').decode(assert(love.filesystem.read('preview-request.json')))
    assert(request.layout.world==4 and request.layout.level==4,'Carte transmise au test')
    love.filesystem.remove('preview-heartbeat.txt'); state.launching=nil
    preview(); preview(); assert(launches==1,'Pas de double lancement pendant le chargement')
    os.execute=execute
    M.project=oldProject; M.save=oldSave; M.selected=M.layout.entities[#M.layout.entities]
    state.status='TESTS VALIDÉS · Import 66 niveaux, édition, annulation, application et création libre.'
    local tick=0
    state.testUpdate=function()
        tick=tick+1
        if tick==2 then love.graphics.captureScreenshot('designer-ocean.png')
        elseif tick==5 then select(7,10); state.category='Terrain'; state.scroll=3;state.all=false
            for _,e in ipairs(M.layout.entities) do if e.kind=='abyss_part' and e.type=='skeleton_rib' then M.selected=e;break end end
        elseif tick==7 then love.graphics.captureScreenshot('designer-abyss.png')
        elseif tick==10 then select(2,10); for _,e in ipairs(M.layout.entities) do if e.kind=='boss' then M.selected=e; break end end
        elseif tick==12 then love.graphics.captureScreenshot('designer-boss-rates.png')
        elseif tick==15 then select(2,1); for _,e in ipairs(M.layout.entities) do if e.kind=='magma_spawner' then M.selected=e; break end end
        elseif tick==17 then love.graphics.captureScreenshot('designer-spawner-rates.png')
        elseif tick==20 then print('PASS designer: 66 imports, placement, undo/redo, sauvegarde atomique, validation libre'); love.event.quit() end
    end
end
return T
