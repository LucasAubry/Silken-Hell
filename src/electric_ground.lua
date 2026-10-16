-- Authored lethal electricity shares the exact brush footprint with the editor.
local E={}
function E.contact(zones)
 if player.tunnelTravel or player.abyssHeld then return end
 local H=require('ground_holes')
 local x=player.x+(player.hitBox_offset_x or 0);local y=player.y+(player.hitBox_offset_y or 0)
 local w,h=player.hitBox_width or 30,player.hitBox_height or 24
 for _,zone in ipairs(zones) do
  local x0,y0,x1,y1=H.bounds(zone)
  if x+w>=zone.x+x0 and x<=zone.x+x1 and y+h>=zone.y+y0 and y<=zone.y+y1 then
   local nx,ny=math.ceil(w/4),math.ceil(h/4)
   for row=0,ny do for col=0,nx do
    if H.contains(zone,x+w*col/nx,y+h*row/ny) then Hazards.kill('electric_ground');return end
   end end
  end
 end
end
function E.draw(zones,time,alpha)
 if #zones==0 then return end
 local g=love.graphics;g.push('all');g.setShader()
 E.shader=E.shader or g.newShader([[
  extern float clock;
  vec4 effect(vec4 color,Image image,vec2 uv,vec2 p) {
   float wav=sin(p.x*.045+clock*2.)*5.+sin(p.x*.17-clock*5.)*2.;
   float seam=abs(mod(p.y+wav,19.)-9.5);
   float pulse=.75+.25*sin(clock*8.+p.x*.025);
   vec3 rgb=mix(vec3(.025,.10,.22),vec3(.25,.70,1.),exp(-seam*seam*.18)*pulse);
   rgb+=vec3(.65,.80,.85)*exp(-seam*seam*2.);
   return vec4(rgb,.82)*color;
  }
 ]])
 E.shader:send('clock',time or 0);g.setShader(E.shader);g.setColor(1,1,1,alpha or 1)
 for _,zone in ipairs(zones) do require('ground_holes').draw(zone) end
 g.pop()
end
return E
