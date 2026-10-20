local S={}
function S.migrate(data)
 if not data or data.abyssSequence==3 or not data.levels then return data end
 local json=require('json');local old=data.levels
 if data.abyssSequence~=2 then
 for n=6,8 do
  local source=old['7:'..(n+1)]
  if source then local copy=json.decode(json.encode(source));copy.level=n;old['7:'..n]=copy else old['7:'..n]=nil end
 end
 old['7:9']={world=7,level=9,width=960,height=600,entities={{kind='spawn',x=170,y=300},{kind='tear',x=710,y=310}}}
 end
 local gate=old['7:9']
 if gate and gate.entities then
  local hasHead=false
  for _,e in ipairs(gate.entities) do if e.kind=='abyss_gate' then hasHead=true end end
  if not hasHead then
   gate.entities[#gate.entities+1]={kind='abyss_gate',x=105,y=300,w=540,h=648}
   -- Move only the old generated approach, preserving authored placements.
   for _,e in ipairs(gate.entities) do
    if e.kind=='spawn' and e.x==170 and e.y==300 then e.x=gate.width-170 end
    if e.kind=='tear' and e.x==710 and e.y==310 then e.x=202.2;e.y=350 end
   end
  end
 end
 data.abyssSequence=3;return data
end
return S
