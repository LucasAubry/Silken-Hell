local S={total=28}
function S.reset(a) a.missingBones={};a.embeddedBones={};a.boneAnchors={};a.bombsEaten=0 end
function S.speed(a)
 local missing=0
 for id in pairs(a.missingBones or {})do if not (a.embeddedBones or {})[id]then missing=missing+1 end end
 local max=540*(player.original_speed or 1)*1.05
 a.swimSpeed=190+(max-190)*math.min(1,missing/S.total+(a.bombsEaten or 0)/6);a.swimMaxSpeed=a.swimSpeed
 return a.swimSpeed
end
function S.id(b)
 if b.part=='head' then return 'head' end
 if b.key=='skeleton_tail' then return 'tail' end
 if b.key=='skeleton_spine' then return 'spine:'..b.part end
 return 'rib:'..b.part..':'..(b.side or 1)
end
local function pose(b,host)
 local c,s=math.cos(host.angle),math.sin(host.angle)
 return host.x+c*b.dx-s*b.dy,host.y+s*b.dx+c*b.dy,host.angle+b.angle
end
function S.build(a)
 local anchors={};local visible={}
 for _,b in ipairs(a.bones)do b.stockId=S.id(b);anchors[b.stockId]=b
  if b.stockId=='head' or not a.missingBones[b.stockId] then visible[#visible+1]=b end
 end
 a.boneAnchors=anchors
 local ids={};for id in pairs(a.embeddedBones)do ids[#ids+1]=id end;table.sort(ids)
 for _,id in ipairs(ids)do local e=a.embeddedBones[id];local host=anchors[e.host] or anchors.head
  local x,y,angle=pose(e,host)
  visible[#visible+1]={stockId=id,embedded=true,key=e.key,part=e.part,side=e.side,x=x,y=y,w=e.w,h=e.h,angle=angle,gx=x,gy=y}
 end
 a.bones=visible
end
function S.restore(a,p)
 if not p.stockId or not a.missingBones[p.stockId] then return false end
 a.missingBones[p.stockId]=nil;a.embeddedBones[p.stockId]=nil;S.speed(a);return true
end
function S.launch(a,b,speed)
 if not b or b.stockId=='head' then return false end
 local id=b.stockId
 if a.missingBones[id] and not a.embeddedBones[id] then return false end
 -- Keep bones planted in a fired host attached to the remaining head.
 for _,e in pairs(a.embeddedBones)do if e.host==id then
  local x,y,angle=pose(e,a.boneAnchors[id]);local head=a.boneAnchors.head;local c,s=math.cos(head.angle),math.sin(head.angle)
  e.host='head';e.dx=(x-head.x)*c+(y-head.y)*s;e.dy=-(x-head.x)*s+(y-head.y)*c;e.angle=angle-head.angle
 end end
 a.embeddedBones[id]=nil;a.missingBones[id]=true
 local dx,dy=player.x+15-b.x,player.y+12-b.y;local d=math.max(.001,math.sqrt(dx*dx+dy*dy))
 a.debris[#a.debris+1]={stockId=id,key=b.key,part=b.part,side=b.side,x=b.x,y=b.y,vx=dx/d*speed,vy=dy/d*speed,w=b.w,h=b.h,angle=b.angle,armTime=.18,recoverTime=.28,shed=true}
 S.speed(a);return true
end
function S.choose(a,side,onScreen)
 local best,bestRank
 for _,b in ipairs(a.bones)do if b.stockId~='head' and (not a.missingBones[b.stockId] or a.embeddedBones[b.stockId])then
  local usable=not onScreen or (b.x>25 and b.x<Arena.width-25 and b.y>30 and b.y<570)
  local rank=b.key=='skeleton_rib' and 1 or b.key=='skeleton_tail' and 2 or 3
  if usable and (not side or b.key~='skeleton_rib' or b.side==side) and (not bestRank or rank<bestRank or (rank==bestRank and rank==3 and b.part>best.part))then best,bestRank=b,rank end
 end end
 -- Do not fire the tail while ribs remain on the opposite side or outside the screen.
 if bestRank and bestRank>1 then
  for _,b in ipairs(a.bones)do if (b.key=='skeleton_rib' or (bestRank==3 and b.key=='skeleton_tail')) and (not a.missingBones[b.stockId] or a.embeddedBones[b.stockId])then return nil end end
 end
 return best
end
local function intersection(p,x0,y0,b)
 local c,s=math.cos(b.angle),math.sin(b.angle)
 local rx,ry=math.max(10,b.w*.32),math.max(10,b.h*.32)
 local ax,ay=((x0-b.x)*c+(y0-b.y)*s)/rx,(-(x0-b.x)*s+(y0-b.y)*c)/ry
 local bx,by=((p.x-b.x)*c+(p.y-b.y)*s)/rx,(-(p.x-b.x)*s+(p.y-b.y)*c)/ry
 local dx,dy=bx-ax,by-ay;local aa=dx*dx+dy*dy;local cc=ax*ax+ay*ay-1
 if cc<=0 then return 0 end
 if aa<.00001 then return nil end
 local bb=2*(ax*dx+ay*dy);local disc=bb*bb-4*aa*cc
 if disc<0 then return nil end
 local t=(-bb-math.sqrt(disc))/(2*aa)
 if t>=0 and t<=1 then return t end
end
function S.recover(a,p,x0,y0)
 if not p.stockId or not a.missingBones[p.stockId] or (p.recoverTime or 0)>0 then return false end
 local host,t
 for _,b in ipairs(a.bones)do if not b.embedded then local hit=intersection(p,x0,y0,b)
  if hit and (not t or hit<t)then host,t=b,hit end
 end end
 if not host then return false end
 p.x=x0+(p.x-x0)*t;p.y=y0+(p.y-y0)*t
 local c,s=math.cos(host.angle),math.sin(host.angle)
 a.embeddedBones[p.stockId]={host=host.stockId,dx=(p.x-host.x)*c+(p.y-host.y)*s,dy=-(p.x-host.x)*s+(p.y-host.y)*c,angle=p.angle-host.angle,key=p.key,part=p.part,side=p.side,w=p.w,h=p.h}
 S.speed(a);return true
end
return S
