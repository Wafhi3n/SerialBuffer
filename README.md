# Serial Buffer

A WoW: Forever addon that lists the players around you who are missing your buffs, in the order
they showed up. Click the top line, or press the "Next buff" key, to buff them one after another.

Get it on CurseForge: https://www.curseforge.com/wow/addons/serial-buffer

Commands: `/sbuff` (show or hide the panel), `/sbuff options`, `/sbuff pvp [on|off]`, `/sbuff version`.
Two-state commands typed alone show the setting and change nothing. The chat only answers what you
type; a line set for you by a group leader comes as a toast in the game's own stack, and the login
line shows once after an install or an update (rule: the public `chat-output` skill).

For developers: the specification is in `docs/specs/serial-buffer.md`, and what has been seen
working in game is logged in `docs/verif-registre.md` (both in French).
