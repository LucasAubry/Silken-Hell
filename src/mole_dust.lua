local D={}
function D.draw(m)
 local g=love.graphics
            local phase,t=Realms.molePhase(m.age)
            if phase=='hidden' then g.setColor(.035,.02,.01,.45);g.ellipse('fill',m.x,m.y+8,22,10) end
            if phase=='warning' or phase=='emerge' or phase=='dig' then
                g.setColor(.085,.04,.025); g.ellipse('fill',m.x,m.y+10,23,11)
                g.setColor(.52,.33,.16); g.ellipse('line',m.x,m.y+10,25,12)
                for j=1,9 do
                    local a=j*2.4; local travel=(m.age*2+j*.13)%1
                    local r=phase=='dig' and 12+travel*23 or 27*(1-travel)
                    local y=m.y+10+math.sin(a)*r*.5-(phase=='emerge' and math.sin(travel*math.pi)*20 or 0)
                    g.setColor(.4+j%3*.07,.23,.1); g.rectangle('fill',m.x+math.cos(a)*r,y,3+j%3,3)
                end
                if phase=='warning' then g.setColor(.9,.62,.25,.6); g.ellipse('line',m.x,m.y+10,20+t*6,10+t*3) end
            end
end
return D
