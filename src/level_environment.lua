-- Saved environment options. Rendering is deterministic; lightning simulation lives in sky_weather.
local E={options={{key='rain',label='Pluie'},{key='leaves',label='Feuilles'},{key='ashes',label='Cendres'},{key='fireflies',label='Lucioles'},{key='blue',label='Particules bleues'},{key='lightning',label='Éclairs'}}}
local defaults={rain=6,leaves=3,ashes=2,fireflies=5,blue=7,lightning=6}
function E.settings()
 local layout=LevelLayouts and LevelLayouts.activeLayout
 return layout and layout.environment
end
function E.enabled(key,world,settings)
 if settings and settings[key]~=nil then return settings[key] end
 return defaults[key]==world or key=='fireflies' and world==3
end
function E.active(key)
 return E.enabled(key,Campaign.biome,E.settings())
end
function E.draw(world,w,h,t,settings,editor,layout)
 local g=love.graphics;g.push('all');g.setShader();g.setBlendMode('alpha');g.setLineWidth(1)
 if E.enabled('rain',world,settings) then
  for i=1,95 do
   local x=(i*173.9-t*34)%w;local y=(i*97.7+t*(180+i%5*17))%h
   g.setColor(.65,.81,.95,.16+(i%4)*.025);g.line(x,y,x-2,y+7+i%5)
  end
 end
 if editor and E.enabled('lightning',world,settings) then
  -- Frozen preview, never advance or spawn real strikes inside the editor.
  local x,y=w*.73,h*.46
  local zones=require('lightning_config').zones(layout,w)
  if zones[1] then x,y=zones[1].x,zones[1].y end
  local points={x-12,y-100,x+5,y-70,x-6,y-44,x+8,y-22,x,y}
  g.setColor(.40,.65,1,.3);g.setLineWidth(9);g.line(points)
  g.setColor(.86,.95,1,.95);g.setLineWidth(2);g.line(points)
  g.setColor(.55,.8,1,.4);g.ellipse('line',x,y,24,12);g.setLineWidth(1)
 end
 if E.enabled('leaves',world,settings) then
  for i=1,25 do
   local x=(i*137.3+t*14+math.sin(t+i)*18)%w;local y=(i*79.7+t*(14+i%4*3))%h
   g.push();g.translate(x,y);g.rotate(math.sin(t*.8+i)*.8+t*.2)
   g.setColor(.42+i%3*.10,.58,.20,.7);g.ellipse('fill',0,0,3+ i%3,1.6);g.pop()
  end
 end
 if E.enabled('ashes',world,settings) and (world~=2 or editor) then
  for i=1,60 do
   local x=(i*137.31+math.sin(t*.4+i)*18)%w;local y=(i*79.73-t*(10+i%5))%h
   g.setColor(.85,.61,.39,.18+.25*math.sin(t+i)^2);g.circle('fill',x,y,.7+i%3*.4)
  end
 end
 for _,kind in ipairs({'fireflies','blue'}) do
  if E.enabled(kind,world,settings) and (kind~='blue' or world~=7 or editor) and (kind~='fireflies' or world~=3 or editor) then
   local blue=kind=='blue'
   g.setBlendMode('add')
   for i=1,blue and 110 or 32 do
    local x=(i*137.31+math.sin(t*.42+i)*16+t*2)%w;local y=(i*79.73+math.cos(t*.37+i)*12)%h
    local a=.4+.3*math.sin(t*2+i*2.4);local r=.7+i%3*.3
    g.setColor(blue and .08 or .60,blue and .35 or .82,blue and 1 or .18,a*.16);g.circle('fill',x,y,6)
    g.setColor(blue and .22 or .78,blue and .7 or 1,blue and 1 or .35,a);g.circle('fill',x,y,r*1.3)
    g.setColor(blue and .65 or 1,blue and .92 or 1,blue and 1 or .65,a);g.circle('fill',x,y,r*.52)
   end
  end
 end
 g.pop()
end
return E
