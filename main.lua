-- Both game and editor ship in the same portable archive.
love.filesystem.setRequirePath('src/?.lua;src/?/init.lua;'..love.filesystem.getRequirePath())
if require('platform').flag('--platform-child') and os.getenv('SILKEN_TEST')=='1' then
    function love.load()
        love.filesystem.setIdentity('silken-hell-tests')
        love.filesystem.write('platform-child.txt','ok')
        love.event.quit()
    end
elseif require('platform').flag('--editor') then
    SILKEN_EMBEDDED_EDITOR=true
    love.filesystem.setRequirePath('designer/?.lua;'..love.filesystem.getRequirePath())
    require('designer.main')
else
    require('game')
end
