local B={}
B.palettes={
 [1]={1,.80,.42},[3]={.79,.89,.40},[4]={.12,.78,1},[5]={.95,.76,.40},[6]={.72,.86,1},
 [2]={1,.25,.055},[7]={.15,.46,1},[8]={.57,.46,1},
}
function B.biome()return (App.state=='bossWorld' or Secret.inArena()) and 8 or Campaign.biome end
function B.active()
 return Graphics.effects and B.palettes[B.biome()]~=nil
  and not (App.state=='playing' and (Campaign.biome==7 or Abyss.playerHidden() or Abyss.encounterActive()))
end
function B.sources(add,time)
 if not B.active() then return end
 local biome=B.biome();local tint=B.palettes[biome]
 if biome==3 then
  add(Arena.width*.48,220,300,.40,tint)
  add(Arena.width*.79,430,200,.24,{.35,.53,.34})
  for i=1,3 do local x,y,c=B.wispPosition(i,time);add(x,y,100,.45,c) end
 else
  for i=1,5 do local x,y,c=B.sparkPosition(i,time);add(x,y,32,.09,c) end
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
function B.sparkPosition(i,t)
 local biome=B.biome();local color=B.palettes[biome]
 local x=(i*173.7+math.sin(t*.31+i*2)*20)%Arena.width
 local y=80+(i*97.3)%440+math.cos(t*.24+i)*15
 if biome==2 then y=560-(t*12+i*93)%480
 elseif biome==4 then y=550-(t*7+i*81)%460
 elseif biome==6 then x=(x+t*5)%Arena.width end
 return x,y,color
end
function B.drawMap(count,blockers,rotations)
 if not B.active() then return end
 local g=love.graphics
 B.shader=B.shader or g.newShader('assets/shaders/biome_radiance.glsl')
 B.shader:send('intensity',B.biome()==3 and 1 or B.biome()==6 and .27 or .18)
 B.shader:send('blockerCount',count or 0)
 if count and count>0 then B.shader:send('blockers',unpack(blockers));B.shader:send('rotations',unpack(rotations)) end
 B.shader:send('clock',UI.clock);B.shader:send('biome',B.biome());B.shader:send('arenaSize',{Arena.width,600})
 g.setShader(B.shader);g.rectangle('fill',0,0,Arena.width,600)
end
function B.preview(biome,time)
 if not Graphics.effects or not B.palettes[biome] then return end
 local g=love.graphics;g.push('all');g.setBlendMode('add');g.setColor(1,1,1)
 B.shader=B.shader or g.newShader('assets/shaders/biome_radiance.glsl')
 B.shader:send('intensity',biome==3 and .45 or biome==6 and .27 or .18)
 B.shader:send('blockerCount',0);B.shader:send('clock',time)
 B.shader:send('biome',biome);B.shader:send('arenaSize',{680,300})
 g.setShader(B.shader);g.rectangle('fill',0,0,680,300);g.pop()
end
function B.motes()
 if not B.active() then return end
 local option=({[2]='ashes',[3]='fireflies',[5]='fireflies',[7]='blue'})[B.biome()]
 if option and not require('level_environment').active(option) then return end
 local g=love.graphics;local biome=B.biome();local t=UI.clock;local tint=B.palettes[biome]
 g.push('all');g.setShader();g.setBlendMode('add')
 if not B.halo then
  local vertices={{0,0,0,0,1,1,1,1}}
  for i=0,32 do local a=i*math.pi/16;vertices[#vertices+1]={math.cos(a),math.sin(a),0,0,1,1,1,0} end
  B.halo=g.newMesh(vertices,'fan','static')
 end
 local count=biome==3 and (Graphics.quality==1 and 42 or Graphics.quality==3 and 120 or 88) or (Graphics.quality==1 and 22 or 36)
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
 if biome~=3 then
  for i=1,5 do
   local x,y,c=B.sparkPosition(i,t);local pulse=.35+.25*math.sin(t*1.1+i*2)
   g.setColor(c[1],c[2],c[3],pulse*.18);g.draw(B.halo,x,y,0,11,11)
   g.setColor(c[1],c[2],c[3],pulse);g.circle('fill',x,y,1.4)
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
