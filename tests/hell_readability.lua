local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false;Replay.ghost=false
 Profile.save=function()end;Bestiary.save=function()end;Profile.recordBoss=function()end
 App.singleLevel=false;App.sessionLayout=nil;App.hardcore=false;App.preview=false;App.practice=nil;Secret.duel=nil;LevelLayouts.disabled=false
 local json=require('json');local layouts=json.decode(love.filesystem.read('custom_levels.json')).levels
 local function level(w,n)
  Campaign.select(w);player.level=n;reset_level();App.state='playing';require('run_start').active=false;require('run_start').goAge=nil
 end
 -- Test the repository's actual authored levels, independently of test saves.
 local read=LevelLayouts.read;LevelLayouts.read=function()
  if App.sessionLayout then local l=App.sessionLayout;return {[l.world..':'..l.level]=l} end
  return layouts
 end
 for n=1,10 do
  level(2,n);local points=levels[n].larme_position
  assert(#points>0 or Campaign.carrier,'Every Hell campaign level has a tear target or carrier: '..n)
  if n<10 then assert((Campaign.canCollect() or Campaign.tearCarried()) and not objet.larme.taken,'Visible collectible in level '..n)
  else assert(objet.larme.taken and Bosses.alive(),'Boss reward stays locked until victory') end
  local authored=0;for _,e in ipairs(layouts['2:'..n].entities) do if e.kind=='tear' then authored=authored+1 end end
  if Campaign.carrier then
   assert(Campaign.tearCarried() and #points==authored,'Carrier needs no artificial ground site')
   local oldX=objet.larme.x;Campaign.carrier.x=Campaign.carrier.x+20;Campaign.updateTear(0)
   assert(math.abs(objet.larme.x-oldX-20)<.001,'Carried tear follows its creature without fixed sites')
   objet.larme_dropped=true;assert(Campaign.canCollect(),'Released tear becomes collectible')
  elseif authored==0 then
   assert(#points==1,'One recovered target only')
   assert(not Arena.blocked(objet.larme.x-12,objet.larme.y-10,54,60),'Recovered tear clears walls')
   for dy=-10,50,10 do for dx=-12,42,9 do assert(not Hazards.inLava(objet.larme.x+dx,objet.larme.y+dy,0),'Recovered tear clears lava') end end
   local x,y=objet.larme.x,objet.larme.y;Campaign.updateTear(20);assert(objet.larme.x==x and objet.larme.y==y,'Recovered tear remains stable')
  else assert(#points==authored,'Preserve authored tear positions') end
 end
 level(6,1);assert(#levels[1].larme_position==0 and objet.larme.taken,'Ciel remains empty')
 local map={world=2,level=1,width=960,height=600,entities={{kind='spawn',x=480,y=300}}}
 App.sessionLayout=map;level(2,1);assert(#levels[1].larme_position==0 and objet.larme.taken,'An explicitly empty Workshop/preview map stays empty');App.sessionLayout=nil
 -- Compare the actual tear against the new ground with FX both enabled and off.
 local g=love.graphics;local canvas=g.newCanvas(1000,600)
 level(2,2)
 for _,effects in ipairs({true,false}) do
  Graphics.effects=effects
  g.push('all');g.setCanvas(canvas);g.origin();g.setShader();g.clear();Campaign.draw();g.pop()
  local before=canvas:newImageData()
  g.push('all');g.setCanvas(canvas);g.origin();Campaign.drawTear(true);g.pop()
  local after=canvas:newImageData();local peak=0
  local x,y=objet.larme.x+15,objet.larme.y+20+math.sin(UI.clock*2)*3
  for yy=math.floor(y-17),math.floor(y+17) do for xx=math.floor(x-12),math.floor(x+12) do
   local r,gg,b=after:getPixel(xx,yy);local r0,g0,b0=before:getPixel(xx,yy)
   peak=math.max(peak,(r*.2126+gg*.7152+b*.0722)-(r0*.2126+g0*.7152+b0*.0722))
  end end
  assert(peak>.35,'Tear contrasts with red floor even without effects')
  after:encode('png',effects and 'hell-red-tear.png' or 'hell-red-tear-no-effects.png');before:release();after:release()
 end
 Graphics.effects=true;level(2,1);UI.clock=3;love.draw()
 LevelLayouts.read=read
 print('PASS Hell: all ten campaign tear targets, safe missing-tear recovery, boss reward lock, authored sites preserved, empty Ciel/preview preserved, high-contrast rendering with effects on/off')
 print('VISUALS '..love.filesystem.getSaveDirectory());love.event.quit()
end
return T
