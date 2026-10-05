# Changelog - Serial Buffer

## v0.3.0-beta - 2026-10-05

Lines now show how long the buff they'd refresh has left ("8 min"). In combat that time keeps
counting down from what was read before the pull, and the line says "expired" when the buff drops,
so you can put it back in the middle of a fight. Party and raid members who are fighting stay on
the list (strangers in combat still don't), which means the tank has a line when you pull.

Serial Buffers in the same group now talk to each other. Each one tells the group what it casts on
each class, and the options show it under the grid, in a new "Group / raid: who casts what" part:
your own Group / raid row, then one row per other Serial Buffer user in the group. /sbuff group
lists them in the chat. Nothing changes yet in what your panel offers; splitting blessings between
paladins comes next.

These messages only go to your party or raid, several clicks make a single message, and they wait
if the game blocks addon messages during a boss fight.

This is a beta: the countdown in combat hasn't been tried in game yet.

## v0.2.0 - 2026-10-05

The 0.2.0 beta, tried in a dungeon and in combat, plus two fixes for low-level players.

When the game refuses a buff with "Target is too low level", Serial Buffer now remembers it. A
level 2 mage who can't take Kings or Wisdom gets Might straight away the next time, even after a
/reload, instead of you clicking through two refusals again. It learns this per spell rank, so
learning a higher rank starts fresh, and a buff that later lands on a player it thought was too
low corrects what it had remembered.

The Group / raid row in the options no longer leaves someone with nothing. If the blessing you
picked for their class can't go on them (too low, not learned yet, or another paladin already put
it there), you're offered the next choice from that class's column.

## v0.2.0-beta - 2026-10-05

Your group and raid now come first. When you're grouped, the panel splits into Group (or Raid),
Around you, and Out of range at the bottom, so clicking the top line buffs your own people before
strangers. In dungeons and raids the list keeps working for your group instead of pausing. If the
game hides some names or buffs in there, the bottom of the panel says how many players it couldn't
read.

The panel stays up in combat. It freezes as it was when the fight started: your group's lines can
still be clicked, a line turns grey once your buff lands, and the list refreshes when combat ends.
Strangers' lines go dark and do nothing until then, and so does the "Next buff" key.

Clicking someone in your group no longer changes your target, in or out of combat.

The options have a new grid, opened from the gear icon on the panel. Each class gets a column of
buff icons; click or scroll a box to change it. Paladins get three choices per class (the first,
then the next one if it can't land), plus a Group / raid row for a single blessing per class on
your own group, the way you'd split blessings in a raid. The All column and its » button copy a
choice across every class, the arrow under a class resets it, and Reset all puts everything back.
Salvation and Light are in the grid too, off by default. Your old settings carry over.

This is a beta: combat and dungeons haven't been tried in game yet.

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
