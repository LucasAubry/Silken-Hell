-- Local developer tools; the opt-in file is never included in releases.
local D={}
local json=require('json')
function D.available()
 return os.getenv('SILKEN_DEV')=='1' or love.filesystem.getInfo('dev-tools.enabled')~=nil
end
local files={'profile.txt','scores.tsv','score_details.json','hardcore-scores.json','hardcore.json','skin-grants.json','top-records.json','bestiary.json','dev-progress.enabled'}
function D.backup()
 local folder='dev-backups/'..os.date('%Y%m%d-%H%M%S')..'-'..math.floor(love.timer.getTime()*1000)
 if not love.filesystem.createDirectory(folder) then return false end
 for _,name in ipairs(files) do
  local content=love.filesystem.read(name)
  if content and not love.filesystem.write(folder..'/'..name,content) then return false end
 end
 return true
end
function D.apply(unlock)
 if not D.available() or Replay.playing then return false end
 if not D.backup() then D.status='Sauvegarde impossible';return false end
 if not unlock then
  Profile.character=1;Profile.iconBiome=nil;Profile.unlocked=1
  Profile.completed={};Profile.levels={};Profile.scores={};Profile.achievements={}
  Profile.stats={tears=0,eggs=0,deaths=0,attempts=0};Profile.biomeStats={};Profile.bossKills={}
  Profile.storyTexts={};Profile.skinGrants={};Profile.topRecords={};Profile.tearExtension=false;Profile.skinEffects={}
  Profile.progressResetAt=os.time()*1000
  Hardcore.completed={};Bestiary.seen={}
 end
 Hardcore.notice=nil
 Bestiary.unread={};Bestiary.latest=nil;Bestiary.levelFilter=nil;Bestiary.worldFilter=nil;Bestiary.dirty=true
 if unlock then
  Profile.unlocked=7
  for world in pairs(Worlds.palette) do Profile.completed[world]=true;Profile.levels[world]=Worlds.levelCount(world) end
  for _,world in ipairs(Worlds.order) do
   Hardcore.completed[tostring(world)]=true;Profile.achievements['flawless'..world]=true
   Profile.storyTexts[tostring(world)]=true
  end
  for _,a in ipairs(Achievements.list) do Profile.achievements[a.id]=true end
  for _,e in ipairs(Bestiary.entries) do Bestiary.seen[e.id]=true end
 end
 -- An artificial test profile cannot submit ranked runs.
 Profile.devProgress=unlock==true
 if unlock then love.filesystem.write('dev-progress.enabled','1') else love.filesystem.remove('dev-progress.enabled') end
 love.filesystem.write('hardcore.json',json.encode(Hardcore.completed))
 love.filesystem.write('skin-grants.json',json.encode(Profile.skinGrants or {}))
 love.filesystem.write('top-records.json',json.encode(Profile.topRecords or {}))
 Profile.save();Bestiary.save()
 Characters.browsed=nil;Characters.menuCacheKey=nil;WorldMap.hardcore=false
 Online.current=nil;UI.returnTo='menu';App.hardcore=false
 require('achievement_notice').init();require('skin_unlock').init()
 require('discovery_notice').queue={};require('discovery_notice').active=nil
 UI.bestSelected=nil;UI.devResetArmed=nil
 D.status=Profile.error or (unlock and 'Tout débloqué' or 'Progression réinitialisée')
 return not Profile.error
end
return D
