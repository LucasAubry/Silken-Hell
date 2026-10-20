-- One-time campaign reorder; Workshop project layouts keep their own order.
local O={}
function O.migrate(data)
 if not data or not data.levels or data.hellOrder==2 then return data end
 local levels=data.levels
 if not data.hellOrder then
 levels['2:4'],levels['2:7']=levels['2:7'],levels['2:4']
 for _,n in ipairs({4,7}) do if levels['2:'..n] then levels['2:'..n].level=n end end
 end
 levels['2:1'],levels['2:3']=levels['2:3'],levels['2:1']
 for _,n in ipairs({1,3}) do if levels['2:'..n] then levels['2:'..n].level=n end end
 data.hellOrder=2
 return data
end
return O
