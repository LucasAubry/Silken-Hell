local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 Campaign.select(3);player.level=1;reset_level();App.state='playing'
 local F=require('final_spider');F.reset(true);F.engaged=true;F.phase='webs';F.x=480;F.y=300
 player.x=85;player.y=488;F.damage();F.damageGrace=0;F.damage()
 assert(F.pendingEggs==1 and #F.eggs==0,'Damage queues an egg, never spawns one remotely')
 local lastX,lastY=F.x,F.y;local laid=false
 for i=1,500 do
  F.update(.01)
  if #F.eggs>0 then
   local e=F.eggs[1];assert((e.x-F.x)^2+(e.y-F.y)^2<4,'Egg is laid at queen position')
   assert(e.x>Arena.width-60 and e.y<75,'Queen reached distant nest')
   assert(e.age==0 and e.hatch==1.5,'Hatch timer starts only on laying');laid=true;break
  end
  assert((F.x-lastX)^2+(F.y-lastY)^2<30^2,'Travel is continuous');lastX,lastY=F.x,F.y
 end
 assert(laid and F.pendingEggs==0)
 local P=require('reached_level_preview');local preview=require('world_preview');local g=love.graphics
 Profile.completed={};for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 App.previewLevels={}
 Profile.levels={[1]=3,[2]=5,[3]=1,[4]=4,[5]=6,[6]=7,[7]=2}
 local cw,cb,pl,aw=Campaign.world,Campaign.biome,player.level,Arena.width
 local canvas=g.newCanvas(680,300)
 for _,w in ipairs(Worlds.order)do
  local layout=P.layout(w);assert(layout.level==Profile.levels[w])
  g.push('all');g.setCanvas(canvas);g.origin();g.clear();preview.draw(w,0,0,680,300,false);g.pop()
  assert(P.shownLevel==Profile.levels[w]);assert(Campaign.world==cw and Campaign.biome==cb and player.level==pl and Arena.width==aw,'Preview preserves live state')
  canvas:newImageData():encode('png','reached-level-'..w..'.png')
 end
 App.previewLevels['1:false']=2;WorldMap.hardcore=false;assert(P.level(1)==2,'Live run level takes priority over furthest unlocked level')
 canvas:release()
 local focus=love.window.hasFocus;love.window.hasFocus=function()return false end
 assert(Graphics.targetRate(false)==10 and Graphics.targetRate(true)==10,'Background game and editor are capped')
 love.window.hasFocus=focus
 print('PASS real nest travel and laying, reached-level previews with borders, preserved run state and background frame cap')
 love.event.quit(0)
end
return T
