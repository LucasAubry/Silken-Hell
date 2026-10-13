local B={}
B.palettes={
 [1]={1,.80,.42},[3]={.66,1,.50},[4]={.12,.78,1},[5]={1,.61,.24},[6]={.62,.82,1},
}
function B.active()
 return Graphics.effects and B.palettes[Campaign.biome]~=nil and not Secret.inArena()
end
function B.sources(add,time)
 local biome=Campaign.biome;local tint=B.palettes[biome]
 if not B.active() then return end
 if biome==4 then
  for i=1,4 do local x,y=B.coralPosition(i)
   add(x,y,115,.40+.07*math.sin(time*.8+i),i%2==0 and {.62,.22,.88} or tint)
  end
 elseif biome==3 then
  add(Arena.width*.22,150,240,.35,tint)
  add(Arena.width*.79,430,200,.34,{1,.40,.62})
  for i=1,3 do local x,y,c=B.wispPosition(i,time);add(x,y,100,.45,c) end
 elseif biome==5 then
  for i=1,3 do add(Arena.width*(.12+i*.22),95+i%2*90,230,.40+.025*math.sin(time*.7+i),tint) end
 elseif biome==1 then
  add(Arena.width*.25,110,280,.25,tint);add(Arena.width*.78,330,255,.18,{.64,.78,1})
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
  i==2 and {1,.40,.67} or {.40,1,.67}
end
function B.drawMap()
 if not B.active() then return end
 local g=love.graphics
 B.shader=B.shader or g.newShader('assets/shaders/biome_radiance.glsl')
 B.shader:send('clock',UI.clock);B.shader:send('biome',Campaign.biome);B.shader:send('arenaSize',{Arena.width,600})
 g.setShader(B.shader);g.rectangle('fill',0,0,Arena.width,600)
end
function B.motes()
 if not B.active() then return end
 local g=love.graphics;local biome=Campaign.biome;local t=UI.clock;local tint=B.palettes[biome]
 g.push('all');g.setShader();g.setBlendMode('add')
 local count=Graphics.quality==1 and 18 or 34
 for i=1,count do
  local x=(i*137.31+math.sin(t*.16+i*2.4)*20+t*2)%Arena.width
  local y=(i*79.73-t*(biome==4 and 6 or 2.5))%600
  local pulse=(.5+.5*math.sin(t*.7+i*1.7))^2
  local alpha=.10+pulse*.30;local size=.7+i%3*.3
  if biome==3 and i%3==0 then g.setColor(1,.50,.71,alpha) else g.setColor(tint[1],tint[2],tint[3],alpha) end
  g.circle('fill',x,y,size)
  if i%3==0 then
   for ring=3,1,-1 do
    g.setColor(tint[1],tint[2],tint[3],alpha*.045)
    g.circle('fill',x,y,ring*2+size)
   end
  end
 end
 if biome==3 then
  if not B.halo then
   local vertices={{0,0,0,0,1,1,1,1}}
   for i=0,32 do local a=i*math.pi/16;vertices[#vertices+1]={math.cos(a),math.sin(a),0,0,1,1,1,0} end
   B.halo=g.newMesh(vertices,'fan','static')
  end
  for i=1,3 do
   local x,y,c=B.wispPosition(i,t);local glow=.65+.15*math.sin(t*1.3+i)
   g.setColor(c[1],c[2],c[3],glow*.22);g.draw(B.halo,x,y,0,23,23)
   g.setColor(c[1],c[2],c[3],glow*.5);g.draw(B.halo,x,y,0,7,7)
   g.setColor(.82,1,.88,glow);g.circle('fill',x,y,1.5)
  end
 end
 g.pop()
end
return B
