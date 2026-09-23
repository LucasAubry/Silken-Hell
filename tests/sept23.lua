local T={}
local function level(w,n)
 Replay.disabled=true;Replay.recording=false;Replay.playing=false;Replay.data=nil;App.practice=nil;App.sessionLayout=nil;App.singleLevel=false
 LevelLayouts.disabled=true;Campaign.select(w);player.level=n;reset_level();App.state='playing';player.reset=false
end
function T.run()
 Online.enabled=false;Replay.disabled=true
 local old=Profile.keys.up;Profile.keys.up='mouse:2';local down=love.mouse.isDown
 love.mouse.isDown=function(b) return b==2 end
 local x,y=Input.move();assert(y==-1,'Mouse binding drives movement');love.mouse.isDown=down;Profile.keys.up=old
 UI.binding='left';love.mousepressed(5,5,4);assert(Profile.keys.left=='mouse:4' and not UI.binding);Profile.keys.left='left'
 RunDetails.reset();player.level=1;player.death=0;RunDetails.tick(2);player.death=1;RunDetails.death();RunDetails.death();RunDetails.tick(3)
 player.level=2;RunDetails.tick(4);assert(RunDetails.rows[1].time==5 and RunDetails.rows[1].deaths==1 and RunDetails.rows[2].time==4)
 Graphics.quality=1;assert(Graphics.floorHeight()==240 and Graphics.backgroundHz()==30);Graphics.quality=2;assert(Graphics.backgroundHz()==60)
 Graphics.effects=false;Graphics.save();Graphics.effects=true;Graphics.load();assert(not Graphics.effects);Graphics.effects=true;Graphics.save()
 level(7,10);assert(Abyss.phase==nil and #Abyss.bones>1,'Old full skeleton restored')
 local l=require('json').decode(love.filesystem.read('tests/abyss_restored_layout.json'));LevelLayouts.disabled=false;Workshop.playLayout(l)
 assert(#AbyssTerrain.parts>0 and Bosses.items[1].boss.headOnly and not Bosses.items[1].boss.phase,'Saved skeleton encounter restored')
 level(4,10);local o=Octopus;local c={x=o.x+200,y=o.y,speed=195,age=1,inked=true,frenzy=true,frenzyTurn=0,wave=1,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
 local changed=false;local previous
 for i=1,12 do c.x=o.x+200;c.y=o.y;c.age=c.age+.23;o.walkCrab(c,.23,function() end);local a=math.atan2(c.vy,c.vx);if previous and math.abs(a-previous)>.5 then changed=true end;previous=a end
 assert(changed,'Inked crabs change direction freely')
 local g=love.graphics;local canvas=g.newCanvas(960,600);g.setCanvas(canvas);o.draw();local raster=o.armRaster
 local start=love.timer.getTime()
 for i=1,120 do o.angle=i*.01;o.draw();g.flushBatch();assert(o.armRaster==raster) end
 print(string.format('PERF cached octopus draw %.3f ms/frame',(love.timer.getTime()-start)*1000/120));g.setCanvas();canvas:release()
 player.x=60;player.y=500;o.releaseCrabs();for _,crab in ipairs(o.crabs) do crab.emerge=nil end
 local kill=Hazards.kill;Hazards.kill=function() end;start=love.timer.getTime()
 for i=1,180 do o.updateCrabs(1/60) end
 print(string.format('PERF octopus crab simulation %.3f ms/frame',(love.timer.getTime()-start)*1000/180));Hazards.kill=kill
 print('PASS mouse input, split times/deaths, graphics persistence, restored abyss, free inked crabs, cached tentacles')
 local tick=0
 love.update=function(dt)
  tick=tick+1
  if tick==1 then level(3,1);App.capture='sept23-renaissance.png'
  elseif tick==3 then App.state='graphics';App.capture='sept23-graphics.png'
  elseif tick==5 then App.selectedWorld=3;WorldMap.open();App.capture='sept23-worlds.png'
  elseif tick==7 then Campaign.select(1);RunDetails.rows={{time=12.5,deaths=0},{time=34.2,deaths=2}};App.state='victory';UI.showRunDetails=true;App.capture='sept23-details.png'
  elseif tick==9 then level(4,10);App.capture='sept23-octopus.png'
  elseif tick==11 then io.stdout:flush();love.event.quit(0) end
 end
end
return T
