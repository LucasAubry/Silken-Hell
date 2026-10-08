-- Portable Workshop content, independent of the current HTTP host or Steam UGC.
-- manifest.json is our format; the future native publisher maps it to Steam APIs.
local C={version=1}
local json=require('json')
function C.export(layout,title,author)
 local valid,why=LayoutSchema.validate(layout);if not valid then return nil,why end
 title=(title or ''):match('^%s*(.-)%s*$');author=(author or ''):match('^%s*(.-)%s*$')
 if title=='' or author=='' then return nil,'Renseigne le titre et ton pseudo.' end
 local hash=Replay.hash(layout)
 local folder='steam-workshop/'..hash
 local manifest={format='silken-hell-map',version=C.version,title=title,author=author,content='content/map.json',sha256=hash,
  biome=layout.biome or layout.world,difficulty=layout.difficulty or 1,difficultyExtra=layout.difficultyExtra or 0,
  tags={'Map','biome:'..(layout.biome or layout.world),'difficulty:'..(layout.difficulty or 1)}}
 if not love.filesystem.createDirectory(folder..'/content') then return nil,'Export impossible.' end
 for _,file in ipairs({{'content/map.json',layout},{'manifest.json',manifest}}) do
  if not love.filesystem.write(folder..'/'..file[1],json.encode(file[2])) then return nil,'Export impossible.' end
 end
 return love.filesystem.getSaveDirectory()..'/'..folder
end
return C
