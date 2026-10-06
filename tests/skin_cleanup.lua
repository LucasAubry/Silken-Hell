local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 local g=love.graphics
 -- Texture import must eliminate partial alpha and faint exterior PNG residue.
 for _,pose in ipairs({'down','up','profil'}) do
  local texture=require('art_filter').image('assets/skins/commun/'..pose..'.png')
  local w,h=texture:getDimensions();local canvas=g.newCanvas(w,h)
  g.push('all');g.setCanvas(canvas);g.origin();g.clear();g.setShader();g.setColor(1,1,1);g.draw(texture);g.pop()
  local pixels=canvas:newImageData()
  for y=0,h-1 do for x=0,w-1 do local _,_,_,a=pixels:getPixel(x,y);assert(a==0 or a==1,'Binary skin alpha after PNG import: '..pose) end end
  pixels:release();canvas:release()
 end
 -- Menu portraits retain fractional positions for the original continuous drift.
 local draw=Art.draw;local checked=false
 Art.draw=function(key,x,y,...)
  if key=='player_skin_down' then local px,py=g.transformPoint(x,y);assert(math.abs(px-128.2)<.001 and math.abs(py-128.3)<.001);checked=true end
  return draw(key,x,y,...)
 end
 g.push('all');g.origin();g.setColor(1,1,1);Characters.portrait(2,128.2,128.3,220,'down');g.pop();Art.draw=draw;assert(checked)
 local gallery=g.newCanvas(1200,22*130)
 g.push('all');g.setCanvas(gallery);g.clear(.045,.045,.055);g.setColor(1,1,1)
 local artDraw=Art.draw
 Art.draw=function(key,...) assert(not key:find('crown') and not key:find('couronne'),'No crown overlay: '..key);return artDraw(key,...) end
 for id=1,22 do for col,dir in ipairs({'down','up','left','right'}) do
  Characters.portrait(id,(col-.5)*300,(id-.5)*130,120,dir)
 end;g.print(Characters.names[id],8,(id-1)*130+5) end
 g.pop();Art.draw=artDraw
 local d=gallery:newImageData();local f=assert(io.open('/tmp/silken-all-skins.png','wb'));f:write(d:encode('png'):getString());f:close();d:release();gallery:release()
 -- Regression for pale gold highlights that used to become skin-colored holes.
 local canvas=g.newCanvas(256,256)
 local function render(id,dir)
  g.push('all');g.setCanvas(canvas);g.origin();g.clear();g.setColor(1,1,1)
  Characters.portrait(id,128,128,220,dir);g.pop();return canvas:newImageData()
 end
 for _,dir in ipairs({'down','up','left','right'}) do
  local reference=render(2,dir);local points={}
  for y=25,125 do for x=45,210 do
   local r,green,b,a=reference:getPixel(x,y)
   if a>.999 and r-b>.15 and green-b>.075 and r<b*1.5+.1 then
    points[#points+1]={x,y,r,green,b}
   end
  end end
  assert(#points>0,'Pale gold regression samples: '..dir)
  for id=2,21 do
   local result=render(id,dir)
   for _,p in ipairs(points) do
    local r,green,b,a=result:getPixel(p[1],p[2])
    assert(a>.999 and math.max(math.abs(r-p[3]),math.abs(green-p[4]),math.abs(b-p[5]))<.015,'Intact gold highlights: '..id..' '..dir)
   end
   result:release()
  end
  reference:release()
 end
 canvas:release()
 local seen={}
 for _,world in ipairs(Worlds.order) do
  App.singleLevel=true;App.practice=world==3 and 1 or 10;App.start(world);player.reset=false
  assert(Story.isBossLevel(),'Boss inscription enabled')
  local x,y,side=Story.wallSpot();local key=side..':'..x..':'..y;assert(not seen[key],'Distinct inscription position');seen[key]=true
  player.x=side=='left' and 22 or side=='right' and Arena.width-60 or x-15
  player.y=side=='top' and 22 or side=='bottom' and 549 or y-12
  assert(Story.atWall(x,y,side),'Inscription accessible: '..world)
  assert(not Arena.blocked(player.x,player.y,30,24),'Clear approach: '..world)
  if world~=3 then player.level=1;assert(not Story.isBossLevel(),'No inscription on exploration levels') end
 end
 for _,entry in ipairs(Bestiary.entries) do if entry.id=='merle' then assert(entry.art=='merle_egg' and Art.images[entry.art]) end end
 require('tests.skin_fx').run()
 print('PASS all 22 skins, crown-free portraits, seven distinct boss-only wall locations, egg bestiary and skin pickup palettes')
 love.event.quit()
end
return T
