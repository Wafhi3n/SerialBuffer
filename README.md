# Serial Buffer

A WoW: Forever addon that lists the players around you who are missing your buffs, in the order
they showed up. Click the top line, or press the "Next buff" key, to buff them one after another.

Get it on CurseForge: https://www.curseforge.com/wow/addons/serial-buffer

Commands: `/sbuff` (show or hide the panel), `/sbuff options`, `/sbuff pvp [on|off]`, `/sbuff version`.
Two-state commands typed alone show the setting and change nothing. The chat only answers what you
type; a line set for you by a group leader comes as a toast in the game's own stack, and the login
line shows once after an install or an update (rule: the public `chat-output` skill).

## Translations

Serial Buffer is written in French and comes in English, German, Spanish and Korean. The Korean
text is new and in beta. It's a first draft made without a Korean speaker, so corrections are very
welcome. On any other client language the addon shows English.

To fix a line, open `SerialBuffer_Locale_koKR.lua` on GitHub, click the pencil icon and change the
Korean text after the `=`. The key on the left is the French original: leave it as it is. The
comment at the end of each line gives the English. Keep every `%s` and `%d`, in the same order,
then click "Propose changes" to open a pull request. The other language files work the same way.
If you'd like to add a new language, open an issue first.

## For developers

The specification is in `docs/specs/serial-buffer.md`, and what has been seen working in game is
logged in `docs/verif-registre.md` (both in French).
