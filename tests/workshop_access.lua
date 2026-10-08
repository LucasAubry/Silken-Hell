local T={}
function T.run()
 local A=require('workshop_access')
 local worlds={names={[1]='Terre',[7]='Abysses'},canEnter=function(id)return id==1 end}
 local bestiary={seen={},entries={{id='crab',name='Crabe'}}}
 local layout={world=7,entities={}}
 assert(not A.check(layout,worlds,bestiary),'Locked biomes cannot be tested')
 layout.world=1;assert(A.check(layout,worlds,bestiary))
 layout.entities={{kind='mob',type='crab'}};assert(not A.check(layout,worlds,bestiary))
 bestiary.seen.crab=true;assert(A.check(layout,worlds,bestiary))
 assert(A.id({kind='boss',type='skeleton_head'})=='skeleton_fish')
 assert(A.id({kind='mob',type='gull',electric=true})=='electric_gull')
 assert(A.warning({kind='mob',type='crab'},1))
 local canEnter=Worlds.canEnter;Worlds.canEnter=function()return false end
 local before=App.state;local session=App.sessionLayout
 local valid={world=1,level=1,width=1200,height=720,entities={{kind='spawn',x=100,y=100},{kind='tear',x=900,y=500}}}
 assert(not Workshop.playLayout(valid));assert(App.state==before and App.sessionLayout==session)
 Worlds.canEnter=canEnter
 assert(Audio.pick==nil and Audio.death==nil and Audio.countdown==nil,'No synthesized sounds')
 print('PASS Workshop biome and monster access, aliases, warnings, denied launch and supplied-only audio')
 love.event.quit()
end
return T
