local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;App.hardcore=false;Secret.duel=nil
 local json=require('json');local P=require('preview_bridge')
 local map={world=6,level=1,width=960,height=600,entities={{kind='spawn',x=400,y=300},{kind='tear',x=800,y=120},{kind='mob',type='cloud_beast',x=600,y=400,speed=330}}}
 App.sessionLayout=map;App.singleLevel=true;App.start(6);App.preview=true;App.historyPreview=false;P.last='reload-test'
 local updated=json.decode(json.encode(map));updated.entities[1].x=200;updated.entities[3].speed=240
 updated.environment={rain=false,lightning=false};updated.lightning={interval=3,delay=.7}
 local function save(layout,ticket)love.filesystem.write('preview-draft.json',json.encode({ticket=ticket or P.last,layout=layout}))end
 save(updated);timer=95;player.death=7;App.state='pause'
 assert(P.reload(),'Reload accepts latest editor draft')
 assert(math.abs(player.x+15-200*Arena.width/960)<.001 and math.abs(mobs[1].speed-240)<.001,'Reload applies new spawn and monster settings: '..tostring(player.x+15)..' expected '..tostring(200*Arena.width/960)..' speed '..tostring(mobs[1] and mobs[1].speed))
 assert(timer==0 and player.death==0 and App.state=='playing','Reload restarts the edited test')
 assert(not require('level_environment').active('rain') and not require('sky_weather').storm,'Reload applies environment settings')
 local loaded=App.sessionLayout
 save(updated,'another-test');assert(not P.reload() and App.sessionLayout==loaded,'Unrelated editor drafts cannot replace the current test')
 local invalid=json.decode(json.encode(updated));invalid.lightning.delay=-1;save(invalid)
 assert(not P.reload() and P.error and App.sessionLayout==loaded,'Invalid drafts keep the current test intact')
 local migrated=json.decode(json.encode(updated));migrated.environment=nil
 migrated.entities[#migrated.entities+1]={kind='rain',x=100,y=100}
 migrated.entities[#migrated.entities+1]={kind='rain',x=200,y=100}
 migrated.entities[#migrated.entities+1]={kind='lightning',x=300,y=100}
 migrated.entities[#migrated.entities+1]={kind='electric_ground',x=300,y=200,radius=20,points={0,0}}
 migrated.entities[#migrated.entities+1]={kind='lightning_zone',x=500,y=300,w=200,h=200}
 LayoutSchema.migrate(migrated);assert(LayoutSchema.validate(migrated))
 assert(migrated.environment.rain and migrated.environment.lightning,'Legacy weather becomes environment options')
 for _,e in ipairs(migrated.entities)do assert(e.kind~='rain' and e.kind~='lightning' and e.kind~='electric_ground','Individual weather objects are removed')end
 assert(#require('lightning_config').zones(migrated,960)==1,'Authored lightning zones remain available')
 save(migrated);assert(P.reload());assert(#Realms.rainSites==0,'No individual rain sites load in game')
 -- The shadow follows the creature near its body instead of floating below it.
 local shadow=Art.contactShadow;local yy
 Art.contactShadow=function(_,y) yy=y end
 require('mobs.cloud_beast').draw({x=300,y=200,phase='surface',age=0,angle=0})
 Art.contactShadow=shadow;assert(yy==205,'Cloud larva shadow stays close to its body')
 App.state='pause';P.error=nil
 local g=love.graphics;local canvas=g.newCanvas(1200,750)
 g.push('all');g.setCanvas(canvas);g.origin();UI.draw();g.pop()
 local found
 for _,b in ipairs(UI.buttons) do if b.run==P.reload then found=b end end
 assert(found,'Pause exposes the reload button')
 local pixels=canvas:newImageData();pixels:encode('png','preview-reload.png');pixels:release();canvas:release()
 migrated.entities[1].x=150;save(migrated);found.run()
 assert(math.abs(player.x+15-150*Arena.width/960)<.001,'Clicking reload applies the latest modification')
 -- A normal open game receives Tester without launching a second process.
 local previousRequest=love.filesystem.read('preview-request.json')
 App.preview=false;App.state='menu';P.last='older';P.raw='old request';P.clock=0
 love.filesystem.write('preview-request.json',json.encode({ticket='open-game-test',layout=updated}))
 P.update(.2)
 assert(App.preview and App.state=='playing' and P.last=='open-game-test','Normal game consumes editor test request')
 assert(math.abs(player.x+15-200*Arena.width/960)<.001,'Open game loads requested map')
 assert(tonumber(love.filesystem.read('preview-heartbeat.txt'))==os.time(),'Open game advertises availability to the editor')
 if previousRequest then love.filesystem.write('preview-request.json',previousRequest) else love.filesystem.remove('preview-request.json') end
 love.filesystem.remove('preview-draft.json')
 print('PASS preview reload: latest edits, validation, ticket isolation, weather migration and closer cloud shadow');love.event.quit()
end
return T
