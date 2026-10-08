-- Keep the textures used by lazy renderers resident before opening the menu.
local P={}
function P.draw()
 local g=love.graphics
 g.push('all');g.origin();g.setCanvas();g.setShader();g.setScissor()
 if P.font then g.setFont(P.font) end
 local w,h=g.getDimensions();local time=love.timer.getTime()-(P.started or 0)
 g.clear(.06,.05,.04)
 g.setShader(P.shader);P.shader:send('time',time);P.shader:send('biome',1)
 P.shader:send('deep',{.91,.81,.65});P.shader:send('fog',{.96,.86,.70});P.shader:send('accent',{1,.97,.89})
 g.setColor(1,1,1);g.draw(P.pixel,0,0,0,w,h);g.setShader()
 local scale=math.min(w/1200,h/750);g.translate(w/2,h/2);g.scale(scale,scale)
 g.setColor(.025,.028,.03,.88);g.rectangle('fill',-300,-98,600,208,8)
 g.setColor(.82,.72,.49,.55);g.rectangle('line',-300,-98,600,208,8)
 for _,x in ipairs({-300,300}) do g.polygon('fill',x,-7,x+5,0,x,7,x-5,0) end
 g.setColor(.94,.91,.82);g.printf('Chargement des assets…',-300,-55,600,'center')
 g.setColor(.7,.72,.67);g.printf('Préparation du jeu',-300,-17,600,'center')
 -- A moving silk knot signals activity without inventing a percentage.
 g.setColor(.82,.72,.49,.25);g.setLineWidth(1);g.line(-225,60,225,60)
 local knot=math.sin(time*1.8)*202
 for i=1,5 do local radius=i*3;g.setColor(.94,.87,.68,.22/i);g.circle('line',knot,60,radius,8) end
 g.setColor(.96,.89,.72);g.polygon('fill',knot,54,knot+5,60,knot,66,knot-5,60)
 g.pop()
end
function P.screen()
 -- Lazy icon textures may load while an offscreen canvas is being composed.
 if love.graphics.getCanvas() then return end
 love.event.pump();P.draw();love.graphics.present()
end
function P.begin()
 P.font=love.graphics.newFont(24)
 P.started=love.timer.getTime();P.shader=love.graphics.newShader('assets/shaders/celestial.glsl');P.pixel=love.graphics.newImage(love.image.newImageData(1,1))
 P.screen()
 local last=love.timer.getTime()
 Art.onLoad=function()
  if love.timer.getTime()-last>=.05 then P.screen();last=love.timer.getTime() end
 end
end
function P.load()
 local extra={
  earth_mound='assets/monstres/terre/taupe/earth_mound.png',
  octopus_mantle='assets/monstres/ocean/poulpe/mantle.png',
  ink_ground='assets/monstres/ocean/poulpe/ink_ground.png',
  merle_egg='assets/monstres/paradis/merle/merle_egg.png',
  reward_crown='assets/skins/accessoires/couronne.png',
  queen_crown='assets/monstres/renaissance/reine/crown.png',
  hardcore_skull='assets/sprites/hardcore_skull.png',
 }
 for _,pose in ipairs({'up','down','left'}) do extra['original_'..pose]='texture/spider_'..pose..'.png' end
 for path in pairs(require('asset_paths').paths) do
  local name=path:match('^assets/sprites/final/(.+)%.png$')
  if name then extra['final_'..name]=path end
 end
 for key,path in pairs(extra) do if not Art.images[key] then Art.add(key,path) end end
 local image=require('art_filter').image
 for _,kind in ipairs({'ange','serpent'}) do
  for _,dir in ipairs({'up','down','left','right'}) do
   image('assets/monstres/paradis/'..kind..'/'..(kind=='serpent' and 'snake' or kind)..'_'..dir..'.png')
  end
 end
 for _,name in ipairs({'scie','scie_pique','scie_blanc','piege','piege_active'}) do image('assets/monstres/paradis/pieges/'..name..'.png') end
 require('paradise_ink').load()

 require('silk_art').load()
 require('servant_art').load()
 local borders=require('biome_borders');borders.images=borders.images or {}
 for _,biome in ipairs({3,4,7}) do borders.images[biome]=image('assets/environments/ink/wall-'..biome..'.png') end
 image('assets/icons/biome-backgrounds.png')
 Art.onLoad=nil
 P.font:release();P.font=nil
 P.shader:release();P.pixel:release();P.shader=nil;P.pixel=nil
 P.ready=true
end
return P
