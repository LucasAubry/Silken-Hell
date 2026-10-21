local P={}
function P.draw(e,state,M,button,text,color,x,y,width,height)
 local timing=require('boss_attack_timing');local rows=timing.spec(e);local pages=math.ceil(#rows/3)
 state.attackPage=math.max(1,math.min(pages,state.attackPage or 1))
 for slot=1,3 do
  local row=rows[(state.attackPage-1)*3+slot]
  if row then
   local key=row[1];local stored=e.bossTimings and e.bossTimings[key];local value=stored or row[3]
   text(row[2]..' (s)',x+24,y+82+(slot-1)*58,18,nil,width-260)
   local label=state.input==key and state.inputText..'|' or tostring(value)..' s'
   button(label,x+width-220,y+74+(slot-1)*58,196,40,function() state.input=key;state.inputText=tostring(value);state.timingError=nil;love.keyboard.setTextInput(true) end)
  end
 end
 if state.timingError then text(state.timingError,x+24,y+254,16,{1,.5,.4},width-48) end
 if pages>1 then
  local function turn(delta) state.attackPage=(state.attackPage-1+delta)%pages+1;state.input=nil;state.timingError=nil;love.keyboard.setTextInput(false) end
  button('<',x+24,y+296,80,34,function() turn(-1) end)
  text(state.attackPage..' / '..pages,x+width/2-22,y+304,16)
  button('>',x+width-104,y+296,80,34,function() turn(1) end)
 end
 button('Par défaut',x+24,y+height-50,160,34,function() M.checkpoint();e.bossTimings=nil;M.persist();state.input=nil;state.timingError=nil;love.keyboard.setTextInput(false) end)
end
return P
