local S={}
function S.migrate(data)
 if not data or data.abyssSequence==2 or not data.levels then return data end
 local json=require('json');local old=data.levels
 for n=6,8 do
  local source=old['7:'..(n+1)]
  if source then local copy=json.decode(json.encode(source));copy.level=n;old['7:'..n]=copy else old['7:'..n]=nil end
 end
 old['7:9']={world=7,level=9,width=960,height=600,entities={{kind='spawn',x=170,y=300},{kind='tear',x=710,y=310}}}
 data.abyssSequence=2;return data
end
return S
