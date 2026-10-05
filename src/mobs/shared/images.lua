-- Shared immutable textures: spawning/restarting must not decode PNGs or upload them again.
local mobImages={}
local function mobImage(path)
    path=require("asset_paths").resolve(path)
    if not mobImages[path] then mobImages[path]=require('art_filter').image(path) end
    return mobImages[path]
end

return mobImage
