-- Unopened worlds are wrapped in the Gardienne's silk, not weather clouds.
local C={}
function C.draw(x,y,seed,time)
 local g=love.graphics;g.push('all');g.setShader();g.translate(x,y)
 local breath=Graphics.effects and math.sin(time*.8+seed)*.012 or 0
 g.scale(1+breath,1-breath)
 -- Anchoring threads extend into the route, with several smaller cross strands.
 for i=1,8 do
  local a=i*math.pi/4+.13*math.sin(seed)
  local ax,ay=math.cos(a)*168,math.sin(a)*77
  local bx,by=math.cos(a)*91,math.sin(a)*42
  g.setColor(.65,.64,.56,.24);g.setLineWidth(1)
  g.line(ax,ay,(ax+bx)*.5,(ay+by)*.5+5,bx,by)
  for j=1,2 do
   local t=j/3;local nextA=a+math.pi/4
   local r=91+77*t;local ry=42+35*t
   g.setColor(.57,.57,.52,.12)
   g.line(math.cos(a)*r,math.sin(a)*ry,math.cos(a+.38)*r*.87,math.sin(a+.38)*ry*.87,math.cos(nextA)*r,math.sin(nextA)*ry)
  end
 end
 -- An opaque, layered cocoon keeps the world and its colours concealed.
 for i=4,1,-1 do
  g.setColor(.005,.008,.012,.12);g.ellipse('fill',0,5,101+i*4,49+i*3)
 end
 g.setColor(.022,.029,.034,1);g.ellipse('fill',0,0,104,51)
 g.setColor(.055,.066,.069,1);g.ellipse('fill',0,-3,98,45)
 -- Wound silk bands follow the volume; the centre remains dark and quiet.
 for i=1,20 do
  local v=-.94+(i-1)*1.88/19;local yy=v*46
  local width=100*math.sqrt(1-v*v);local line={}
  for j=0,16 do
   local t=j/16;local xx=(t*2-1)*width
   line[#line+1]=xx;line[#line+1]=yy+math.sin(t*math.pi)*(i%2==0 and 10 or -8)
  end
  g.setColor(.62,.62,.55,.13+(i%3)*.035);g.setLineWidth(i%4==0 and 1.4 or .8);g.line(line)
 end
 for _,direction in ipairs({-1,1}) do
  for i=-2,2 do
   g.setColor(.77,.72,.57,.16);g.setLineWidth(1)
   g.line(-86,-direction*26+i*3,-38,direction*8+i*2,12,direction*19+i*2,85,direction*30+i*2)
  end
 end
 -- A small silk seal replaces the old question mark.
 g.setColor(.025,.032,.035,.97);g.circle('fill',0,0,16)
 g.setColor(.73,.67,.49,.65);g.setLineWidth(1)
 g.polygon('line',0,-12,9,0,0,12,-9,0)
 g.line(0,-8,0,8,-5,0,5,0)
 g.pop()
end
return C
