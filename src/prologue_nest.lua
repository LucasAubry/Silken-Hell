-- Small silken retreat with a hollow opening, rather than a twig bird nest.
local N={}
function N.load()
 if N.image then return end
 local g=love.graphics;N.image=g.newCanvas(200,150,{dpiscale=2})
 g.push('all');g.setCanvas(N.image);g.origin();g.setShader();g.clear();g.translate(100,76)
 for i=7,1,-1 do g.setColor(.035,.04,.025,.025);g.ellipse('fill',2,15,63+i,35+i*.7) end
 -- Loose threads anchor the cocoon to the surrounding plants.
 g.setLineWidth(.6)
 for i=1,9 do
  local side=i%2==0 and 1 or -1
  g.setColor(.81,.83,.72,.18)
  g.line(side*(48+i%3*4),-23,side*(72+i%4*3),-39-i%3*5,side*(82+i%2*4),-55)
 end
 local shell=love.math.newBezierCurve({-65,13,-74,-24,-39,-59,8,-57,61,-57,75,-17,63,19}):render(5)
 local silk=g.newShader([[float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
 vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 px){
  float grain=hash(floor(px));
  float fiber=sin(px.x*.33+px.y*.53+sin(px.x*.025)*4.);
  float shade=.91+(grain-.5)*.065+fiber*.022;
  return vec4(tint.rgb*shade,tint.a);
 }]])
 g.setShader(silk)
 g.setColor(.67,.71,.61);g.polygon('fill',shell)
 g.setColor(.78,.80,.68);g.ellipse('fill',-3,-18,60,34)
 g.setColor(.84,.85,.74,.28);g.ellipse('fill',-13,-27,42,20)
 g.setShader();silk:release()
 -- The shaded mouth opens toward the clearing; the bed recedes into silk.
 g.setColor(.25,.30,.24);g.ellipse('fill',0,9,56,30)
 g.setColor(.12,.17,.14);g.ellipse('fill',0,3,49,24)
 g.setColor(.48,.53,.43);g.ellipse('fill',0,20,51,16)
 g.setColor(.67,.70,.57);g.ellipse('fill',0,26,47,10)
 for i=1,90 do
  local a=i*2.399;local x=math.cos(a)*(20+i%31);local y=-20+math.sin(a)*(12+i%17)
  if y< -8 or math.abs(x)>43 then
   g.setColor(.95,.94,.83,.18);g.setLineWidth(.5)
   g.line(love.math.newBezierCurve({x-10,y+4,x-4,y-6,x+6,y-8,x+14,y-4}):render(3))
  end
 end
 -- Soft lower lip, no hard circular rim or dense web drawn over the opening.
 for i=1,7 do
  g.setColor(.83,.85,.73,.13);g.setLineWidth(2)
  g.line(love.math.newBezierCurve({-55,22,-26,40+i*.5,29,40+i*.5,57,20}):render(4))
 end
 g.pop()
end
function N.draw(x,y)
 N.load();local g=love.graphics;g.push('all');g.setShader();g.setColor(1,1,1)
 g.setBlendMode('alpha','premultiplied');g.draw(N.image,x-100,y-76);g.pop()
end
return N
