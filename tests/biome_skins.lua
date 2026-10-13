local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false
 Profile.save=function()error('Cosmetic previews must not save progress')end;Bestiary.save=function()end
 local g=love.graphics;local C=Characters;local O=require('breathing_bubble')
 local before=require('json').encode({Profile.completed,Profile.achievements,Profile.skinGrants})
 for _,index in ipairs(C.baseIndices) do assert(index~=3,'Braise is removed from the selector') end
 assert(not C.unlocked(3),'Retired Braise cannot be equipped')
 assert(C.model('left',3)==C.model('left',11),'Legacy Braise replays retain valid artwork')
 local rng=love.math.getRandomState()
 local uploaded=g.newImage;g.newImage=function()error('Accessories must be preloaded')end
 local canvas=g.newCanvas(1200,1320,{dpiscale=1})
 local function save(name)
  local pixels=canvas:newImageData();pixels:encode('png','biome-skins/'..name..'.png');pixels:release()
 end
 love.filesystem.createDirectory('biome-skins')
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.10,.13,.17);g.setColor(1,1,1)
 local rows={13,9,10,6,8,11,4}
 for row,index in ipairs(rows) do
  local y=90+(row-1)*159
  UI.rawText(C.names[index],16,y-12,'body',{1,1,1},160)
  for col,dir in ipairs({'down','up','left','right'}) do
   g.setColor(1,1,1);C.portrait(index,230+(col-1)*230,y,132,dir)
  end
  g.setColor(1,1,1);C.portrait(index,1110,y,92,'down',true)
 end
 g.pop();save('poses')
 -- The ground shadow must fade smoothly, independently of sprite pixels.
 local shadow=g.newCanvas(160,120,{dpiscale=1})
 g.push('all');g.setCanvas(shadow);g.origin();g.clear();C.shadow(80,50,100,'down');g.pop()
 local shade=shadow:newImageData()
 local _,_,_,center=shade:getPixel(80,65)
 local _,_,_,edge=shade:getPixel(114,65)
 local _,_,_,outside=shade:getPixel(125,65)
 assert(center>.35 and edge>0 and edge<center*.4 and outside==0,'Soft oval shadow fades below the spider')
 shade:release();shadow:release()
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.42,.39,.31)
 for row,index in ipairs(rows) do
  local y=90+(row-1)*159
  UI.rawText(C.names[index],16,y-12,'body',{1,1,1},160)
  for col,dir in ipairs({'down','up','left','right'}) do
   local x=230+(col-1)*230
   C.shadow(x,y,132,dir);g.setColor(1,1,1);C.portrait(index,x,y,132,dir)
  end
 end
 g.pop();save('ground-shadows')
 -- Preserve source alpha for Gillou: only its colors change.
 local sample=g.newCanvas(220,220,{dpiscale=1})
 local function portrait(index)
  g.push('all');g.setCanvas(sample);g.origin();g.clear();g.setColor(1,1,1)
  C.portrait(index,110,110,150,'down');g.pop();return sample:newImageData()
 end
 local plain,red=portrait(2),portrait(13);local warm=0
 for y=0,219 do for x=0,219 do
  local _,_,_,a=plain:getPixel(x,y);local r,green,b,alpha=red:getPixel(x,y)
  assert(a==alpha,'Gillou retains exactly the existing silhouette')
  if alpha>.9 and r>green*2 and r>b*2 then warm=warm+1 end
 end end
 assert(warm>100,'Gillou uses the red-orange reference palette');plain:release();red:release();sample:release()
 -- Complete PNGs render without separate bubble, wing, spike or horn objects.
 local drawAt,drawLantern=O.drawAt,O.drawLantern;local bubbles,lanterns=0,0
 O.drawAt=function(...)bubbles=bubbles+1;return drawAt(...)end
 O.drawLantern=function(...)lanterns=lanterns+1;return drawLantern(...)end
 for _,index in ipairs({4,9}) do
  bubbles=0;C.portrait(index,200,200,59,'down');assert(bubbles==0,'Head bubble is already in the PNG')
  for _,world in ipairs({4,7}) do
   bubbles=0;C.portrait(index,200,200,59,'down',false,nil,world);assert(bubbles==0,'No double head bubble')
  end
 end
 for index,name in pairs(require('integrated_skins').names) do
  for _,dir in ipairs({'down','up','left','right'}) do
   local frame=Art.images[C.model(dir,index)]
   local pose=(dir=='left' or dir=='right') and 'profil' or dir
   local dedicated=name=='ambre' or name=='aureole' or name=='braise' or name=='cendre' or ((name=='ecume' or name=='corail') and pose=='up')
   local file=dedicated and name..'_'..pose or name
   assert(require('prism_material').paths[frame.image]=='assets/skins/integrated/'..file..'.png','Complete skin PNG is used in every pose')
  end
 end
 lanterns=0;C.portrait(10,200,200,59,'down');assert(lanterns==1)
 lanterns=0;C.portrait(10,200,200,59,'down',false,nil,7);assert(lanterns==0,'No double Abyss lantern')
 lanterns=0;C.portrait(10,200,200,59,'down',false,nil,4);assert(lanterns==1,'Abyss skin retains its lantern in Ocean')
 lanterns=0;C.portrait(10,200,200,59,'up');assert(lanterns==1,'Back-view Abyss skin uses the same lure design')
 O.drawAt,O.drawLantern=drawAt,drawLantern
 -- Compare head-sized marine overlays against complete sprites in every direction.
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.10,.13,.17)
 for row,index in ipairs(rows) do
  local y=90+(row-1)*159
  UI.rawText(C.names[index],16,y-12,'body',{1,1,1},160)
  for col,dir in ipairs({'down','up','left','right'}) do
   local x=230+(col-1)*230
   g.setColor(1,1,1);C.portrait(index,x,y,132,dir,false,nil,4)
   if not require('integrated_skins').bubble(index) then
    local hx,hy,r=O.headPosition(x,y,132,dir,index)
    O.drawAt(hx,hy,r,0,false,nil,nil,nil,dir)
   end
  end
 end
 g.pop();save('ocean-heads')
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.10,.13,.17)
 for row,index in ipairs(rows) do
  local y=90+(row-1)*159
  UI.rawText(C.names[index],16,y-12,'body',{1,1,1},160)
  for col,dir in ipairs({'down','up','left','right'}) do
   local x=230+(col-1)*230
   g.setColor(1,1,1);C.portrait(index,x,y,92,dir)
   require('skin_effects').halo(x,y,92,dir)
  end
 end
 g.pop();save('red-halo')
 -- Cached menu and leaderboard portraits must retain the accessories at both scales.
 local selected,browsed=Profile.character,C.browsed
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.10,.13,.17)
 for row,index in ipairs(rows) do
  local y=90+(row-1)*159
  UI.rawText(C.names[index],16,y-12,'body',{1,1,1},160)
  C.browsed=index;g.setColor(1,1,1);C.selectionPortrait(270,y,132)
  for col,dir in ipairs({'down','up','left','right'}) do
   g.setColor(1,1,1);C.portrait(index,520+(col-1)*150,y,28,dir)
  end
 end
 g.pop();save('cached');Profile.character=selected;C.browsed=browsed;canvas:release()
 assert(love.math.getRandomState()==rng,'Cosmetics preserve gameplay RNG')
 assert(before==require('json').encode({Profile.completed,Profile.achievements,Profile.skinGrants}),'Cosmetics preserve unlocks')
 g.newImage=uploaded
 print('CAPTURE '..love.filesystem.getSaveDirectory()..'/biome-skins/poses.png')
 print('PASS biome skins: four poses, locked silhouettes, Gillou source alpha and red palette, no duplicate marine accessories, preloaded textures, stable unlocks and RNG')
 love.event.quit()
end
return T
