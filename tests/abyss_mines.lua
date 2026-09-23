local T={}
local function level(n)
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false;Replay.data=nil
 App.hardcore=false;App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;Secret.duel=nil;LevelLayouts.disabled=true
 Campaign.select(7);player.level=n or 10;reset_level();App.state='playing';player.reset=false
end
function T.run()
 local M=require('mobs.bosses.abyss.mines')
 level();local a=Abyss
 assert(#a.lightSites==0 and #a.mines==2,'Mines replace cages')
 local hp=a.hp;a.clock=4;a.update(.01);assert(not a.open and a.hp==hp,'Preparation does not damage boss')
 a.clock=5.6;a.update(.01);assert(a.open,'Periodic suction retained')
 local mx,my=a.mouth();player.x=mx-15;player.y=my-12;player.charges=0;a.contact();assert(player.reset,'Being swallowed is lethal without charge')
 level();a=Abyss;local p=a.mines[1];p.age=1;player.x=p.x-15;player.y=p.y-12
 M.update(a,.01);assert(player.reset,'Walking into mine kills')
 level();a=Abyss;p=a.mines[1];p.age=1;player.x=p.x-40;player.y=p.y-12;player.dashing=true
 M.update(a,.01);assert(p.armed and not player.reset,'Dash detaches mine safely')
 player.dashing=false;player.x=Arena.width-65;player.y=500;a.open=true;a.buildBones();hp=a.hp
 for i=1,30 do M.update(a,.05);if a.hp<hp then break end end
 assert(a.hp==hp-2 and not a.open and a.recoil>0,'Swallowed mine damages boss and interrupts suction')
 level();a=Abyss;a.nextShot=0;a.update(.01);assert(#a.threads==3 and a.threads[1].tooth,'Teeth replace charging lightning')
 local t=a.threads[1];t.x=player.x+15;t.y=player.y+12;t.vx=0;t.vy=0;a.update(.01);assert(player.reset and player.charges==0,'Teeth are lethal, not a light resource')
 level();a=Abyss;a.hp=2;a.open=true;mx,my=a.mouth();a.mines={{x=mx+20,y=my,age=1,armed=true,vx=-100,vy=0,grace=1,freeTime=0}}
 M.update(a,.01);assert(a.defeated and #a.mines==0 and not a.open and Campaign.canCollect(),'Final mine wins and clears hazards')
 level();LevelLayouts.disabled=false
 Workshop.playLayout({world=7,level=10,width=960,height=600,entities={{kind='spawn',x=480,y=510},{kind='boss',type='skeleton_head',x=200,y=270},{kind='tear',x=480,y=300}}})
 local custom=Bosses.items[1].boss;assert(#custom.mines==2 and #custom.lightSites==0,'Authored boss uses new encounter')
 level(8);assert(not Abyss.boss and #Abyss.bones>0,'Earlier skeleton levels remain intact')
 print('PASS replacement encounter: periodic suction, lethal mouth/mines/teeth, dash detachment, mine damage/recoil, victory and authored bosses')
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then level();a=Abyss;for _,m in ipairs(a.mines) do m.age=2 end;a.fireBlue();App.capture='abyss-mines-idle.png'
  elseif tick==3 then a.open=true;a.clock=6;a.buildBones();local p=a.mines[1];p.armed=true;p.vx=-200;p.vy=0;p.grace=1;M.update(a,.3);App.capture='abyss-mines-suction.png'
  elseif tick==5 then love.event.quit(0) end
 end
end
return T
