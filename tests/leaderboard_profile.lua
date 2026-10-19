local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 Profile.name='Current';Profile.stats.tears=999
 local P=require('player_profile');local g=love.graphics
 local requests={};Online.request=function(path,body,callback)requests[#requests+1]={path=path,callback=callback}end
 local remote={name='Visitor',skin=2,runId='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',time=42,deaths=7}
 Online.page=function()return {scores={remote},total=1,hasMore=false},'online'end
 Online.scores=function()return {remote},'online'end
 UI.boardWorld=1;UI.boardLocal=false;UI.boardHardcore=false;UI.boardPage=1;UI.boardCountry=false;Input.active=false
 UI.mouse=function()return 350,290 end
 local canvas=g.newCanvas(1200,750)
 local function capture(name,draw)
  UI.buttons={};g.push('all');g.setCanvas(canvas);g.origin();g.clear(.015,.025,.04);draw();g.pop()
  local data=canvas:newImageData();data:encode('png',name..'.png');data:release()
 end
 App.state='rankings';capture('leaderboard-player-hover',UI.rankings)
 UI.click(350,290)
 assert(App.state=='playerProfile' and P.name=='Visitor' and P.skin==2 and P.data==nil,'Selected identity and skin appear immediately')
 assert(requests[1].path=='/v1/players/by-run/'..remote.runId,'Remote identity is resolved by run, never by nickname')
 local data={name='Visitor',skin=27,stats={tears=123,deaths=7,attempts=12,bosses=4},worlds={{world=1,completed=true}},achievements={},source='profile'}
 requests[1].callback(data,200)
 assert(P.data==data and P.data.stats.tears~=Profile.stats.tears and P.data.skin==27,'Display fetched stats and latest selected skin')
 capture('leaderboard-player-profile',P.draw)
 P.close();assert(App.state=='rankings','Return preserves leaderboard')
 -- Stale requests cannot replace another player or reopen a closed profile.
 P.open(remote);P.close();requests[2].callback(data,200);assert(P.data==nil and App.state=='rankings')
 P.open(remote);requests[3].callback({},404);assert(P.status=='Profil indisponible');P.close()
 P.open({name='Local',skin=2,time=42,deaths=7,world=1})
 assert(P.data.name=='Local' and P.data.skin==2 and P.data.stats.deaths==7 and P.data.stats.tears==nil,'Old local score never borrows current player statistics');P.close()
 UI.buttons={};assert(UI.playerTarget(remote,280,285,430,27),'Mouse highlights the player')
 UI.mouse=function()return 10,10 end
 UI.buttons={};assert(not UI.playerTarget(remote,280,285,430,27),'Hover clears outside the player')
 Input.active=true;Input.index=1;UI.buttons={};assert(UI.playerTarget(remote,280,285,430,27),'Controller focuses the same target');Input.active=false
 App.state='boards';UI.mouse=function()return 90,205 end
 capture('leaderboard-compact-hover',function()UI.board(20,100,500,false)end)
 UI.click(90,205);assert(App.state=='playerProfile' and P.name=='Visitor','Compact board click takes priority over parent panel')
 requests[4].callback(data,200);P.close();assert(App.state=='boards','Return to compact board')
 canvas:release();print('PASS leaderboard profile: hover, controller focus, both boards, selected skin, remote stats, local fallback, errors, stale callbacks and return');love.event.quit()
end
return T
