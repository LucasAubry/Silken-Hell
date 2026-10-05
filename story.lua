-- Main-menu story and the white spider's traces along the descent.
local S={translations={},worldTranslations={},speed=18}
S.teaser='Un fil blanc. Sept mondes. Une promesse à tenir.'
S.text=[[UN FIL POUR TE RETROUVER

Vous n’étiez que deux petites araignées, et cela suffisait à faire un monde.

Puis elle est morte.

Emportée loin de toi, ta compagne s’est retrouvée prisonnière des Enfers. Il ne te restait d’elle qu’un fil blanc, trop fragile pour te guider, trop précieux pour l’abandonner.

C’est alors que la Reine des araignées est apparue. Rouge, marquée de blanc et couronnée d’or, elle t’a proposé un défi :

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
 local language=Profile and Profile.language or 'fr';local biome=Worlds.biome(world)
 return (S.worldTranslations[biome] or {})[language] or require('localization').render(S.worlds[biome] or '')
end
function S.drawWallMessage()
 if require('boss_liberation').busy() then return end
 local final=require('final_spider')
 if not Aftermath.cleared and not (final.active and final.defeated) then return end
 local biome=Campaign.biome;local line=S.inscriptions[biome];if not line then return end
 local g=love.graphics;local x=Arena.width*.5;local width=math.min(590,Arena.width-140)
 g.push('all');g.setShader();g.setColor(.06,.065,.075,.96);g.rectangle('fill',x-width/2,577,width,22,3)
 g.setColor(.77,.76,.65,.65);g.setLineWidth(1);g.rectangle('line',x-width/2+2,579,width-4,18,2)
 g.setFont(UI.fonts.tiny);g.setColor(0,0,0,.9);g.printf(line,x-width/2+10,583,width-20,'center')
 g.setColor(.97,.92,.79,.95);g.printf(line,x-width/2+10,582,width-20,'center')
 local near=math.abs(player.x+15-x)<width/2+25 and player.y>430
 if near then
  local w=math.min(530,Arena.width-100)
  g.setColor(.025,.032,.045,.94);g.rectangle('fill',x-w/2,410,w,112,8)
  g.setColor(.84,.84,.75,.6);g.rectangle('line',x-w/2,410,w,112,8)
  UI.text('Un message d’elle',x-w/2+20,420,'small',{1,.9,.68},w-40,'center')
  UI.text(S.localizedWorld(Campaign.world),x-w/2+24,446,'body',{.94,.95,.92},w-48,'center')
 else UI.text('Elle a laissé un message sur le mur du bas.',x-240,548,'small',{.94,.93,.82},480,'center') end
 g.pop()
end
return S
