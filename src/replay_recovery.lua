-- Verify a historical simulation against the entire recording before showing it.
local V={}
local json=require 'json'
function V.start(R,data)
 local E=require 'replay_engine';local exact=E.find(data.build)
 local engines={};if exact then engines[1]=exact end
 local others={};for _,e in ipairs(E.catalog().engines) do if not exact or e.build~=exact.build then others[#others+1]=e end end
 local stamp=tonumber(data.startedAt) or os.time()
 table.sort(others,function(a,b)
  local da,db=math.abs(a.time-stamp),math.abs(b.time-stamp)
  if da~=db then return da<db end
  if (a.reconstructed==true)~=(b.reconstructed==true) then return not a.reconstructed end
  return a.revision<b.revision
 end)
 for _,e in ipairs(others) do engines[#engines+1]=e end
 local candidates={}
 for _,e in ipairs(engines) do
  candidates[#candidates+1]={engine=e,session=data.session==true}
  if data.session==nil and data.single and data.layouts[data.world..':'..data.startLevel] then candidates[#candidates+1]={engine=e,session=true} end
 end
 local id=R.hash(data)
 local raw=love.filesystem.read('replay-engines/matches.json');local ok,matches=pcall(json.decode,raw or '{}')
 matches=ok and type(matches)=='table' and matches or {};local match=matches[id]
 if match then
  for i,c in ipairs(candidates) do if c.engine.build==match.build and c.session==match.session then
   if match.wrapper==R.build() then c.untilFrame=match.untilFrame;R.verified={id=id,choice=c};return R.play(data,c) end
   table.remove(candidates,i);table.insert(candidates,1,c);break
  end end
 end
 R.saveContext();R.recording=false;R.playing=true;R.data=data;R.paused=false;R.frame=0
 R.recovery={data=data,candidates=candidates,index=0,id=id,matches=matches};App.state='playing';R.status=''
 return true
end
local function launch(R,v,choice)
 v.matches[v.id]={build=choice.engine.build,session=choice.session,untilFrame=choice.untilFrame,wrapper=R.build()}
 love.filesystem.createDirectory('replay-engines');love.filesystem.write('replay-engines/matches.json',json.encode(v.matches))
 R.verified={id=R.hash(v.data),choice=choice}
 R.recovery=nil;R.play(v.data,choice)
end
function V.update(R)
 local v=R.recovery;if not v then return end
 if v.result then
  if os.getenv('SILKEN_REPLAY_HISTORY_TEST')=='1' then print('VERIFY '..tostring(v.candidates[v.index].engine.revision or v.candidates[v.index].engine.build)..' session='..tostring(v.candidates[v.index].session)..' frame='..(R.frame or 0)..' '..v.result) end
  if v.result=='Lecture terminée.' then
   local choice=v.candidates[v.index]
   launch(R,v,choice);return
  end
  local check=v.data.checks[(R.checkIndex or 1)-1]
  if check and (not v.best or check[1]>v.best.untilFrame) then
   local choice=v.candidates[v.index];v.best={engine=choice.engine,session=choice.session,untilFrame=check[1]}
  end
  v.result=nil;v.active=false
 end
 if not v.active then
  v.index=v.index+1
  local choice=v.candidates[v.index]
  if not choice then
   if v.best then launch(R,v,v.best)
   else R.recovery=nil;R.stop('Cette version n’a pas conservé les données nécessaires à sa restauration.') end
   return
  end
  v.active=true;v.running=true
  R.play(v.data,choice)
  v.running=false
  if v.result then return end
 end
 v.running=true
 R.update(.25,App.simulate)
 v.running=false
end
function V.draw(R)
 local g=love.graphics;g.push('all');g.origin();g.setShader();g.clear(.013,.025,.035)
 local scale=math.min(g.getWidth()/1200,g.getHeight()/750)
 g.translate((g.getWidth()-1200*scale)/2,(g.getHeight()-750*scale)/2);g.scale(scale)
 UI.buttons={};UI.text('RESTAURATION DU REPLAY',150,265,'heading',nil,900,'center')
 local v=R.recovery
 UI.text('Vérification '..v.index..' / '..#v.candidates..'  ·  '..math.floor((R.frame or 0)/v.data.frames*100)..' %',150,335,'body',nil,900,'center')
 UI.button('Annuler',450,410,300,52,function() R.stop() end)
 g.pop()
end
return V
