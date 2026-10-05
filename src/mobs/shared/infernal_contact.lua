local function die()
    if not player.reset then player.reset=true; player.death=player.death+1; Profile.record('deaths'); activateShaderEffect() end
end
return die
