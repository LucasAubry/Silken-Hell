local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end;love.focus=function()end
 local art=require('cloud_snail_art')
 assert(art.facing(0)=='right' and art.facing(math.pi)=='left' and art.facing(math.pi/2)=='down' and art.facing(-math.pi/2)=='up')
 for _,dir in ipairs({'up','down','right'}) do assert(art.sprite(dir).w>0) end
 local N=require('cloud_snail');local W=require('sky_weather')
 local layout={world=6,level=1,width=960,height=600,entities={{kind='spawn',x=450,y=490},{kind='tear',x=840,y=480},{kind='mob',type='cloud_snail',x=260,y=300,speed=80}}}
 assert(require('layout_schema').validate(layout))
 App.sessionLayout=layout;App.singleLevel=true;App.practice=1;App.start(6);require('run_start').active=false
 local snail=mobs[1];W.storm=false;W.strikes={};W.holes={};W.trails={};Realms.holes={};player.reset=false
 for _=1,150 do N.update(snail,1/60);W.update(1/60) end
 for _,hole in ipairs(W.snailHoles) do assert(hole.radius*2<N.size*.55,'Hole width follows the smaller snail') end
 assert(#W.snailHoles>10 and #W.snailHoles<100,'Distance-sampled holes stay bounded')
 local p=W.snailHoles[math.floor(#W.snailHoles*.6)];local x,y=(p.x+p.tx)/2,(p.y+p.ty)/2
 assert(N.fallAt(x,y) and Realms.fallAt(x,y),'Snail makes solid ground lethal')
 assert(not N.fallAt(80,70),'Distant ground is safe')
 local sx=snail.x;snail.is_frozen=true;N.update(snail,1);assert(snail.x==sx);snail.is_frozen=false
 player.x=x-15;player.y=y-12;Realms.contact();assert(player.reset and player.falling,'Walking on the trail immediately causes a fall')
 player.reset=false;player.falling=false;player.x=x-15;player.y=y+65
 local L=require('world_lighting');local apply=L.apply;local rendered
 L.apply=function(scene)rendered=apply(scene);return rendered end
 UI.clock=4;Realms.clock=4;Graphics.effects=true;Graphics.quality=2
 local order={};local ground,holes,electric=W.drawGround,N.drawTrail,W.drawElectric
 W.drawGround=function(...)order[#order+1]='ground';return ground(...)end
 N.drawTrail=function(...)order[#order+1]='holes';return holes(...)end
 W.drawElectric=function(...)order[#order+1]='electric';return electric(...)end
 local state=require('json').encode(require('replay_state').snapshot());love.draw()
 W.drawGround,N.drawTrail,W.drawElectric=ground,holes,electric
 local index={};for i,key in ipairs(order) do index[key]=i end
 assert(index.holes<index.ground and index.ground<index.electric,'Snail holes render below all hazards and electric traces')
 assert(state==require('json').encode(require('replay_state').snapshot()),'Rendering preserves simulation')
 local image=rendered:newImageData();image:encode('png','cloud-snail-holes.png');image:release();L.apply=apply
 W.resize(1.25);assert(N.fallAt(x*1.25,y));W.resize(.8)
 local count=#W.snailHoles;W.update(120);assert(#W.snailHoles==count and Realms.fallAt(x,y),'Holes remain lethal indefinitely')
 player.reset=false;player.x=x-15;player.y=y-12;Realms.contact();assert(player.reset,'Permanent hole still causes a fall')
 N.trail(100,100,110,100);local total=#W.snailHoles;N.trail(110,100,100,100);assert(#W.snailHoles==total,'Retracing a permanent segment does not accumulate duplicates');local other={type='cloud_snail',x=x,y=y,age=0,speed=66};mobs[#mobs+1]=other;N.update(other,.01);assert(other.falling,'Other snails fall into existing trails');N.update(other,.6);assert(other.dead,'Fallen snail disappears');W.reset();assert(#W.snailHoles==0,'Retry clears snail holes')
 print('PASS cloud snail: directional PNGs, lethal trail, immediate fall, permanent ground holes, freeze, resize, reset and draw isolation');love.event.quit()
end
return T
