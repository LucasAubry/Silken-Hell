local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;LevelLayouts.disabled=true;love.focus=function()end
 local g=love.graphics
 local files={};for _,p in ipairs({'profile.txt','scores.tsv','score_details.json'}) do files[p]=love.filesystem.read(p) or false end
 Profile.biomeStats={};Profile.bossKills={};Profile.stats={tears=0,deaths=0,attempts=0,eggs=0}
 App.sessionLayout=nil;App.preview=nil;Campaign.select(6)
 Profile.record('attempts',4);Profile.record('tears');Profile.record('deaths');Profile.recordBoss('storm')
 assert(Profile.biomeCounters(4).attempts==1 and Profile.biomeCounters(6).attempts==1,'Start is attributed to destination biome')
 Replay.playing=true;Profile.recordBoss('storm');Profile.record('tears');Replay.playing=false
 Profile.load()
 assert(Profile.bossKills.storm==1 and Profile.biomeCounters(6).tears==1 and Profile.biomeCounters(6).deaths==1,'Counters persist without replay inflation')
 for p,data in pairs(files) do if data then love.filesystem.write(p,data) else love.filesystem.remove(p) end end
 Profile.save=function()end;Bestiary.save=function()end
 local function capture(name)
  local c=g.newCanvas(1200,750);g.push('all');g.setCanvas(c);g.origin();g.clear();UI.draw();g.pop()
  local d=c:newImageData();local f=assert(io.open('/tmp/silken-'..name..'.png','wb'));f:write(d:encode('png'):getString());f:close();d:release();c:release()
 end
 Profile.stats={tears=1234,deaths=5678,attempts=6789};App.state='achievements';capture('counters')
 App.state='statistics';capture('statistics');love.keypressed('escape');assert(App.state=='menu')
 for _,world in ipairs(Worlds.order) do
  App.practice=world==3 and 1 or 10;App.singleLevel=true;App.start(world)
  objet.larme.taken=false;Campaign.carrier=nil;Ending.active=false;Renaissance.active=false;Campaign.drawTear()
 end
 print('PASS persistent biome/boss counters, destination attribution, replay isolation, stats navigation and seven tear palettes')
 love.event.quit()
end
return T
