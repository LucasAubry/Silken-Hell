local H={}
function H.offset(t,id)return math.sin(t*36+id)*2-math.max(0,math.sin(t*5+id*.9))*5 end
return H
