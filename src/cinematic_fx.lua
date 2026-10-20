-- Screen-space atmosphere; all effects settle before the gameplay handoff.
local F={}
function F.draw(scene,canvas,w,h)
 local g=love.graphics;local t=scene.age or 0;local duration=scene.duration or 6.7
 local fade=math.min(1,t/.35)*math.max(0,math.min(1,(duration-.45-t)/.8))
 local pulse=math.exp(-((t-2.8)/.18)^2)+.6*math.exp(-((t-5.65)/.14)^2)
 if not F.canvas or F.canvas:getWidth()~=w or F.canvas:getHeight()~=h then
  if F.canvas then F.canvas:release() end
  F.canvas=g.newCanvas(w,h)
 end
 local target=g.getCanvas();g.push('all');g.setCanvas(F.canvas);g.clear();scene.draw(canvas,w,h)
 g.setCanvas(target);g.origin();g.setShader();g.setColor(1,1,1);g.setBlendMode('alpha','premultiplied')
 g.draw(F.canvas,math.sin(t*77)*pulse*fade*3,math.cos(t*93)*pulse*fade*4)
 g.setBlendMode('add','alphamultiply')
 for i=1,46 do
  local edge=i%2==0 and .02 or .98
  local px=w*(edge+math.sin(i*2.4+t*.6)*.035);local py=h*((i*.173-t*.075)%1)
  g.setColor(.55,.70,.85,fade*(.08+.08*math.sin(t*2+i)^2))
  g.circle('fill',px,py,1+i%3)
 end
 for i=1,12 do
  g.setColor(.32,.45,.62,fade*(.004+pulse*.004))
  g.setLineWidth(i*3);g.rectangle('line',0,0,w,h)
 end
 g.pop()
end
return F
