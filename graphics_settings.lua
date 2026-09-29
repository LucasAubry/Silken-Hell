local G={quality=2,effects=true,showFPS=true,vsync=0,limit=120}
local json=require 'json'
local T=require('localization').text
function G.load()
 local data=love.filesystem.read('graphics.json');local ok,v=pcall(json.decode,data or '')
 if ok and type(v)=='table' then
  G.quality=math.max(1,math.min(3,tonumber(v.quality) or 2));G.effects=v.effects~=false;G.showFPS=v.showFPS~=false
  G.limit=(v.limit==0 or v.limit==60) and v.limit or 120
  G.vsync=(v.vsync==1 or v.vsync==-1) and v.vsync or 0
 end
 love.window.setVSync(G.vsync)
end
function G.save() love.filesystem.write('graphics.json',json.encode({quality=G.quality,effects=G.effects,showFPS=G.showFPS,vsync=G.vsync,limit=G.limit})) end
function G.floorHeight() return ({240,360,600})[G.quality] end
function G.backgroundHz() return G.quality==1 and 30 or 60 end
function G.pace()
 if os.getenv('SILKEN_TEST')=='1' or G.limit==0 then G.lastFrame=love.timer.getTime();return end
 local now=love.timer.getTime();local wait=1/G.limit-(now-(G.lastFrame or now))
 if wait>0 then love.timer.sleep(wait) end
 G.lastFrame=love.timer.getTime()
end
function G.draw()
 local U=UI;U.panel(305,95,590,565);U.text(T('Graphismes'),340,125,'heading')
 U.text(T('Choisis le rendu qui reste fluide sur ton écran.'),340,174,'small',{.7,.8,.8})
 U.button(T('Qualité : %s',T(({'Légère','Équilibrée','Élevée'})[G.quality])),340,215,520,45,function() G.quality=G.quality%3+1;G.save() end)
 U.button(T('Lumières décoratives : %s',T(G.effects and 'activées' or 'désactivées')),340,280,520,45,function() G.effects=not G.effects;G.save() end)
 U.button(T('Synchronisation verticale : %s',T(({[-1]='adaptative',[0]='désactivée',[1]='activée'})[G.vsync])),340,345,520,45,function()
  G.vsync=G.vsync==0 and 1 or G.vsync==1 and -1 or 0;love.window.setVSync(G.vsync);G.save()
 end)
 U.button(T('Compteur FPS : %s',T(G.showFPS and 'visible' or 'masqué')),340,410,520,45,function() G.showFPS=not G.showFPS;G.save() end)
 U.button(T('Limite FPS : %s',G.limit==0 and T('sans limite') or tostring(G.limit)),340,475,520,45,function() G.limit=G.limit==120 and 60 or G.limit==60 and 0 or 120;G.save() end)
 U.text(T('En cas de ralentissements : qualité légère et lumières désactivées.\nLa lumière nécessaire au combat des abysses reste active.'),340,534,'small',{.65,.77,.79},520)
 U.button('Retour',340,580,520,42,function() App.state='settings' end)
end
return G
