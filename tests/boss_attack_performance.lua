local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 local V=require('mobs.bosses.octopus.tentacle');local clock=love.timer.getTime;local g=love.graphics
 local points={};for i=1,20 do points[i]={x=120+i*13,y=200+math.sin(i*.23)*60,width=26-i*.8,nx=math.cos(i*.23),ny=math.sin(i*.23),distance=(i-1)*16} end
 local vertices=V.build(points,0);local started=clock()
 for frame=1,80 do points[10].y=200+math.sin(frame*.03)*60;vertices=V.build(points,0,vertices) end
 local elapsed=(clock()-started)*1000/80
 local digest={};for _,v in ipairs(vertices)do for _,n in ipairs(v)do digest[#digest+1]=string.format('%.12g',n or 0)end end
 local hash=love.data.encode('string','hex',love.data.hash('sha256',table.concat(digest,',')))
 love.filesystem.write('boss-attack-perf.json',require('json').encode({tentacleMs=elapsed,hash=hash,vertices=#vertices}))
 print(string.format('BOSS_PERF tentacle_build=%.3fms vertices=%d hash=%s',elapsed,#vertices,hash))
 print('PASS boss attack geometry benchmark');love.event.quit()
end
return T
