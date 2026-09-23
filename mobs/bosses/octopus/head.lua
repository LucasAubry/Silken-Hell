-- Clip the original PNG to the mantle and eyes, following its irregular outline.
-- Texture coordinates stay unchanged; no circular mask or old arm fragments.
local H={}
local outline={627,338,613,357,606,374,589,385,583,381,576,402,574,422,551,442,538,424,533,427,525,449,503,465,480,487,463,514,451,547,442,579,438,611,442,636,452,655,470,673,492,688,495,713,510,742,529,773,550,791,576,795,581,822,598,846,604,858,616,856,626,846,639,860,653,854,666,836,676,805,700,796,721,781,737,757,747,731,752,704,772,685,791,665,805,642,811,614,808,586,800,556,787,525,771,500,753,478,733,459,720,447,717,429,712,422,704,440,689,427,679,419,674,398,668,380,663,394,647,375,638,357}
function H.draw(a,x,y,angle,scale,flash)
 if H.image~=a.image then
  local iw,ih=a.image:getDimensions();local qx,qy,qw,qh=a.quad:getViewport();local vertices={}
  for _,triangle in ipairs(love.math.triangulate(outline)) do
   for i=1,6,2 do local px,py=triangle[i],triangle[i+1];vertices[#vertices+1]={px-qx-qw/2,py-qy-qh/2,px/iw,py/ih,1,1,1,1} end
  end
  if H.mesh then H.mesh:release() end
  H.mesh=love.graphics.newMesh(vertices,'triangles','static');H.mesh:setTexture(a.image);H.image=a.image
 end
 H.shader=H.shader or love.graphics.newShader([[vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 px) {
  vec4 p=Texel(tex,uv);float l=(p.r+p.g+p.b)/3.0;
  if(!(p.r>p.g*1.25 && p.g>p.b*1.2)) p.rgb=mix(vec3(l*.95,l*.55,l*1.25),vec3(l*.48,l*.86,l*1.42),.35+.2*sin(uv.x*25.0+uv.y*19.0));
  return p*tint;
 }]])
 Art.shadow(H.mesh,x,y,angle,scale,scale)
 love.graphics.push('all');love.graphics.setShader(H.shader);love.graphics.setColor(1,1-flash,1-flash)
 love.graphics.draw(H.mesh,x,y,angle,scale,scale);love.graphics.pop()
end
return H
