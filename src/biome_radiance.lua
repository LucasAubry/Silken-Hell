local B={}
B.palettes={
 [1]={1,.80,.42},[3]={.79,.89,.40},[4]={.12,.78,1},[5]={.95,.76,.40},[6]={.72,.86,1},
 [2]={1,.18,.10},[7]={.15,.46,1},[8]={.57,.46,1},
}
function B.biome()return (App.state=='bossWorld' or Secret.inArena()) and 8 or Campaign.biome end
function B.active()
 return Graphics.effects and B.palettes[B.biome()]~=nil
  and not (App.state=='playing' and (Campaign.biome==7 or Abyss.playerHidden() or Abyss.encounterActive()))
end
function B.sources(add,time)
 local biome=B.biome();local tint=B.palettes[biome]
 if not B.active() then return end
 if biome==4 then
  for i=1,4 do local x,y=B.coralPosition(i)
   add(x,y,115,.40+.07*math.sin(time*.8+i),i%2==0 and {.62,.22,.88} or tint)
  end
 elseif biome==3 then
  add(Arena.width*.48,220,300,.40,tint)
  add(Arena.width*.79,430,200,.24,{.35,.53,.34})
  for i=1,3 do local x,y,c=B.wispPosition(i,time);add(x,y,100,.45,c) end
 elseif biome==5 then
  add(Arena.width*.48,220,300,.40,tint)
  add(Arena.width*.79,430,200,.24,{.58,.39,.20})
 elseif biome==6 then
  add(Arena.width*.48,220,300,.40,tint)
  add(Arena.width*.79,430,200,.24,{.39,.58,.78})
 elseif biome==1 then
  add(Arena.width*.25,100,300,.40,tint);add(Arena.width*.78,380,260,.30,{1,.90,.68})
 elseif biome==2 then
  add(Arena.width*.48,380,300,.40+.025*math.sin(time*.65),tint)
  add(Arena.width*.79,170,200,.24,{.70,.20,.07})
 elseif biome==7 then
  -- Color only existing revealed surfaces; this light never removes darkness.
  add(Arena.width*.20,100,220,.16,tint);add(Arena.width*.82,480,180,.13,{.43,.18,.83})
 elseif biome==8 then
  add(Arena.width*.18,135,270,.27,tint);add(Arena.width*.82,135,270,.27,{.25,.64,1})
 else
  add(Arena.width*(.28+.025*math.sin(time*.09)),165,330,.20,tint)
  add(Arena.width*.76,375,270,.18,{1,.81,.57})
 end
end
function B.coralPosition(i)
 return (i%2==0 and Arena.width-42 or 42),90+(i-1)*140
end
function B.wispPosition(i,time)
 local sites={{.09,130},{.88,460},{.63,545}}
 local site=sites[i]
 return Arena.width*site[1]+math.sin(time*.35+i*2)*13,site[2]+math.cos(time*.28+i)*9,
  i==2 and {.63,.78,.32} or {.84,.92,.46}
end
function B.drawMap()
 if not B.active() then return end
 local g=love.graphics
 B.shader=B.shader or g.newShader('assets/shaders/biome_radiance.glsl')
 B.shader:send('clock',UI.clock);B.shader:send('biome',B.biome());B.shader:send('arenaSize',{Arena.width,600})
 g.setShader(B.shader);g.rectangle('fill',0,0,Arena.width,600)
end
function B.motes()
 if not B.active() then return end
 local g=love.graphics;local biome=B.biome();local t=UI.clock;local tint=B.palettes[biome]
 g.push('all');g.setShader();g.setBlendMode('add')
 if not B.halo then
  local vertices={{0,0,0,0,1,1,1,1}}
  for i=0,32 do local a=i*math.pi/16;vertices[#vertices+1]={math.cos(a),math.sin(a),0,0,1,1,1,0} end
  B.halo=g.newMesh(vertices,'fan','static')
 end
 local count=Graphics.quality==1 and 42 or Graphics.quality==3 and 120 or 88
 local rise=biome==2 and 19 or biome==4 and 9 or biome==7 and 1.5 or 3.5
 local drift=biome==3 and 5 or 2
 -- Decorative motion uses no gameplay RNG. Abyss motes are drawn beneath darkness.
 for i=1,count do
  local depth=.55+(i%7)/7
  local x=(i*137.31+math.sin(t*.16+i*2.4)*(biome==3 and 32 or 20)+t*drift*depth)%Arena.width
  local y=(i*79.73-t*rise*depth+math.sin(t*.3+i)*7)%600
  local pulse=(.5+.5*math.sin(t*.7+i*1.7))^2
  local edge=math.min(1,x/20,(Arena.width-x)/20,y/20,(600-y)/20)
  local alpha=(.12+pulse*.36)*edge*(biome==7 and .55 or 1);local size=(.65+i%3*.3)*depth
  local r,green,b=tint[1],tint[2],tint[3]
  if biome==3 and i%3==0 then r,green,b=.91,.95,.57
  elseif biome==2 and i%3==0 then r,green,b=1,.70,.28
  elseif biome==4 and i%5==0 then r,green,b=.60,.48,1
  elseif biome==1 and i%4==0 then r,green,b=1,.94,.77 end
  g.setColor(r,green,b,alpha)
  if biome==4 and i%4==0 then
   g.setLineWidth(.6);g.circle('line',x,y,size+1)
  elseif biome==2 and i%3==0 then
   g.setLineWidth(.8);g.line(x,y,x+.5,y+size*2.5)
  else
   g.circle('fill',x,y,size)
  end
  if i%3==0 then
   g.setColor(r,green,b,alpha*.20)
   g.draw(B.halo,x,y,0,5+size*2,5+size*2)
  end
 end
 if biome==3 then
  for i=1,3 do
   local x,y,c=B.wispPosition(i,t);local glow=.65+.15*math.sin(t*1.3+i)
   g.setColor(c[1],c[2],c[3],glow*.22);g.draw(B.halo,x,y,0,23,23)
   g.setColor(c[1],c[2],c[3],glow*.5);g.draw(B.halo,x,y,0,7,7)
   g.setColor(.93,.97,.64,glow);g.circle('fill',x,y,1.5)
  end
 end
 g.pop()
end
return B
