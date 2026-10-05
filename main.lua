-- LÖVE entry point; game modules live in src/.
love.filesystem.setRequirePath('src/?.lua;src/?/init.lua;'..love.filesystem.getRequirePath())
require('game')
