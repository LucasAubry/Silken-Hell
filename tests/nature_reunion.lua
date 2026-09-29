local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 App.start(3);player.level=2;reset_level();local E=Ending
 E.partner.x=Arena.width-70;E.partner.y=300;player.x=Arena.width-250;player.y=288
 local x,y=E.partner.x,E.partner.y;local switches=0;local last
 local complete=E.complete;E.complete=function()error('Unexpected catch')end
 for i=1,120 do E.update(1/60);local facing=E.partner.facing;if last and facing~=last then switches=switches+1 end;last=facing end
 assert((E.partner.x-x)^2+(E.partner.y-y)^2>100^2,'Leaves wall instead of flickering in place')
 assert(switches<8,'Stable pose transitions')
 E.complete=complete
 local caught=0;E.complete=function()caught=caught+1 end
 E.clock=30;player.x=E.partner.x-15;player.y=E.partner.y-12;E.update(.01);assert(caught==1);E.complete=complete
 local callbacks=0
 E.startCredits(function()callbacks=callbacks+1;App.state='victory'end)
 love.keypressed('escape','escape',false);love.keypressed('escape','escape',true)
 assert(App.state=='credits' and E.creditEscapes==1,'Holding escape is not three presses')
 love.keypressed('escape','escape',false);assert(App.state=='credits')
 love.keypressed('escape','escape',false);assert(App.state=='victory' and callbacks==1)
 E.finishCredits();assert(callbacks==1,'Completion callback once')
 E.startCredits(function()callbacks=callbacks+1;App.state='victory'end);assert(E.creditEscapes==0)
 E.updateCredits(E.creditDuration());assert(callbacks==2,'Natural end preserved')
 App.start(3);player.level=2;reset_level()
 local tick=0
 love.update=function()tick=tick+1;if tick==1 then App.capture='renaissance-nature.png' elseif tick==5 then print('PASS stable wall escape and poses, catch, three separate Escape presses, callback once, natural credits');love.event.quit()end end
end
return T
