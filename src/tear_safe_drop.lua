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
 -- Locate nearby candidates in rings instead of probing the whole arena.
 local function nearest(sx,sy)
  local cx=math.max(1,math.min(cols-1,math.floor(sx/step+.5)))
  local cy=math.max(1,math.min(rows-1,math.floor(sy/step+.5)))
  local bx,by,best,bkey=nil,nil,math.huge,math.huge
  local offset=math.max(math.abs(cx*step-sx),math.abs(cy*step-sy))
  local function visit(col,row)
   local d=(col*step-sx)^2+(row*step-sy)^2;local key=row*cols+col
   if (d<best or d==best and key<bkey) and safe(col,row) then bx,by,best,bkey=col,row,d,key end
  end
  for radius=0,math.max(cols,rows) do
   for col=cx-radius,cx+radius do visit(col,cy-radius);if radius>0 then visit(col,cy+radius) end end
   for row=cy-radius+1,cy+radius-1 do visit(cx-radius,row);visit(cx+radius,row) end
   local lower=(radius+1)*step-offset
   if bx and lower>0 and lower*lower>best then return bx,by,best end
  end
  return bx,by,best
 end
 local startX,startY=nearest(player.x+15,player.y+12)
 if not startX then return player.x+15,player.y+12 end
 local _,_,nearestDistance=nearest(x,y)
 -- Best-first flood preserves reachability, and ends as soon as the closest
 -- safe shoreline is reached. Disconnected islands still cannot receive a tear.
 local heap={};local visited={};local count=0
 local function push(col,row)
  local node={col,row,(col*step-x)^2+(row*step-y)^2};count=count+1;local i=count
  while i>1 do local parent=math.floor(i/2);if heap[parent][3]<=node[3] then break end;heap[i]=heap[parent];i=parent end
  heap[i]=node;visited[row*cols+col]=true
 end
 local function pop()
  local first=heap[1];local last=heap[count];heap[count]=nil;count=count-1
  if count>0 then
   local i=1
   while i*2<=count do
    local child=i*2;if child<count and heap[child+1][3]<heap[child][3] then child=child+1 end
    if last[3]<=heap[child][3] then break end
    heap[i]=heap[child];i=child
   end
   heap[i]=last
  end
  return first
 end
 push(startX,startY)
 local bx,by,best=startX*step,startY*step,math.huge
 local directions={{-1,0},{1,0},{0,-1},{0,1}}
 while count>0 do
  local node=pop();local d=node[3]
  if d<best then bx,by,best=node[1]*step,node[2]*step,d end
  if best<=nearestDistance then return bx,by end
  for _,dir in ipairs(directions) do
   local col,row=node[1]+dir[1],node[2]+dir[2];local key=row*cols+col
   if not visited[key] and safe(col,row) then push(col,row) end
  end
 end
 return bx,by
end
return T
