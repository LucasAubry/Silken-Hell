# Game localization

`game.json` maps authored French source text to English (`en`), Spanish (`es`),
Russian (`ru`), Portuguese (`pt`), Simplified Chinese (`zh`) and Japanese (`ja`).
French (`fr`) uses the original text. Settings also have entries in
`localization.lua`. Add every supported language when introducing new text.

The game translates at display time so changing the language does not alter
world IDs, scores, saved progress, or source descriptions. `UI.text` and
`UI.button` localize authored labels. Use `UI.rawText` and the last `raw` argument
of `UI.button` for nicknames, community map titles, and other player input.
`localization.text(source, ...)` formats translated templates; pass translated
world names as arguments when appropriate. `localization.render` also handles
legacy labels assembled from catalog fragments, without replacing partial words.
Measure translated text before wrapping or calculating scroll limits.

`story.lua` currently contains no authored story or world inscriptions. When
adding them, provide the French `text` / `worlds[id]` and either corresponding
catalog entries or `translations[language]` / `worldTranslations[id][language]`.
The story view rebuilds its scrolling text whenever the selected language changes.

Run the LÖVE localization checks with `SILKEN_TEST=1 SILKEN_LOCALIZATION_TEST=1`.
Optionally set `SILKEN_LANGUAGE_CAPTURES` to an existing directory for screenshots.
The tests use the test save identity and cover all languages, every bestiary
entry, glyph coverage, scrolling, immediate switching, and unmodified user text.
