-- Shared top-right cards for discoveries and achievements, below the HUD.
local C={x=808,y=94,width=365,height=77}
function C.draw(age,heading,name,detail,icon,slot)
 local a=math.max(0,math.min(1,age/.22,(3.6-age)/.35))
 local slide=(1-math.min(1,age/.28))^3+math.max(0,(age-3.25)/.35)^3
 if not require('ui_motion').enabled() then slide=0 end
 local g=love.graphics;local x,y=C.x+slide*395,C.y+(slot or 0)*87
 g.push('all');g.setShader()
 g.setColor(.012,.024,.038,.96*a);g.rectangle('fill',x,y,C.width,C.height,7)
 g.setColor(.93,.76,.39,.9*a);g.setLineWidth(1);g.rectangle('line',x,y,C.width,C.height,7)
 g.setColor(1,1,1,a);icon(x+39,y+39,a)
 local L=require('localization')
 UI.rawText(UI.ellipsize(L.render(heading),'body',275),x+73,y+14,'body',{1,.8,.42,a})
 UI.rawText(UI.ellipsize(L.render(name),'body',275),x+73,y+43,'body',{1,.97,.86,a})
 g.pop()
end
return C
