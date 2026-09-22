-- Shared immutable textures: spawning/restarting must not decode PNGs or upload them again.
local mobImages={}
local function mobImage(path)
    if not mobImages[path] then mobImages[path]=love.graphics.newImage(path) end
    return mobImages[path]
end

return mobImage
