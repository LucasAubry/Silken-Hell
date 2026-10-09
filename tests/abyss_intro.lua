local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;Profile.name='QA';App.sessionLayout=nil;App.singleLevel=false;App.hardcore=false;Secret.duel=nil;App.state='playing';LevelLayouts.disabled=false
 local G=require('abyss_gate');local I=require('mobs.bosses.abyss.arrival');local S=require('abyss_sequence')
 local d={levels={}};for n=6,10 do d.levels['7:'..n]={level=n,marker=n}end
 S.migrate(d);assert(d.levels['7:6'].marker==7 and d.levels['7:7'].marker==8 and d.levels['7:8'].marker==9 and d.levels['7:10'].marker==10)
 S.migrate(d);assert(d.levels['7:6'].marker==7,'Migration runs exactly once')
 Campaign.select(7);player.level=9;reset_level();player.reset=false;require('run_start').active=false
 assert(G.active and not G.closing and #mobs==0 and not Abyss.giant,'Level nine is a quiet stationary gate')
 player.x=G.tx-35-15;player.y=G.ty-12;G.update(.01);assert(not G.closing,'Proximity without touching the tear does not close the mouth')
 player.x=Arena.width*.18-15;player.y=288
 G.update(.1);assert(not G.closing and not Campaign.canCollect(),'Tear cannot skip the jaws')
 local frame=0
 love.update=function()
  frame=frame+1
  if frame==1 then App.capture='abyss-gate-open.png'
  elseif frame==3 then player.x=G.tx-15;player.y=G.ty-12;G.update(.01);assert(G.closing);local sx,sy=G.shake();assert(sx==0 and sy==0,'No shake before jaw closure');G.update(.25);local effects=Graphics.effects;Graphics.effects=true;sx,sy=G.shake();assert(math.abs(sx)+math.abs(sy)>0,'Jaw closure shakes the view');Graphics.effects=false;sx,sy=G.shake();assert(sx==0 and sy==0);Graphics.effects=effects;App.capture='abyss-gate-closed.png'
  elseif frame==5 then G.update(.6);assert(G.fade==1);App.capture='abyss-gate-black.png'
  elseif frame==7 then
   G.update(.5);App.simulate(.01);assert(player.level==10 and not G.active,'Swallow advances through standard level progression')
   assert(I.current and #I.current.lumenParticles==0 and I.current.swimHead.x<0,'Boss and particles begin offscreen/absent')
   assert(math.abs(player.x+15-Arena.width/2)<1 and player.y+12==300,'Player starts in the middle')
   App.capture='abyss-arrival-empty.png'
  elseif frame==9 then I.update(I.current,1.5);App.capture='abyss-arrival-left.png'
  elseif frame==11 then I.update(I.current,.9);assert(I.current.open and #I.current.lumenParticles==300 and #I.current.returnShots==0);App.capture='abyss-arrival-spit.png'
  elseif frame==13 then local a=I.current;I.update(a,1);assert(not I.current and #a.lumenParticles==300 and a.returnShotTimer>1,'Fight starts after particles settle');App.capture='abyss-arrival-ready.png'
  elseif frame==15 then print('PASS level migration, giant gate, mouth closure, blackout, level ten arrival, central spawn and blue-particle spit');love.event.quit()end
 end
end
return T
