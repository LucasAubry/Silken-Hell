-- Preview poses share game sprites and rigs, never run combat updates.
local A={}
local facing={ange='ange',snake='snake',spinner='serpent',wasp='wasp',waspling='waspling',storm='merle_flight',hedgehog='hedgehog',fish='fish',jelly='jelly',mole='mole',lanternfish='lanternfish',blackbird_chick='merle'}
function A.draw(e,x,y,size,time)
 local g=love.graphics;local t=time or 0;local id=e.id
 g.push('all');g.setColor(1,1,1)
 local dir=({'down','left','up','right'})[math.floor(t/2.8)%4+1]
 local angle=({down=0,left=math.pi/2,up=math.pi,right=-math.pi/2})[dir]
 if id=='dragonfly' or id=='mist_moth' or id=='wind_bat' or id=='lava_scorpion' then
  require('sky_insect_art').draw(id,x+math.sin(t*1.4)*size*.03,y,size,t,angle)
 elseif id=='worm' or id=='larva' then
  Art.drawWorm(dir,x,y,size*(id=='larva' and .5 or 1),t)
 elseif id=='final_spider' or id=='queen_child' then
  local variant=id=='final_spider' and 'queen' or (e.art or 'final_baby_red'):gsub('final_','')
  local walk={walkPhase=t*7,walkMoving=true,enraged=false}
  require('final_art').spider(variant,x,y,size*.85,angle,walk)
  if id=='final_spider' then require('final_art').clutch(x,y,size*.85,24,angle) end
 elseif id=='octopus' then
  require('octopus_preview').draw(x,y,size,t)
 elseif id=='light_jelly' then
  Art.drawSwimmer('abyss_octopus',x,y,size,math.sin(t*.6)*.12,t)
 elseif id=='lava' then
  A.lava=A.lava or {x=0,y=0,radius=22,points={-20,0,0,-8,22,4,8,12},seed=7}
  g.translate(x,y);g.scale(size/100)
  require('lava_zones').draw(A.lava,t,1,2)
 elseif id=='crab' then
  local key=math.floor(t*6)%2==0 and 'crab_open' or 'crab_closed'
  Art.draw(key,x+math.sin(t*2)*size*.035,y,size,math.sin(t)*.08)
 elseif id=='merle' then
  require('mobs.bosses.raven.egg').draw(x,y,size*.5,0,math.sin(t*2.4)*.045)
 elseif id=='skeleton_fish' then
  local key=math.sin(t*1.8)>.4 and 'skeleton_open' or 'skeleton_head'
  local a=Art.images[key];Art.draw(key,x,y+math.sin(t*1.4)*size*.04,size*a.w/math.max(a.w,a.h),math.sin(t*.7)*.07)
 elseif id=='cloud_snare' then
  require('tornado_art').draw(Art,x,y,t,size)
 elseif e.trapKind or id=='scie' or id=='piege' then
  require('trap_art').draw(e.trapKind or id,x,y,size,e.world,t%3>2,t*2)
 elseif id=='earth_tunnel' then
  g.translate(x,y);g.scale(size/104,size/104);require('earth_mound').draw(0,0)
 elseif e.art=='rain' then
  g.setColor(1,.85,.32,.7+.3*math.sin(t*6)^2)
  g.polygon('fill',x+size*.14,y-size*.42,x-size*.25,y+size*.05,x-size*.04,y+size*.05,x-size*.14,y+size*.42,x+size*.25,y-size*.06,x+size*.04,y-size*.06)
 elseif id=='ange' or id=='snake' then
  local key=id..'_'..dir;local ink=require('paradise_ink');local a=ink.frame(key)
  ink.draw(key,x,y+math.sin(t*3)*size*.025,size*a.w/math.max(a.w,a.h),math.sin(t*2)*.035)
 elseif facing[id] then
  local flap=id=='wasp' or id=='waspling' or id=='storm' or id=='blackbird_chick'
  local pulse=flap and math.sin(t*18)*.07 or math.sin(t*4)*.025
  g.translate(x,y+(flap and math.sin(t*3)*size*.025 or 0));g.scale(1+pulse,1-pulse*.4)
  local name=facing[id]
  if name=='merle_flight' and dir=='right' then g.scale(-1,1);dir='left' end
  Art.drawFacing(name,dir,0,0,size)
 else
  local a=Art.images[e.art];local width=a and size*a.w/math.max(a.w,a.h) or size
  local pulse=math.sin(t*(id=='magma_larva' and 14 or 3))*.025
  g.translate(x,y);g.scale(1+pulse,1-pulse)
  require('prism_material').drawPreview(function()Art.draw(e.art,0,0,width,math.sin(t*1.4)*.035)end)
 end
 g.pop()
end
return A
