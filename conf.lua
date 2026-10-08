function love.conf(t)
    local editor,preview=false,false
    for _,v in ipairs(arg or {}) do editor=editor or v=='--editor';preview=preview or v=='--preview' end
    t.identity = editor and (os.getenv('SILKEN_DESIGNER_TEST')=='1' and 'silken-hell-designer-tests' or 'silken-hell-designer') or 'silken-hell'
    t.version = '11.5'
    t.window.title = editor and 'Silken Hell — Création de niveaux' or 'Silken Hell'
    t.window.width = 1200
    t.window.height = 750
    t.window.resizable = true
    t.window.vsync = 0
    t.window.fullscreen = not editor and not preview and os.getenv('SILKEN_PREVIEW_WORLD') == nil and os.getenv('SILKEN_TEST') ~= '1' and os.getenv('SILKEN_ONLINE_TEST') ~= '1'
    t.window.fullscreentype = 'desktop'
    t.window.minwidth = 900
    t.window.minheight = 600
    if editor then t.window.width=1440;t.window.height=900;t.window.minwidth=1150;t.window.minheight=760 end
    t.console = false
end
