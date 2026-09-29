local Test={}
function Test.run()
    local L=require 'localization'
    local json=require 'json'
    local catalog=json.decode(love.filesystem.read('assets/locales/game.json'))
    local initialStory=Story.text
    local oldText=UI.rawText
    local drawn={}
    UI.rawText=function(value,...) drawn[#drawn+1]=value;return oldText(value,...) end
    -- A nickname or a community map named after a world is still user content.
    Profile.name='Terre';App.draftName='Enfer'
    Online.scores=function() return {},'offline' end
    Online.board=function() return {scores={},total=0,hasMore=false},'offline' end
    Profile.completed={};Profile.levels={}
    for _,id in ipairs(Worlds.order) do Profile.completed[id]=true;Profile.levels[id]=10 end
    for _,entry in ipairs(Bestiary.entries) do Bestiary.seen[entry.id]=true end
    local canvas=love.graphics.newCanvas(1200,750)
    local captures=os.getenv('SILKEN_LANGUAGE_CAPTURES')
    local function render(state,name)
        App.state=state;drawn={}
        love.graphics.setCanvas(canvas);love.graphics.clear(.01,.025,.035,1)
        UI.draw()
        love.graphics.setCanvas()
        if captures and name then
            local bytes=canvas:newImageData():encode('png'):getString()
            local f=assert(io.open(captures..'/'..name..'.png','wb'));f:write(bytes);f:close()
        end
    end
    for _,option in ipairs(L.options) do
        local code=option.code;Profile.language=code
        for source,row in pairs(catalog) do
            assert(L.has(source,code),'Missing translation: '..code..' / '..source)
            local translated=L.text(source)
            assert(code=='fr' or translated==row[code],source)
            assert(UI.fonts.body:hasGlyphs((translated:gsub('[\r\n]',''))),'Missing glyph: '..code..' / '..source)
        end
        for _,entry in ipairs(Bestiary.entries) do
            assert(L.has(entry.name,code),'Missing name: '..entry.name)
            assert(L.has(entry.text,code),'Missing description: '..entry.id)
            UI.bestSelected=nil
            for i,e in ipairs(Bestiary.entries) do if e==entry then UI.bestSelected=i end end
            UI.bestCategory=Bestiary.category(entry);UI.bestPage=1;UI.bestScroll=0;UI.bestHardcore=false
            render('bestiary',entry.id=='octopus' and code..'-bestiary' or nil)
            if entry.id=='octopus' then assert(UI.bestScrollMax>0,'Long translated descriptions must scroll') end
        end
        UI.settingsPage='language';render('settings',code..'-languages')
        UI.settingsPage='shortcuts';render('settings')
        UI.settingsPage='general';render('settings')
        render('graphics');render('menu',code..'-menu');render('worlds');render('pause');render('achievements')
        Input.active=false;render('entry')
        local nickname=false
        for _,value in ipairs(drawn) do if value==L.text('Pseudo : ')..'Enfer|' then nickname=true end end
        assert(nickname,'Nickname must not be translated')
        Workshop.publishing=false;Workshop.rows={{id='test',title='Terre',author='Enfer',biome=1,difficulty=1,stars=0}};Workshop.status='Chargement des cartes…'
        render('workshop')
        local title,author=false,false
        for _,value in ipairs(drawn) do if value=='Terre' then title=true end;if value=='Enfer · '..L.text('Paradis') then author=true end end
        assert(title and author,'Community content must remain unchanged')
        -- Exercise the scrolling story with authored text and change languages
        -- without recreating the screen. The shipped story is currently empty.
        Story.text=Bestiary.entries[1].text;UI.storyOffset=100
        render('story',code..'-story')
        assert(UI.storySource==L.text(Story.text),'Story cache used a previous language')
        Story.worlds[1]=Story.text;assert(Story.localizedWorld(1)==L.text(Story.text))
        assert(L.render('Paradis  ·  Voir tous')==L.text('Paradis')..L.text('  ·  Voir tous'))
        assert(L.render('Charges : 3')==L.text('Charges : ')..'3')
        assert(L.render('Terrestre')=='Terrestre','Do not replace partial words')
    end
    Story.text=initialStory;Story.worlds[1]=nil;UI.rawText=oldText
    -- French is also immediate when switching back from Japanese.
    Profile.language='fr';assert(L.render('Paradis  ·  Voir tous')=='Paradis  ·  Voir tous')
    print('PASS localization: 7 languages, complete catalog and bestiary, glyphs, menus, long-text scroll, story refresh, user content preserved')
    io.stdout:flush();love.event.quit(0)
end
return Test
