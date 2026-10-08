local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false;Replay.ghost=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.sessionLayout=nil;App.singleLevel=false;App.practice=nil;App.hardcore=false
 Campaign.select(3);player.level=1;reset_level();App.state='playing';player.reset=false
 local F=require('final_spider');local A=require('final_art');local W=require('brown_walk');local H=require('boss_hud');local g=love.graphics
 local directions={{'down',0,210},{'up',0,-210},{'right',260,0},{'left',-260,0}}
 local function setup(p)
  F.reset(true);F.engaged=true;F.phase='webs';F.jumpCooldown=10;F.x=Arena.width*.5;F.y=300;F.shot=0
  player.x=F.x+p[2]-15;player.y=F.y+p[3]-12;player.reset=false
 end
 local gallery=g.newCanvas(1000,540)
 g.push('all');g.setCanvas(gallery);g.clear(.035,.04,.055,1);g.pop()
 for col,p in ipairs(directions) do
  setup(p);local oldX,oldY=F.x,F.y;F.update(.04)
  assert(F.walkMoving and F.walkPhase>0 and (F.x~=oldX or F.y~=oldY),'Queen walks during web attacks')
  assert(A.facing(F.visualAngle())==p[1],'Firing orientation survives movement: '..p[1])
  assert(#F.webs>0,'A web was fired')
  local shot=F.webs[1];assert(shot.vx*p[2]+shot.vy*p[3]>0,'Web flies towards the player')
  F.update(.04);assert(A.facing(F.visualAngle())==p[1],'Queen tracks player between shots')
  local firstVertices
  for row=1,3 do
   F.walkPhase=(row-1)*math.pi/2;F.walkMoving=true
   g.push('all');g.setCanvas(gallery);g.origin();g.translate(125+(col-1)*250,90+(row-1)*180);g.scale(2,2);g.translate(-F.x,-F.y)
   F.webs={};F.draw();g.pop()
   local key=({down='queen',up='up_red',right='side_red',left='left_red'})[p[1]]
   local pose=W.meshes[Art.images['final_'..key].image][p[1]]
   if row==1 then
    firstVertices={};for i,v in ipairs(pose.vertices) do firstVertices[i]={v[1],v[2]} end
   elseif row==2 then
    local changed=0;for i,v in ipairs(pose.vertices) do if math.abs(v[1]-firstVertices[i][1])>.1 or math.abs(v[2]-firstVertices[i][2])>.1 then changed=changed+1 end end
    assert(changed>50,'Leg mesh visibly changes between strides: '..p[1])
   end
  end
 end
 gallery:newImageData():encode('png','boss-spider-walk-gallery.png');gallery:release()
 setup(directions[1]);F.phase='recover';F.shot=100;F.update(.1);assert(not F.walkMoving,'Legs stop at rest')
 F.leap('webs');F.update(.1);assert(not F.walkMoving and F.jumpHeight>0,'No walking in midair')
 setup(directions[4]);F.phase='lay';F.update(.04);assert(F.walkMoving,'Walking while laying')
 setup(directions[1]);F.phase='charge';F.chargeX=F.x+200;F.chargeY=F.y;F.update(.04)
 assert(F.walkMoving and F.dashing and A.facing(F.visualAngle())=='right','Charging follows movement with animated legs')
 local canvas=g.newCanvas(1200,750);g.push('all');g.setCanvas(canvas);g.clear(.025,.035,.045,1)
 local kinds={'merle','wasp','storm','hedgehog','octopus','skeleton_fish','final_spider','mixed'}
 for i,kind in ipairs(kinds) do
  local boss={hp=6,maxHp=10,name=kind,flash=0,hardcore=kind=='wasp'}
  if kind=='wasp' then boss.bees={{hp=3},{hp=2},{hp=1}} end
  g.push();g.translate(0,(i-1)*88-25);H.paint(boss,kind);g.pop()
 end
 g.pop();local data=canvas:newImageData()
 for i,kind in ipairs(kinds) do
  local r,green,b=data:getPixel(345,85+(i-1)*88-25)
  assert(r>.6 and r>green*4 and r>b*4,'Red health fill: '..kind)
 end
 data:encode('png','boss-red-health-gallery.png');data:release();canvas:release()
 print('PASS four-direction aiming through actual movement and web shots, animated queen mesh in four poses, resting/jump/charge/lay states, red health for every boss and hardcore wasps')
 local frame=0
 love.update=function()
  frame=frame+1
  if frame<=4 then setup(directions[frame]);F.update(.04);App.capture='boss-spider-facing-'..directions[frame][1]..'.png'
  elseif frame==6 then love.event.quit() end
 end
end
return T
