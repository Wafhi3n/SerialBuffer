# Serial Buffer

<!-- Texte EXACT publie sur la page CurseForge (resume + description), garde ici pour que la page
     et le depot ne divergent pas. Toute retouche de la page se recopie dans ce fichier. -->

## Summary

Lists the players around you who are missing your buffs, your group first. Click the top line, or
press one key, to buff them one after another.

## Description

Buffs last an hour on Forever, so handing them out in town or at a quest hub is worth doing. The
hard part is keeping track: who's already got Arcane Intellect, and who just walked up. Serial
Buffer keeps that list.

A small panel sits on the side of your screen. It shows every friendly player in range who's
missing one of your buffs. Your group and raid come first, under their own heading, then everyone
else in the order they arrived. Click a line and
that player gets the buff, then drops off the list. The top line never moves, so you can stand
there and keep clicking it until the list is empty. If you'd rather not aim, bind a key to "Next
buff" in the game's key bindings and press it instead.

Each buff is still one click or one key press from you. WoW doesn't let an addon cast spells on
its own, so Serial Buffer lines them up and you press the button.

What it offers depends on your class:

- Mages, priests, druids and warlocks cast all their buffs on each player who doesn't have them, one
  after another, with no grid to set up. Two mages in a group each see who's still missing Arcane
  Intellect, and a player drops off both lists once either of them buffs him. A buff with more than
  45 minutes left counts as done, and a 10-minute buff like Thorns, Shadow Protection or Unending
  Breath with more than 2 (you can change both in the options).
- Warlocks hand out Unending Breath and Detect Invisibility, the highest rank you know.
- Shamans hand out Water Walking and Water Breathing. Both need a reagent (Fish Oil, Shiny Fish
  Scales): when you run out, that buff stops showing up and its icon turns red until you restock.
- 10-minute buffs stay in your group unless you say otherwise. Shadow Protection, Unending Breath
  and Detect Invisibility go to you and your group, and druids put Thorns on tanks only (whoever has
  the Tank role in your group, or your raid's main tank). Under the panel title, "For everyone:"
  shows a box with the icon of each of your 10-minute buffs: tick one and it goes to anyone who
  lacks it, low-level players passing by included. The same line sets the 10-minute threshold.
- Paladins put one blessing per player. For each class you pick a first, second and third choice
  (Kings, then Wisdom, then Might by default). If another paladin already gave that player the
  same blessing with more than half an hour left, you're offered the next one. You can also set a
  single blessing per class for your own group or raid.
- Mana buffs (Wisdom, Arcane Intellect, Divine Spirit) skip warriors and rogues.

For a paladin, the gear icon on the panel opens the options: a grid with one column per class, where
each box is a buff icon you change with a click or the mouse wheel.

Players who can't take a buff don't stay stuck at the top. If the game answers "Target is too low
level" or "A more powerful spell is already active", you're offered their next buff instead. Too
low is remembered for good, per spell rank: a level 2 player won't be offered Kings again. Players
flagged for PvP are hidden by default, since buffing them flags you too (/sbuff pvp on shows them).

You'll need friendly player nameplates turned on (Options, Nameplates): that's how the addon sees
the people around you. In dungeons and raids the game blocks friendly nameplates, so only your
group is listed there. In combat the panel stays up but freezes: you can still click your group's
lines to rebuff them, and it refreshes when the fight ends. Each line shows how long its buff has
left ("8 min"), and that keeps counting down during a fight until it says "expired".

If other people in your group run Serial Buffer too, you'll see what they cast on each class, under
the grid in the options ("Group / raid: who casts what"), and /sbuff group lists them in the chat.
Paladins split their blessings on their own: whoever joined the group first keeps their pick, and
the others move to their next choice for that class instead of casting the same blessing twice.

Clicking a stranger's line targets them, and they stay targeted afterwards. Clicking someone in
your group leaves your target alone.

Commands: /sbuff shows or hides the panel, /sbuff options opens the settings, /sbuff pvp on (or off)
shows or hides PvP-flagged players, /sbuff group lists the other Serial Buffers in your group.
Typed alone, /sbuff pvp tells you the current setting and changes nothing.

The only thing that goes over the network is what you cast on each class, sent to your own party
or raid as addon messages. Nobody gets a whisper or a chat line. Built for WoW: Forever (Camelot).
English, French, German and Spanish.
