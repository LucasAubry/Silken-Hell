-- Bindings use SDL gamepad names, including signed stick directions and triggers.
local P={defaults={up='axis:lefty:-',down='axis:lefty:+',left='axis:leftx:-',right='axis:leftx:+',dash='a',pause='start',bestiary='y',restartLevel='x',restartWorld='back',nextWorld='none',previousWorld='none',replaySlower='leftshoulder',replayFaster='rightshoulder'}}
local buttons={a=true,b=true,x=true,y=true,back=true,start=true,guide=true,leftstick=true,rightstick=true,leftshoulder=true,rightshoulder=true,dpup=true,dpdown=true,dpleft=true,dpright=true}
local axes={leftx=true,lefty=true,rightx=true,righty=true,triggerleft=true,triggerright=true}
function P.valid(value)
 if type(value)~='string' then return false end
 local axis,sign=value:match('^axis:(%a+):([+-])$')
 return value=='none' or buttons[value] or axis and axes[axis] and (not axis:find('trigger') or sign=='+') or false
end
function P.load(saved)
 local result={};for action,value in pairs(P.defaults) do result[action]=type(saved)=='table' and P.valid(saved[action]) and saved[action] or value end
 return result
end
function P.label(binding)
 local T=require('localization').text
 local labels={none='—',a='A',b='B',x='X',y='Y',start='Start',back='Back',guide='Guide',leftstick='L3',rightstick='R3',leftshoulder='LB / L1',rightshoulder='RB / R1',dpup='Croix ↑',dpdown='Croix ↓',dpleft='Croix ←',dpright='Croix →'}
 if labels[binding] then return T(labels[binding]) end
 local axis,sign=binding:match('^axis:(%a+):([+-])$')
 if axis=='triggerleft' then return 'LT / L2' elseif axis=='triggerright' then return 'RT / R2' end
 local arrow=axis and (axis:sub(-1)=='x' and (sign=='+' and '→' or '←') or (sign=='+' and '↓' or '↑')) or ''
 return T(axis and axis:sub(1,4)=='left' and 'Stick gauche' or 'Stick droit')..' '..arrow
end
function P.value(j,binding)
 if not j or not j:isConnected() or not binding or binding=='none' then return 0 end
 local axis,sign=binding:match('^axis:(%a+):([+-])$')
 if axis then
  local value=j:getGamepadAxis(axis)*(sign=='+' and 1 or -1)
  return math.max(0,math.min(1,(value-.2)/.8))
 end
 return j:isGamepadDown(binding) and 1 or 0
end
function P.speedBinding(binding,bindings)
 if binding==bindings.dash then return true end
 if bindings.dash~=P.defaults.dash then return false end
 local aliases={leftshoulder=true,rightshoulder=true,['axis:triggerleft:+']=true,['axis:triggerright:+']=true}
 if not aliases[binding] then return false end
 for action,value in pairs(bindings) do if value==binding and action~='replaySlower' and action~='replayFaster' then return false end end
 return true
end
function P.speedHeld(j,bindings)
 for _,binding in ipairs({bindings.dash,'leftshoulder','rightshoulder','axis:triggerleft:+','axis:triggerright:+'}) do
  if P.speedBinding(binding,bindings) and P.value(j,binding)>.125 then return true end
 end
 return false
end
function P.move(j,bindings)
 local values={}
 local dpad={up='dpup',down='dpdown',left='dpleft',right='dpright'}
 for action,button in pairs(dpad) do
  values[action]=P.value(j,bindings[action])
  -- The D-pad remains an alternative to the default stick unless reassigned.
  local assigned=false;for _,binding in pairs(bindings) do if binding==button then assigned=true end end
  if not assigned and bindings[action]==P.defaults[action] then values[action]=math.max(values[action],P.value(j,button)) end
 end
 return values.right-values.left,values.down-values.up
end
return P
