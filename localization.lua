-- Authored game text is localized at display time; IDs and save data stay stable.
local L = {}
L.options = {
    {code="en", name="English"},
    {code="fr", name="Français"},
    {code="es", name="Español"},
    {code="ru", name="Русский"},
    {code="pt", name="Português"},
    {code="zh", name="中文"},
    {code="ja", name="日本語"},
}
local supported = {}
for _, option in ipairs(L.options) do supported[option.code] = true end
function L.valid(code) return supported[code] == true end
local messages = {
    ["Qualité : %s"] = {en="Quality: %s", es="Calidad: %s", ru="Качество: %s", pt="Qualidade: %s", zh="画质：%s", ja="画質：%s"},
    ["Légère"] = {en="Low", es="Baja", ru="Низкое", pt="Baixa", zh="低", ja="低"},
    ["Équilibrée"] = {en="Balanced", es="Equilibrada", ru="Среднее", pt="Equilibrada", zh="均衡", ja="標準"},
    ["Élevée"] = {en="High", es="Alta", ru="Высокое", pt="Alta", zh="高", ja="高"},
    ["Lumières décoratives : %s"] = {en="Decorative lights: %s", es="Luces decorativas: %s", ru="Декоративный свет: %s", pt="Luzes decorativas: %s", zh="装饰光效：%s", ja="装飾ライト：%s"},
    ["activées"] = {en="on", es="sí", ru="вкл.", pt="sim", zh="开", ja="オン"},
    ["désactivées"] = {en="off", es="no", ru="выкл.", pt="não", zh="关", ja="オフ"},
    ["activée"] = {en="on", es="sí", ru="вкл.", pt="sim", zh="开", ja="オン"},
    ["désactivée"] = {en="off", es="no", ru="выкл.", pt="não", zh="关", ja="オフ"},
    ["adaptative"] = {en="adaptive", es="adaptativa", ru="адаптивная", pt="adaptativa", zh="自适应", ja="適応"},
    ["Synchronisation verticale : %s"] = {en="Vertical sync: %s", es="Sincronización vertical: %s", ru="Вертикальная синхронизация: %s", pt="Sincronização vertical: %s", zh="垂直同步：%s", ja="垂直同期：%s"},
    ["Compteur FPS : %s"] = {en="FPS counter: %s", es="Contador FPS: %s", ru="Счётчик FPS: %s", pt="Contador FPS: %s", zh="帧率显示：%s", ja="FPS表示：%s"},
    ["visible"] = {en="visible", es="visible", ru="виден", pt="visível", zh="显示", ja="表示"},
    ["masqué"] = {en="hidden", es="oculto", ru="скрыт", pt="oculto", zh="隐藏", ja="非表示"},
    ["Limite FPS : %s"] = {en="FPS limit: %s", es="Límite FPS: %s", ru="Лимит FPS: %s", pt="Limite FPS: %s", zh="帧率上限：%s", ja="FPS上限：%s"},
    ["sans limite"] = {en="unlimited", es="sin límite", ru="без лимита", pt="sem limite", zh="无限制", ja="無制限"},
    ["Choisis le rendu qui reste fluide sur ton écran."] = {en="Choose graphics that run smoothly on your screen.", es="Elige gráficos fluidos para tu pantalla.", ru="Выбери плавный режим для своего экрана.", pt="Escolha gráficos que rodem bem na sua tela.", zh="选择适合屏幕的流畅画质。", ja="画面で滑らかに動く画質を選んでください。"},
    ["En cas de ralentissements : qualité légère et lumières désactivées.\nLa lumière nécessaire au combat des abysses reste active."] = {en="If the game slows down, use low quality and disable lights.\nLighting needed for the abyss fight stays on.", es="Si va lento, baja la calidad y desactiva las luces.\nLa luz necesaria para luchar en el abismo sigue activa.", ru="При замедлении снизь качество и отключи свет.\nСвет для боя в бездне останется включённым.", pt="Se ficar lento, reduza a qualidade e desligue as luzes.\nA luz necessária na batalha do abismo continua ativa.", zh="运行缓慢时，请降低画质并关闭装饰光效。\n深渊战斗所需的照明会保持开启。", ja="動作が重い場合は低画質にし、ライトをオフに。\n深淵の戦闘に必要な光は消えません。"},
    ["Paramètres"] = {en="Settings", es="Ajustes", ru="Настройки", pt="Configurações", zh="设置", ja="設定"},
    ["Langue"] = {en="Language", es="Idioma", ru="Язык", pt="Idioma", zh="语言", ja="言語"},
    ["Jeu et son"] = {en="Game & sound", es="Juego y sonido", ru="Игра и звук", pt="Jogo e som", zh="游戏与声音", ja="ゲームと音声"},
    ["Raccourcis"] = {en="Shortcuts", es="Atajos", ru="Горячие клавиши", pt="Atalhos", zh="快捷键", ja="ショートカット"},
    ["Retour"] = {en="Back", es="Volver", ru="Назад", pt="Voltar", zh="返回", ja="戻る"},
    ["Monter"] = {en="Move up", es="Subir", ru="Вверх", pt="Subir", zh="向上", ja="上へ"},
    ["Descendre"] = {en="Move down", es="Bajar", ru="Вниз", pt="Descer", zh="向下", ja="下へ"},
    ["Gauche"] = {en="Left", es="Izquierda", ru="Влево", pt="Esquerda", zh="向左", ja="左へ"},
    ["Droite"] = {en="Right", es="Derecha", ru="Вправо", pt="Direita", zh="向右", ja="右へ"},
    ["Ralentir"] = {en="Slow down", es="Ralentizar", ru="Замедление", pt="Desacelerar", zh="减速", ja="減速"},
    ["SON"] = {en="SOUND", es="SONIDO", ru="ЗВУК", pt="SOM", zh="声音", ja="音声"},
    ["Ambiance"] = {en="Ambience", es="Ambiente", ru="Окружение", pt="Ambiente", zh="环境音", ja="環境音"},
    ["Effets"] = {en="Effects", es="Efectos", ru="Эффекты", pt="Efeitos", zh="音效", ja="効果音"},
    ["Muet"] = {en="Mute", es="Silenciar", ru="Выкл.", pt="Mudo", zh="静音", ja="消音"},
    ["Graphismes"] = {en="Graphics", es="Gráficos", ru="Графика", pt="Gráficos", zh="画面", ja="グラフィック"},
    ["Manette : branchement détecté automatiquement"] = {en="Controller: automatically detected", es="Mando: detección automática", ru="Контроллер определяется автоматически", pt="Controle: detecção automática", zh="自动检测手柄连接", ja="コントローラーを自動検出"},
    ["Manette : %s"] = {en="Controller: %s", es="Mando: %s", ru="Контроллер: %s", pt="Controle: %s", zh="手柄：%s", ja="コントローラー：%s"},
    ["Touche ou bouton souris…"] = {en="Press a key or mouse button…", es="Pulsa una tecla o botón…", ru="Нажмите клавишу или кнопку…", pt="Pressione uma tecla ou botão…", zh="请按键盘或鼠标按键…", ja="キーかマウスボタンを押す…"},
    ["Appuie sur une touche…"] = {en="Press a key…", es="Pulsa una tecla…", ru="Нажмите клавишу…", pt="Pressione uma tecla…", zh="请按一个键…", ja="キーを押してください…"},
    ["Rejouer le niveau"] = {en="Retry level", es="Reintentar nivel", ru="Повторить уровень", pt="Repetir nível", zh="重试关卡", ja="レベルをやり直す"},
    ["Recommencer le monde"] = {en="Restart world", es="Reiniciar mundo", ru="Начать мир заново", pt="Reiniciar mundo", zh="重启世界", ja="ワールドをやり直す"},
    ["Monde suivant"] = {en="Next world", es="Mundo siguiente", ru="Следующий мир", pt="Próximo mundo", zh="下一个世界", ja="次のワールド"},
    ["Monde précédent"] = {en="Previous world", es="Mundo anterior", ru="Предыдущий мир", pt="Mundo anterior", zh="上一个世界", ja="前のワールド"},
    ["Pause / reprendre"] = {en="Pause / resume", es="Pausa / continuar", ru="Пауза / продолжить", pt="Pausar / continuar", zh="暂停／继续", ja="一時停止／再開"},
    ["Replay : ralentir"] = {en="Replay: slower", es="Repetición: más lenta", ru="Замедлить повтор", pt="Replay: desacelerar", zh="回放：减速", ja="リプレイ：減速"},
    ["Replay : accélérer"] = {en="Replay: faster", es="Repetición: más rápida", ru="Ускорить повтор", pt="Replay: acelerar", zh="回放：加速", ja="リプレイ：加速"},
    ["Tester avec le fantôme"] = {en="Practice with ghost", es="Practicar con fantasma", ru="Тренировка с призраком", pt="Treinar com fantasma", zh="与幽灵练习", ja="ゴーストと練習"},
    ["Plein écran : activé  ·  F11"] = {en="Fullscreen: on  ·  F11", es="Pantalla completa: sí  ·  F11", ru="Полный экран: вкл.  ·  F11", pt="Tela cheia: sim  ·  F11", zh="全屏：开  ·  F11", ja="全画面：オン  ·  F11"},
    ["Plein écran : désactivé  ·  F11"] = {en="Fullscreen: off  ·  F11", es="Pantalla completa: no  ·  F11", ru="Полный экран: выкл.  ·  F11", pt="Tela cheia: não  ·  F11", zh="全屏：关  ·  F11", ja="全画面：オフ  ·  F11"},
    ["JOUER"] = {en="PLAY", es="JUGAR", ru="ИГРАТЬ", pt="JOGAR", zh="开始游戏", ja="プレイ"},
    ["PARAMÈTRES"] = {en="SETTINGS", es="AJUSTES", ru="НАСТРОЙКИ", pt="CONFIGURAÇÕES", zh="设置", ja="設定"},
    ["HISTOIRE"] = {en="STORY", es="HISTORIA", ru="ИСТОРИЯ", pt="HISTÓRIA", zh="故事", ja="ストーリー"},
    ["BESTIAIRE"] = {en="BESTIARY", es="BESTIARIO", ru="БЕСТИАРИЙ", pt="BESTIÁRIO", zh="生物图鉴", ja="生き物図鑑"},
    ["SUCCÈS"] = {en="ACHIEVEMENTS", es="LOGROS", ru="ДОСТИЖЕНИЯ", pt="CONQUISTAS", zh="成就", ja="実績"},
    ["Reprendre"] = {en="Resume", es="Continuar", ru="Продолжить", pt="Continuar", zh="继续", ja="再開"},
    ["Quitter la partie"] = {en="Leave game", es="Salir de la partida", ru="Выйти из игры", pt="Sair da partida", zh="退出游戏", ja="ゲームを終了"},
    ["Choisis ta langue."] = {en="Choose your language.", es="Elige tu idioma.", ru="Выбери язык.", pt="Escolha seu idioma.", zh="选择语言。", ja="言語を選んでください。"},
    ["Choix enregistré automatiquement."] = {en="Your choice is saved automatically.", es="Tu elección se guarda automáticamente.", ru="Выбор сохраняется автоматически.", pt="Sua escolha é salva automaticamente.", zh="选择会自动保存。", ja="選択は自動的に保存されます。"},
    ["Rejouer un niveau lance un entraînement non classé.\nChanger de monde : entraînement uniquement, mondes débloqués."] = {en="Retrying a level starts unranked practice.\nWorld switching: practice only, unlocked worlds.", es="Reintentar inicia una práctica sin clasificación.\nCambiar de mundo: solo práctica, mundos desbloqueados.", ru="Повтор уровня запускает тренировку без рейтинга.\nСмена мира: только тренировка и открытые миры.", pt="Repetir inicia um treino sem classificação.\nTroca de mundo: só treino, mundos desbloqueados.", zh="重试关卡会开始不计排名的练习。\n切换世界：仅限练习和已解锁的世界。", ja="やり直すとランキング対象外の練習になります。\nワールド変更：練習中のみ、解放済みワールド限定。"},
}
local extra = require('json').decode(assert(love.filesystem.read('assets/locales/game.json')))
for source, translations in pairs(extra) do messages[source] = translations end
-- Legacy labels concatenate authored fragments. Match only complete catalog
-- phrases at word boundaries, longest first; never rewrite translated output.
local candidates = {}
local aliases = {}
for source, translations in pairs(messages) do
    if source:upper() ~= source then
        local row = {};for code, value in pairs(translations) do row[code] = value:upper() end
        aliases[source:upper()] = row
    end
end
for source,row in pairs(aliases) do if not messages[source] then messages[source] = row end end
for source in pairs(messages) do
    local first = source:sub(1,1)
    candidates[first] = candidates[first] or {}
    table.insert(candidates[first], source)
end
for _,list in pairs(candidates) do table.sort(list,function(a,b) return #a > #b end) end
local function word(c) return c ~= '' and (c:match('[%w_]') ~= nil or c:byte() >= 128) end
local cache, cacheSize, cacheLanguage = {}, 0, nil
function L.has(source, code) return code == 'fr' or messages[source] and messages[source][code] ~= nil or false end
function L.render(source)
    if type(source) ~= 'string' then return source end
    local code = Profile and Profile.language or 'fr'
    if code == 'fr' then return source end
    if code ~= cacheLanguage then cache,cacheSize,cacheLanguage = {},0,code end
    if cache[source] then return cache[source] end
    if messages[source] and messages[source][code] then return messages[source][code] end
    local result, i = {}, 1
    while i <= #source do
        local matched
        for _,key in ipairs(candidates[source:sub(i,i)] or {}) do
            if source:sub(i,i+#key-1) == key
                and not (word(key:sub(1,1)) and word(source:sub(i-1,i-1)))
                and not (word(key:sub(-1)) and word(source:sub(i+#key,i+#key))) then
                result[#result+1] = messages[key][code] or key
                i = i + #key;matched = true;break
            end
        end
        if not matched then result[#result+1] = source:sub(i,i);i = i+1 end
    end
    local translated = table.concat(result)
    if cacheSize >= 1024 then cache,cacheSize = {},0 end
    cache[source] = translated;cacheSize = cacheSize+1
    return translated
end
function L.text(source, ...)
    local code = Profile and Profile.language or "fr"
    local result = (messages[source] and messages[source][code]) or source
    if select("#", ...) > 0 then return string.format(result, ...) end
    return result
end
return L
