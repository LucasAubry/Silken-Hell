-- Le texte sera fourni par Lucas. L'écran reste vide jusque-là.
local S={text='',worlds={},translations={},worldTranslations={},speed=24}
function S.localizedText()
    local language=Profile and Profile.language or 'fr'
    return S.translations[language] or require('localization').render(S.text)
end
function S.localizedWorld(world)
    local language=Profile and Profile.language or 'fr'
    local translations=S.worldTranslations[world] or {}
    return translations[language] or require('localization').render(S.worlds[world] or '')
end
return S
