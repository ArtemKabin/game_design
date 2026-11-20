# 0042: Game 3: time without learning slowly takes back up to half of what was learned

* Date: 2026-11-20
* Status: accepted
* Participants: Person A, Person B

## Context
Players could grind one station on Monday and sleep until Friday. Prüfungssicherheit should feel like something you have to keep up.

## Decision
Every game hour that is not spent learning (other actions, walking around, sleeping; a night counts as 10 h) takes 1 Prüfungssicherheit, but never more than half of what was learned this week (`FORGET_PER_HOUR`, `FORGET_MAX_SHARE` in `game_state.gd`). Learning actions and minigames that give study points do not forget. The HUD shows "vergessen -X", the week summary lists it.

## Consequences
Spreading learning over the week pays off. Players who learn nothing lose nothing below the start value.
