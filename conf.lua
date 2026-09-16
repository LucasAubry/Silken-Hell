function love.conf(t)
    t.identity = 'silken-hell'
    t.version = '11.5'
    t.window.title = 'Silken Hell — Les cinq mondes'
    t.window.width = 1200
    t.window.height = 750
    t.window.resizable = true
    t.window.fullscreen = os.getenv('SILKEN_TEST') ~= '1' and os.getenv('SILKEN_ONLINE_TEST') ~= '1'
    t.window.fullscreentype = 'desktop'
    t.window.minwidth = 900
    t.window.minheight = 600
    t.console = false
end
