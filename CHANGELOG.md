# Changelog - Serial Buffer

## v0.8.1 - 2026-10-17

- The group leader (or an assistant) can set your Group / raid line from their own Serial Buffer.
  Forever can hide a player's rank from addons, and when it does, Serial Buffer now turns that
  setting down instead of risking a Lua error. The rest of the time, nothing changes.

## v0.8.0 - 2026-10-16

Salvation got reworked on Forever, and Serial Buffer follows.

- Salvation is now a one-hour buff that stacks with your other blessings, and Revoke takes it off
  again. You want it on everyone but the tanks. So Salvation left the blessing grid (it would have
  replaced Kings on a player) and gets its own lines instead.
- When your group or raid has a tank (the Tank role set in the game, or your raid's main tank), a
  Salvation icon shows next to the counter. Your group's part of the panel then ends with one line
  per member missing Salvation, tanks left out. Click a line to cast it.
- With Mass Salvation (level 60) and Symbols of Kings in your bags, a class with two or more
  non-tanks gets one line instead ("Mage (3)"): one cast covers every mage in the raid. A class
  with a single non-tank still gets plain Salvation, which costs a lot less.
- A tank wearing Salvation, yours or another paladin's, gets a Revoke line at the very bottom.
- Click the Salvation icon to turn these lines off (it greys out). The choice is saved.
- When the game hides buffs (combat, battlegrounds) there are no Salvation lines at all, and the
  "Next buff" key leaves them alone in combat so you don't burn a Symbol of Kings mid-fight.
- A player who's too low for Salvation drops off its list, like with blessings.
- Not tested in game yet: Mass Salvation and the per-class lines (we only had a level 30 paladin),
  and Revoke on anyone but yourself. If something's off, the bug button in the panel files
  a ticket.

## v0.7.0 - 2026-10-16

The "Next buff" key now works in combat.

- Until now the key did nothing once a fight started, and you had to click lines with the mouse.
  Now each press buffs the next player in the list as it stood when the fight began: you, then your
  group or raid. Strangers are skipped (their lines already go dark in combat), and so are the dead.
  Once it reaches the end of the list, the key stops casting until the fight is over.
- In combat the game doesn't let an addon know whether a buff landed, so every press moves on to the
  next player. Press too early, during the global cooldown, and that player is skipped. They're back
  on the list after the fight. A press on a player who's out of range casts nothing: press again and
  the key goes to the next one.
- Someone you buff with the key gets the same treatment as a clicked line: their line greys out, and
  in a battleground they stay off the list after the fight unless they die. Tested in a battleground,
  where every press went to a different ally.
- You can still click a greyed line in combat to cast the buff again, handy when someone dies and
  gets back up mid-fight.

## v0.6.0 - 2026-10-14

Serial Buffer should now behave in battlegrounds, and you can cap how tall the panel gets.

- In a battleground the game hides buffs from addons, so Serial Buffer thought nobody had any and
  kept offering the same buff over and over. When the game hides buffs now, the list follows your
  own casts instead. Someone you buffed stays off the list until that buff should run out, then
  comes back. If they die, they're back on the list as soon as they're alive again. The bottom of
  the panel says "Buffs hidden by the game" while this is on.
- To know when a buff runs out, it uses the length it last saw on that buff outside the
  battleground. If it never saw one, it assumes an hour (10 minutes for Thorns and the other short
  buffs).
- What it can't see: buffs cast by other players, and enemy dispels. A /reload also makes it forget
  what you cast, so everyone is offered again once.
- /sbuff blind on turns this mode on by hand until your next /reload, in case the game hides buffs
  somewhere it doesn't tell the addon about. /sbuff blind off goes back to automatic.
- PvP-flagged players are still hidden by default, but once you're flagged yourself (every
  battleground, or a contested zone on a PvP realm) they're listed like everyone else. Before, a
  battleground panel showed nobody but you.
- New slider in the options, "Max rows in the panel", from 1 to 16. 16 is the old behaviour. Anyone
  past the limit is counted at the bottom ("+3 more"), and the top line still works the same way.
- Priests, mages and warlocks no longer get Might from a paladin by default: their third choice is
  empty, so a paladin whose partners already cast Kings and Wisdom on them moves on. The » button
  doesn't copy Might back to them either. You can still put it there by hand.
- "Target is too low level" refusals are learned from scratch once. A bug could blame your click for
  an error that came from another spell you cast right after, and remember it for good. A real
  refusal is learned again on the first try.
- Smaller fixes. The toast you get when your leader sets your Group / raid row now also works after a
  /reload in the middle of a fight. Your raid's main tank is recognized for Thorns in every case. And
  when the game turns down a message to your group for being sent too fast, it's sent again a moment
  later instead of being lost.

## v0.5.0 - 2026-10-11

Warlocks and shamans can use Serial Buffer now, and 10-minute buffs stop coming back the moment you
cast them.

- Warlocks get Unending Breath and Detect Invisibility (the highest rank you know). Shamans get
  Water Walking and Water Breathing, which need a reagent (Fish Oil, Shiny Fish Scales). When you
  run out, that buff isn't offered anymore and its icon turns red until you restock.
- Mages, priests and druids no longer have a grid to set up. Each of their buffs goes to anyone who
  doesn't have it, and mana buffs still skip warriors and rogues. What you set before is kept but
  no longer used, and a group leader can't set their Group / raid row anymore.
- 10-minute buffs (Thorns, Shadow Protection, and the new warlock and shaman ones) used to come
  back right after you cast them, because anything under 45 minutes counted as fading. They now
  wait until less than 2 minutes are left. You can set that between 1 and 9 minutes in the options,
  or on the line under the panel title.
- That line also decides who gets them. "For everyone:" shows a box with the icon of each of your
  10-minute buffs, unticked by default, so they go to you and your group only, and Thorns to tanks
  only (whoever has the Tank role in your group, or your raid's main tank). Tick a box to offer that
  buff to everyone around who lacks it.
- If you play a priest, note that Shadow Protection isn't offered to players around you anymore
  unless you tick its box.
- The addon no longer says "loaded" every time you log in. You get one line after installing or
  updating, and that's it. /sbuff pvp and /sbuff around typed alone now tell you the current
  setting instead of flipping it; add on or off to change it. When your group leader sets your
  Group / raid row, you get a toast instead of a chat line.
- A character too low to know any of their class buffs no longer gets "None of your buffs was
  recognized" at every login.

## v0.4.1 - 2026-10-11

Two layout fixes.

- With "Next buff" on the mouse wheel, the header spelled the key out ("[Mouse Wheel Up]") right
  over the "Group only" box. Mouse keys now show as short codes, the way action bar addons write
  them: "[WU]", "[WD]", "[M4]", with the game's own modifier in front ("s-WU"). A key that still
  doesn't fit gets cut short, and hovering it gives the full name.
- On a paladin, the bottom of the options page ran past the frame and cut "Group only" in half.
  "Show the panel" and "Show PvP-flagged players" now share a line. If a page is still too tall
  (a priest has the extra "Refresh" line), a thin scroll bar shows up on the right. The mouse wheel
  doesn't scroll the page, because it already changes the buffs in the grid.

## v0.4.0 - 2026-10-09

The first stable version since 0.2.0. It has everything from the 0.3 betas below (time left on each
line, paladins splitting their blessings, the bug report button), and these changes on top:

- Each line shows the buff's icon instead of its name, at the right edge, with the time left just
  before it. A player out of range is greyed out, the way the game's own group frames do it.
- A "Group only" box in the panel's header hides the players around you and keeps only you and
  your group or raid. It's in the options too, and /sbuff around flips it.
- Your "Next buff" key shows in the header ("[F]", or "key?" if none is set). Click it to open the
  game's Keybindings page at the Serial Buffer section.
- The group leader, or anyone in the group if you allow it in the options, can set your Group / raid
  row for you. In the options, a gold mark shows a row set to a single buff, and "+N" a row that
  casts all of them.
- Dragging the panel during a fight no longer gets the addon blocked by the game: the panel stays
  put in combat, and a drag started just before the pull finishes when the fight ends.
- Hid the panel with /sbuff and couldn't get it back? The options now have a "Show the panel
  (/sbuff)" box, and hiding the panel tells you in chat how to bring it back.

## v0.3.2-beta - 2026-10-09

Found a bug, or have an idea? Click the little blue bug next to the gear at the top of the panel, or
the button next to the title in the options (or type /sbuff bug). Pick Bug or Idea and the addon
gives you a link, already selected. Press Ctrl+C, paste it in your browser, and the GitHub form opens
with your addon and game versions filled in. Nothing about your character goes in it. No GitHub
account? The third choice gives you the addon's CurseForge page, where you can leave a comment.

## v0.3.1-beta - 2026-10-05

Paladins in the same group now split their blessings. The one who joined the group first keeps
what they picked; the others take, class by class, the first blessing from their own choices that
nobody ahead of them has already claimed. If you and an earlier paladin both put Kings first for
mages, your panel offers Wisdom to the mages in your group instead, and strangers outside the group
still get your usual column. A /reload doesn't lose you your place in the queue.

The options show your actual split at the top of "Group / raid: who casts what" ("You, after the
split"), since it can differ from the row you set. /sbuff group also says whether each other
paladin comes before or after you.

The time left on a line now rounds up like the game's own buff bar ("7 min", not "6 min"), and a
long name gets cut short instead of running under the buff name.

This is still a beta: the split needs two paladins to show, and hasn't been tried in game yet.

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
