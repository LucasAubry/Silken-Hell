-- Main-menu story and the white spider's traces along the descent.
local S={translations={},worldTranslations={},speed=18}
S.teaser='Un fil blanc. Sept mondes. Une promesse à tenir.'
S.text=[[UN FIL POUR TE RETROUVER

Vous n’étiez que deux petites araignées, et cela suffisait à faire un monde.

Puis elle est morte.

Emportée loin de toi, ta compagne s’est retrouvée prisonnière des Enfers. Il ne te restait d’elle qu’un fil blanc, trop fragile pour te guider, trop précieux pour l’abandonner.

C’est alors que la Reine des araignées est apparue. Rouge et marquée de blanc, elle t’a proposé un défi :

« Traverse les mondes. Parviens jusqu’aux Enfers. Si tu survis à cette descente, tu pourras la retrouver. »

Tu as accepté.

Ton voyage commence au Paradis. Au-delà de sa lumière t’attendent le Ciel, les profondeurs de la Terre, l’Océan, les Abysses, puis les flammes de l’Enfer.

Au début, presque rien : un fil accroché à une pierre, quelques mots gravés à l’abri d’un mur. Puis les traces se multiplient. Les toiles deviennent plus nombreuses. Sa présence se fait plus proche.

Elle est passée par là.
Elle t’a laissé des messages.
Elle espère encore que tu viendras.

Sur les bêtes, tu reconnais la même soie. Elles servent les gardiens par peur, par rage, faute de pouvoir fuir. Et les gardiens eux-mêmes portent les fils de la Gardienne.

Chaque gardien vaincu te rapproche de sa voix. Chaque monde traversé donne un sens à cette promesse : tu ne la laisseras pas seule.

Mais la Reine n’a pas encore révélé le prix du retour.

Suis le fil.]]
S.worlds={
 [1]='« J’ai noué ce premier fil pour toi. Si tu le trouves, c’est que tu ne m’as pas oubliée. »',
 [6]='« Le vent emporte presque tout. J’ai caché ces mots dans la pierre pour qu’ils restent. »',
 [5]='« Ici, sous la terre, je ne voyais plus le ciel. Alors j’ai pensé à toi pour continuer. »',
 [4]='« L’eau a effacé mes pas, mais pas mon fil. Je le laisse derrière moi. Suis-le. »',
 [7]='« Je ne vois presque plus rien. Pourtant, parfois, je crois sentir tes pas de l’autre côté du noir. »',
 [2]='« Les flammes n’ont pas brûlé ce qui nous lie. Si tu es arrivé jusque-là, retrouve-moi au-delà de la porte. »',
 [3]='« Je suis là. J’ai tellement attendu que j’ai peur de rêver encore. Approche doucement. »'
}
S.inscriptions={
 [1]='Un premier fil. Je ne t’ai pas oublié.',[6]='Ces mots resteront quand le vent se taira.',
 [5]='Dans le noir, je pensais à toi.',[4]='Suis mon fil. Je suis passée ici.',
 [7]='Tes pas me semblent si proches…',[2]='Les flammes n’ont pas brûlé notre lien.',
 [3]='Je suis là. Approche doucement.'
}
function S.localizedText()
 local language=Profile and Profile.language or 'fr'
 return S.translations[language] or require('localization').render(S.text)
end
function S.localizedWorld(world)
 local language=Profile and Profile.language or 'fr';local biome=world==8 and Campaign.biome or Worlds.biome(world)
 return (S.worldTranslations[biome] or {})[language] or require('localization').render(S.worlds[biome] or '')
end
function S.isBossLevel()
 return Worlds.isSecret(Campaign.world) or player.level==(Campaign.world==3 and 1 or 10)
end
function S.wallSpot()
 local spots={[1]={'bottom',.28},[6]={'top',.72},[5]={'left',.64},[4]={'right',.38},[7]={'bottom',.64},[2]={'top',.30},[3]={'left',.36}}
 local spot=spots[Campaign.biome] or {'bottom',.5};local side=spot[1]
 local horizontal=side=='top' or side=='bottom';local span=horizontal and Arena.width or 600
 local position=span*spot[2]
 for _,offset in ipairs({0,40,-40,80,-80,120,-120}) do
  local candidate=math.max(80,math.min(span-80,position+offset))
  local x=horizontal and candidate or side=='left' and 12 or Arena.width-12
  local y=horizontal and (side=='top' and 12 or 588) or candidate
  local bx=horizontal and x-15 or side=='left' and 22 or Arena.width-60
  local by=horizontal and (side=='top' and 22 or 540) or y-12
  if not Arena.blocked(bx,by,horizontal and 30 or 38,horizontal and 38 or 24) then return x,y,side end
 end
 return horizontal and position or (side=='left' and 12 or Arena.width-12),horizontal and (side=='top' and 12 or 588) or position,side
end
function S.atWall(x,y,side)
 side=side or (y<22 and 'top' or x<22 and 'left' or x>Arena.width-22 and 'right' or 'bottom')
 if side=='top' then return math.abs(player.x+15-x)<=22 and player.y>=y and player.y<=y+38 end
 if side=='left' then return math.abs(player.y+12-y)<=22 and player.x>=x and player.x<=x+38 end
 if side=='right' then return math.abs(player.y+12-y)<=22 and player.x+30>=x-38 and player.x+30<=x end
 return math.abs(player.x+15-x)<=22 and player.y+24>=y-38 and player.y+24<=y
end
function S.progress()
 local found,total=0,0
 for biome in pairs(S.inscriptions) do
  total=total+1
  if Profile and (Profile.storyTexts or {})[tostring(biome)]==true then found=found+1 end
 end
 return found,total
end
function S.wallAvailable()
 return App.state=='playing' and Aftermath.ready() and not require('boss_liberation').busy()
  and not App.preview and S.inscriptions[Campaign.biome]~=nil
end
function S.updateWall(dt)
 if not S.wallAvailable() or App.sessionLayout or player.reset or (Replay and (Replay.playing or Replay.ghost)) then
  S.wallKey=nil;S.nearSince=nil;S.readTime=0;return
 end
 local key=tostring(Campaign.world)..':'..tostring(player.level)
 if S.wallKey~=key then S.wallKey=key;S.nearSince=nil;S.readTime=0 end
 local x,y,side=S.wallSpot()
 if not S.atWall(x,y,side) then S.nearSince=nil;S.readTime=0;return end
 S.nearSince=S.nearSince or UI.clock
 S.readTime=(S.readTime or 0)+math.min(dt,.1)
 if S.readTime<.25 then return end
 local id=tostring(Campaign.biome)
 Profile.storyTexts=Profile.storyTexts or {}
 if Profile.storyTexts[id]~=true then Profile.storyTexts[id]=true;Profile.save() end
end
function S.drawWallMessage()
 if not S.wallAvailable() then return end
 local g=love.graphics;local x,y,side=S.wallSpot()
 local near=S.atWall(x,y,side)
 local alpha=near and S.nearSince and math.min(1,(UI.clock-S.nearSince)*4) or 0
 g.push('all');g.setShader()
 -- The wall mark is deliberately miniature; approaching it reveals readable prose.
 g.push();g.translate(x,y);if side=='left' then g.rotate(-math.pi/2) elseif side=='right' then g.rotate(math.pi/2) end
 local line=require('localization').render(S.inscriptions[Campaign.biome])
 local font=UI.fonts.body;local scale=.19;local tw=font:getWidth(line)*scale;local th=font:getHeight()*scale
 local pulse=Graphics.effects and (.8+.2*math.sin(UI.clock*2)) or 1
 local inward=side=='bottom' and -1 or 1
 g.setBlendMode('add')
 for i=12,1,-1 do
  local reach=i*3
  g.setColor(1,.72,.12,.02*pulse);g.polygon('fill',-2,0,2,0,8+reach*.16,inward*reach,-8-reach*.16,inward*reach)
 end
 for i=4,1,-1 do
  g.setColor(1,.68,.08,.04*pulse);g.ellipse('fill',0,0,tw*.5+i*1.5,th*.5+i*1.2)
 end
 g.setFont(font)
 for _,offset in ipairs({{-.5,0},{.5,0},{0,-.5},{0,.5}}) do
  g.setColor(1,.77,.15,.25*pulse);g.print(line,-tw/2+offset[1],-th/2+offset[2],0,scale,scale)
 end
 g.setBlendMode('alpha');g.setColor(1,.87,.16,1);g.print(line,-tw/2,-th/2,0,scale,scale);g.pop()
 if alpha>0 then
  local width=math.min(460,Arena.width-100);local left=math.max(35,math.min(Arena.width-width-35,x-width/2))
  local text=S.localizedWorld(Campaign.world);local _,lines=UI.fonts.body:getWrap(text,width-40)
  local height=math.max(91,#lines*UI.fonts.body:getHeight()*UI.fonts.body:getLineHeight()+30)
  local top=side=='top' and 62 or side=='bottom' and 600-height-69 or math.max(80,math.min(600-height-59,y-45))
  g.setColor(.025,.032,.045,.96*alpha);g.rectangle('fill',left,top,width,height,6)
  g.setColor(1,.76,.18,.8*alpha);g.setLineWidth(1.5);g.rectangle('line',left,top,width,height,6)
  UI.text(text,left+20,top+15,'body',{1,.87,.44,alpha},width-40,'center')
 end
 g.pop()
end
return S
