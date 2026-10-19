-- Empty gameplay layout with a painted backdrop. Stable ID 6 preserves saves.
local S={}
function S.openEdges()
 return Campaign and Campaign.biome==6 and not (Secret and Secret.inArena())
end
function S.edgeDepth(position,side)
 return 23+8*math.sin(position*.037+side*1.7)+4*math.sin(position*.091+side*.8)
end
function S.fallAt(x,y)
 return S.openEdges() and (x<S.edgeDepth(y,3) or x>Arena.width-S.edgeDepth(y,4)
  or y<S.edgeDepth(x,1) or y>600-S.edgeDepth(x,2))
end
-- Ten campaign routes. Only generated/empty defaults are upgraded; authored
-- Workshop layouts and recorded replay snapshots keep their exact contents.
function S.layout(n,width)
 width=width or Arena.width
 local routes={
  {{.30,190},{.65,340},{.82,180}},
  {{.24,400},{.48,160},{.78,390}},
  {{.18,170},{.80,170},{.80,450},{.22,450}},
  {{.48,110},{.82,300},{.50,480},{.18,300}},
  {{.20,140},{.78,440},{.75,150},{.23,440}},
  {{.25,180},{.50,440},{.76,180},{.50,100}},
  {{.18,150},{.80,450},{.80,150},{.18,450},{.50,300}},
  {{.20,300},{.40,130},{.76,200},{.78,440},{.44,470}},
  {{.18,120},{.82,120},{.82,470},{.18,470},{.50,150},{.50,450}}
 }
 local entities={{kind='spawn',id='sky-spawn',x=width*.5,y=535}}
 local function add(kind,id,x,y,typ,speed)
  entities[#entities+1]={kind=kind,id='sky-'..id,x=x,y=y,type=typ,speed=speed}
 end
 if n==10 then
  add('boss','guardian',width*.5,170,'storm')
 else
  for i,p in ipairs(routes[n] or routes[1]) do add('tear','tear-'..i,p[1]*width,p[2]) end
  add('mob','dragonfly',width*.28,160,'dragonfly',70+n*4)
  if n>=2 then add('mob','moth',width*.75,310,'mist_moth',42+n*2) end
  if n>=3 then add('mob','bat',width*.15,250,'wind_bat',180+n*5) end
  if n>=4 then add('tornado','vortex',width*.5,280) end
  if n>=5 then add('mob','dragonfly-2',width*.78,160,'dragonfly',90+n*3) end
  if n>=6 then add('mob','moth-2',width*.25,350,'mist_moth',54) end
  if n>=7 then add('tornado','vortex-2',width*.72,390) end
  if n>=8 then add('mob','bat-2',width*.85,390,'wind_bat',225);entities[#entities].dx=-1 end
  if n>=9 then add('mob','dragonfly-3',width*.48,110,'dragonfly',105) end
 end
 return {world=6,biome=6,level=n,width=width,height=600,skyRevision=4,entities=entities}
end
function S.prepare(layout)
 if layout.world~=6 or (layout.skyRevision or 0)>=4 then return layout end
 for _,e in ipairs(layout.entities) do
  if e.kind~='spawn' and not (e.id and e.id:match('^sky%-')) then return layout end
 end
 return S.layout(layout.level,layout.width)
end
function S.draw(width,height)
 require('biome_floor').draw(6,width,height,UI and UI.clock or 0)
end
return S
