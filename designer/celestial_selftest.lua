local T={}
function T.run(M,state,select)
 io.stdout:setvbuf('no');M.draftFilename='celestial-test-drafts.json';M.drafts={};M.applied={version=1,levels={}}
 select(6,1);state.category='Terrain';state.all=false;love.draw()
 local before=#M.layout.entities
 local draw=Biome and Biome.draw or require('biome_floor').draw
 local floor=require('biome_floor');local seen
 floor.draw=function(world,w,h,t) if world==6 then seen=t end;return draw(world,w,h,t) end
 love.update(.5);love.draw();assert(seen==0 and state.clock==0,'Sky preview keeps the new backdrop frozen')
 love.update(2);love.draw();assert(seen==0 and #M.layout.entities==before,'Editor updates leave scenery and map unchanged')
 floor.draw=draw
 for _,e in ipairs(require('catalog')) do if e.kind=='hole' then state.tool=e end end
 assert(state.tool,'Hole brush exists')
 local view=state.canvas
 local function point(x,y)return view.x+x*view.s,view.y+y*view.s end
 local x,y=point(320,180);love.mousepressed(x,y,1)
 x,y=point(320,400);love.mousemoved(x,y);love.draw();love.mousereleased(x,y,1)
 assert(#M.layout.entities==before+1 and M.validate(M.layout),'Hole brush paints a valid zone')
 local zone=M.layout.entities[#M.layout.entities];assert(zone.kind=='hole' and #zone.points==4)
 M.undo(false);assert(#M.layout.entities==before);M.undo(true);assert(#M.layout.entities==before+1)
 state.tool=nil;local bat=M.add({kind='mob',type='wind_bat',speed=210},220,200)
 love.draw()
 -- x, y, speed occupy three rows; direction is the first control below them.
 local w=love.graphics.getWidth();love.mousepressed(w-227+80,280+3*39+16,1)
 assert(state.directionPicker==bat,'Departure control opens its selector')
 love.draw();local h=love.graphics.getHeight();local yy=(h-350)/2
 love.mousepressed(w/2,yy+74+42+16,1);assert(bat.startDirection=='left')
 local insect=require('sky_insect_art');local drawInsect=insect.draw;local facing
 insect.draw=function(kind,x,y,size,t,angle,...) if kind=='wind_bat' and x==bat.x and y==bat.y then facing=insect.facing(angle) end;return drawInsect(kind,x,y,size,t,angle,...) end
 love.draw();assert(facing=='left','Editor PNG faces the authored direction')
 insect.draw=drawInsect
 M.undo(false);assert(not M.layout.entities[#M.layout.entities].startDirection,'Departure supports undo')
 M.undo(true);bat=M.layout.entities[#M.layout.entities];assert(bat.startDirection=='left','Departure supports redo');M.selected=bat
 state.details=bat;love.draw();local count=#M.layout.entities
 love.mousepressed(400,300,1);assert(#M.layout.entities==count,'Behaviour sheet blocks map clicks')
 love.keypressed('escape');assert(not state.details)
 local original=M.clone(M.layout)
 for _,kind in ipairs({'blackbird_chick','spinner','jelly','fish','light_jelly','cloud_beast','cloud_snail','mist_moth','wind_bat'}) do
  for _,dir in ipairs({'up','down','left','right'}) do
   M.add({kind='mob',type=kind,speed=80,startDirection=dir},400,300);love.draw()
  end
 end
 M.layout=original;M.selected=nil;M.persist()
 local snail
 for _,entry in ipairs(require('catalog')) do
  assert(entry.kind~='electric_ground' and entry.kind~='rain','Obsolete terrain tools are removed')
  if entry.type=='cloud_snail' then snail=entry end
 end
 state.tool=snail;local mx,my=point(480,300);love.mousepressed(mx,my,1);love.draw()
 assert(M.selected and M.selected.type=='cloud_snail','Real mouse placement of a snail must not crash')
 state.tool=nil;state.category='Environnement';love.draw()
 local rain=require('level_environment').enabled('rain',6,M.layout.environment);assert(rain,'Rain defaults on in Sky')
 love.mousepressed(110,344,1);love.draw();assert(M.layout.environment.rain==false,'Environment toggle persists off')
 M.undo(false);assert(require('level_environment').enabled('rain',6,M.layout.environment),'Environment participates in undo')
 M.undo(true);assert(M.layout.environment.rain==false,'Environment participates in redo')
 assert(M.validate(M.layout));local saved=require('json').decode(love.filesystem.read(M.draftFilename))['6:1']
 assert(saved.environment.rain==false and saved.entities[#saved.entities].type=='cloud_snail','Options and placed snail persist in drafts')
 local timed=M.add({kind='mob',type='mist_moth',speed=55},500,300)
 state.attackSettings=timed;love.draw()
 local height=love.graphics.getHeight();local top=(height-410)/2
 love.mousepressed(w/2+180,top+94,1);state.inputText='4';love.keypressed('return')
 love.draw();love.mousepressed(w/2+180,top+152,1);state.inputText='10';love.keypressed('return')
 assert(timed.attackDelay==4 and timed.attackDuration==10 and timed.attackInterval==nil,'Attack settings are individually optional')
 assert(M.validate(M.layout));local encoded=require('json').decode(love.filesystem.read(M.draftFilename))['6:1']
 assert(encoded.entities[#encoded.entities].attackDuration==10,'Attack timings persist')
 love.draw();love.mousepressed(w/2+180,top+152,1);state.inputText='0';love.keypressed('return');assert(timed.attackDuration==10 and state.timingError,'Invalid attack duration is rejected')
 love.keypressed('escape');love.keypressed('escape');assert(not state.attackSettings)
 M.undo(false);assert(M.layout.entities[#M.layout.entities].attackDuration==nil,'Undo restores default duration')
 M.undo(true);timed=M.layout.entities[#M.layout.entities];assert(timed.attackDuration==10)
 state.attackSettings=timed;state.timingError=nil
 local frames=0;state.testUpdate=function()
  frames=frames+1
  if frames==2 then love.graphics.captureScreenshot('celestial-editor.png') end
  if frames==4 then print('PASS celestial editor: hole drawing, environment toggles, snail placement, undo/redo, direction controls and persistence');love.event.quit() end
 end
end
return T
