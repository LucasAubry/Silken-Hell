-- Optional timings only. Unauthored actors retain their original simulation.
local A={keys={'attackDelay','attackDuration','attackInterval'}}
A.specs={
 mist_moth={attackDelay=.85,attackDuration=2,attackInterval=2.5},
 jelly={attackDelay=1,attackInterval=3.5},light_jelly={attackDelay=3,attackInterval=3},
 worm={attackDelay=3.6,attackInterval=4},fish={attackDelay=2.3,attackDuration=.7,attackInterval=2.3},
 lava_scorpion={attackDelay=1.5,attackDuration=3,attackInterval=2},
 cloud_beast={attackDelay=3.15,attackDuration=.9},
 magma_larva={attackDelay=3.6},dragonfly={attackDelay=0}
}
function A.spec(e)
 if e.kind and e.kind~='mob' then return end
 local spec=A.specs[e.type];if not spec then return end
 if e.type=='worm' and e.startUnderground then return {attackDelay=1.2,attackInterval=4} end
 return spec
end
function A.valid(e,key,value)
 local spec=A.spec(e);local min=key=='attackDelay' and (e.type=='cloud_beast' and 1.95 or 0) or .1
 return spec and spec[key]~=nil and type(value)=='number' and value==value and value>=min and value<=120
end
function A.apply(m,e)
 for _,key in ipairs(A.keys) do if e[key]~=nil then m[key]=e[key] end end
 if e.type=='lava_scorpion' and e.attackDelay~=nil then m.charge=e.attackDelay end
 if e.type=='magma_larva' and e.attackDelay~=nil then m.fuse=e.attackDelay end
end
function A.due(m,dt,first,interval)
 if m.attackDelay==nil and m.attackInterval==nil then return nil end
 local before=m.attackClock or 0;local now=before+dt;m.attackClock=now
 first=m.attackDelay or first;interval=m.attackInterval or interval
 local function index(t) return t<first and -1 or math.floor((t-first+1e-9)/interval) end
 return index(now)>index(before==0 and -1e-9 or before)
end
function A.charge(m,dt)
 if m.attackDelay==nil and m.attackDuration==nil and m.attackInterval==nil then return nil end
 local spec=A.spec(m);m.attackClock=(m.attackClock or 0)+dt
 local t=m.attackClock-(m.attackDelay or spec.attackDelay)
 local duration=m.attackDuration or spec.attackDuration
 local active=t>=-1e-9 and (math.max(0,t)%(duration+(m.attackInterval or spec.attackInterval)))<duration
 if active and not m.attackActive then m.attackAngle=math.atan2(player.y+12-m.y,player.x+15-m.x) end
 m.attackActive=active;return active
end
function A.warning(m)
 if m.attackClock==nil then return nil end
 local spec=A.spec(m);local t=m.attackClock-(m.attackDelay or spec.attackDelay)
 if t<0 then return t>=-.25 end
 local duration=m.attackDuration or spec.attackDuration;local cycle=duration+(m.attackInterval or spec.attackInterval)
 local phase=t%cycle;return phase<duration or phase>=cycle-.25
end
return A
