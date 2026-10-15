-- One-time campaign reorder; Workshop project layouts keep their own order.
local O={}
function O.migrate(data)
 if not data or not data.levels or data.hellOrder==1 then return data end
 local levels=data.levels
 levels['2:4'],levels['2:7']=levels['2:7'],levels['2:4']
 for _,n in ipairs({4,7}) do if levels['2:'..n] then levels['2:'..n].level=n end end
 data.hellOrder=1
 return data
end
return O
