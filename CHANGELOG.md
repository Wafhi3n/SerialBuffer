# Changelog - Serial Buffer

## v0.1.0 - 2026-10-04

First release, for WoW: Forever.

A panel on the side of your screen lists the friendly players around you who are missing one of
your buffs, plus your group and raid, in the order they showed up. Click a line, or bind a key to
"Next buff", and that player gets the buff. The top line stays put, so you can keep clicking it
until the list is empty.

Mages, priests and druids cast all their buffs on each player; a buff with more than 45 minutes
left counts as done (adjustable in /sbuff options). Paladins give one blessing per player from a
priority list you can reorder (Kings, Wisdom, Might by default), and move on to the next blessing
when another paladin's is already there with more than half an hour left. Mana buffs skip warriors
and rogues.

A player the game refuses ("Target is too low level", "A more powerful spell is already active")
leaves the list for that buff. PvP-flagged players are hidden unless you type /sbuff pvp. Needs
friendly player nameplates turned on, works outdoors, pauses in dungeons and hides in combat.
