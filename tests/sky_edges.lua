local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false
 Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.singleLevel=true;App.practice=1;App.start(6);App.practice=nil;require('run_start').active=false
 local move,slow=Input.move,Input.slow
 for _,width in ipairs({Arena.width,1440}) do
  Arena.width=width;Arena.build(levels[player.level].player_position,levels[player.level].larme_position,false)
  assert(not Arena.blocked(0,280,30,24),'Sky perimeter collision must be open')
  assert(not Realms.fallAt(width/2,300),'The middle of the sky keeps the original walkable ground')
  assert(not Realms.fallAt(22.1,300) and Realms.fallAt(21.9,300),'The visible border and the falling boundary agree')
  local directions={{-1,0},{1,0},{0,-1},{0,1},{-1,-1},{1,-1},{-1,1},{1,1}}
  for _,d in ipairs(directions) do
   local x=d[1]<0 and 48 or d[1]>0 and width-48 or width/2
   local y=d[2]<0 and 48 or d[2]>0 and 552 or 300
   player.x=x-15;player.y=y-12;player.speed=1;player.reset=false;player.falling=false;player.fallTimer=0
   Input.move=function()return d[1],d[2] end;Input.slow=function()return false end
   local deaths=player.death;App.move(.20)
   assert(player.reset and player.falling,string.format('Edge %d,%d at %.2f,%.2f must cause a fall (width %d, reset %s, falling %s)',d[1],d[2],player.x+15,player.y+12,width,tostring(player.reset),tostring(player.falling)))
   assert(player.death==deaths+1,'A fall counts exactly one death')
   Realms.contact();assert(player.death==deaths+1,'Contact cannot count the same fall twice')
  end
  local wall={x=width/2,y=270,w=22,h=60};Arena.walls[#Arena.walls+1]=wall
  assert(Arena.blocked(width/2,280,30,24),'Interior walls in custom Sky maps remain solid')
  table.remove(Arena.walls)
  Secret.duel={}
  assert(Arena.blocked(0,280,30,24) and not require('sky').fallAt(10,300),'Secret arenas keep their enclosing walls')
  Secret.duel=nil
 end
 Input.move=move;Input.slow=slow
 App.practice=1;App.start(5);App.practice=nil
 assert(Arena.blocked(0,280,30,24),'Earth retains its perimeter walls')
 assert(not require('sky').fallAt(10,300),'Sky edge deaths do not affect other biomes')
 print('PASS Sky edges: four sides, four corners, dash substeps, fall animation, single death, wide arenas, interior walls and unchanged Earth/secret boundaries')
 love.event.quit()
end
return T
