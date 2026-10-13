local L={}
function L.bind()
 local g=love.graphics
 L.shader=L.shader or g.newShader([[
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 pixel) {
   return vec4(0.,0.,0.,Texel(image,uv).a*color.a);
  }
 ]])
 g.setShader(L.shader)
end
function L.question(x,y,size,alpha)
 local g=love.graphics;local font=UI.fonts.body
 local scale=math.max(1,size/90)
 g.push('all');g.setShader();g.setBlendMode('alpha');g.setColor(.92,.94,.98,alpha or 1)
 g.setFont(font);g.translate(x,y);g.scale(scale)
 g.print('?',-font:getWidth('?')/2,-font:getHeight()/2);g.pop()
end
return L
