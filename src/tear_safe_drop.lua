-- Search only the walkable component containing the player. Deterministic and
-- run once on a carrier's fall, never while the tear is being carried.
local T={}
local offsets={{0,0},{-20,0},{20,0},{0,-20},{0,20},{-20,-20},{20,-20},{-20,20},{20,20}}
function T.safe(x,y)
 if x<40 or x>Arena.width-40 or y<40 or y>560 or Arena.blocked(x-20,y-20,40,40) then return false end
 for _,o in ipairs(offsets) do
  if Realms.fallAt(x+o[1],y+o[2]) or Hazards.inLava(x+o[1],y+o[2],0) then return false end
 end
 return true
end
function T.position(x,y)
 local step=16;local cols=math.floor(Arena.width/step);local rows=math.floor(600/step)
 local cached={}
 local function safe(col,row)
  if col<1 or col>=cols or row<1 or row>=rows then return false end
  local key=row*cols+col
  if cached[key]==nil then cached[key]=T.safe(col*step,row*step) end
  return cached[key],key
 end
 local sx,sy=player.x+15,player.y+12
 local startX,startY,bestStart=nil,nil,math.huge
 -- Find a safe foothold near the player, including when they are mid-dash.
 for row=1,rows-1 do for col=1,cols-1 do
  local d=(col*step-sx)^2+(row*step-sy)^2
  if d<bestStart and safe(col,row) then startX,startY,bestStart=col,row,d end
 end end
 if not startX then return sx,sy end
 local queue={{startX,startY}};local visited={[startY*cols+startX]=true};local index=1
 local bx,by,best=startX*step,startY*step,math.huge
 local directions={{-1,0},{1,0},{0,-1},{0,1}}
 while index<=#queue do
  local node=queue[index];index=index+1
  local px,py=node[1]*step,node[2]*step;local d=(px-x)^2+(py-y)^2
  if d<best then bx,by,best=px,py,d end
  for _,dir in ipairs(directions) do
   local col,row=node[1]+dir[1],node[2]+dir[2];local ok,key=safe(col,row)
   if ok and not visited[key] then visited[key]=true;queue[#queue+1]={col,row} end
  end
 end
 return bx,by
end
return T
