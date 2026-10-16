-- A fixed, telegraphed silk sweep supplements the guardian's aimed volleys.
local W={}
function W.begin(f)
 f.weaveResume=f.phaseTime;f.phase='weave';f.phaseTime=0;f.volley=f.volley+1
 f.weaveX,f.weaveY=f.x,f.y
 f.weaveAngle=math.atan2(player.y+12-f.y,player.x+15-f.x)
 f.weaveCount=f.pressure()==3 and 7 or 5;f.weaveFired=0
 f.weaveSide=f.volley%2==0 and 1 or -1
end
function W.angle(f,index)
 return f.weaveAngle+(index-(f.weaveCount+1)/2)*.24*f.weaveSide
end
function W.update(f)
 f.angle=f.weaveAngle-math.pi/2
 local wanted=math.min(f.weaveCount,math.max(0,math.floor((f.phaseTime-.85)/.13)+1))
 while f.weaveFired<wanted do
  f.weaveFired=f.weaveFired+1
  local a=W.angle(f,f.weaveFired);local dx,dy=math.cos(a),math.sin(a)
  f.webs[#f.webs+1]={x=f.weaveX+dx*25,y=f.weaveY+dy*25,vx=dx*360,vy=dy*360,age=0}
 end
 if f.phaseTime>.85+f.weaveCount*.13+.3 then
  f.phase='webs';f.phaseTime=f.weaveResume;f.shot=.65
 end
end
function W.draw(f)
 if f.phase~='weave' then return end
 local g=love.graphics;g.push('all');g.setShader()
 local tell=math.min(1,f.phaseTime/.85)
 for i=f.weaveFired+1,f.weaveCount do
  local a=W.angle(f,i);local c,s=math.cos(a),math.sin(a)
  -- Fine silk fibres mark the locked firing directions before the release.
  g.setColor(.88,.94,.73,(.12+tell*.22));g.setLineWidth(1)
  g.line(f.weaveX+c*32,f.weaveY+s*32,f.weaveX+c*145,f.weaveY+s*145)
  g.setColor(.96,1,.82,.4+tell*.4)
  g.circle('fill',f.weaveX+c*(32+tell*13),f.weaveY+s*(32+tell*13),2)
 end
 g.pop()
end
return W
