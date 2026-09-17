function love.conf(t)
    t.identity=os.getenv('SILKEN_DESIGNER_TEST')=='1' and 'silken-hell-designer-tests' or 'silken-hell-designer'
    t.window.title='Silken Hell — Concepteur de niveaux'
    t.window.width=1440; t.window.height=900; t.window.minwidth=1150; t.window.minheight=760
    t.window.resizable=true; t.window.fullscreen=false; t.window.vsync=1
    t.modules.audio=false; t.modules.physics=false
end
