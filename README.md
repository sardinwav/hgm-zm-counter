# HGM Compact Counter — for server owners

Original script for HGM BO2 Plutonium ZM servers.
Single pill, very top-left, shows `HGM | R <round> <time> | Z <left>`.

`Z` = alive on map + remaining to spawn (`get_round_enemy_array().size + level.zombie_total`).
Orange, red when `<= 5`. Time = engine round timer since round started, reset each round.
Colors: HGM purple, round green, zombies orange.

## Install (dedicated server / host)

1. Copy `HGM_Counter.gsc` to:
   - `...\Plutonium\storage\t6\scripts\zm\HGM_Counter.gsc`
   - or legacy path `...\Plutonium\storage\t6\raw\scripts\zm\HGM_Counter.gsc`
2. `map_restart` in console (or restart map). No compile step.
3. Done. Pill is ON by default for every player.

File is standalone. Requires only stock T6 `_zm_utility` + `_utility`.
`PrecacheShader("white")` is done in `init()`.

## Player commands (chat)

- `.hgm` or `.hc` — toggle ON/OFF for yourself only. Memory-only, default ON.
- Example feedback: `[HGM] counter ON/OFF`.

## Why it's light (vs typical counters)

- 6 HUD elems per player (bg + edge + HGM + R + time + Z). Reference CUK-style HUDs use 15-17.
- 1 thread per player + 2 level threads. No pref-file threads, no pulse threads. Timer is engine-driven (`setTimerUp`, reset only on round change) — zero per-second cost.
- `wait 0.25` (not 0.05/0.1) + `setValue` only when round/left changes. No per-frame `setText`, so no configstring overflow.
- O(1) count: `.size + level.zombie_total`. No loop over enemies to separate dogs — dogs count as zombies, which is what you want for "how many left".
- No `fs_fopen` / file IO at all.

## Tweak (2 min)

All layout in `hgm_make_hud()`:
- `bx = 10; by = 10;` — top-left anchor. Increase to move right/down.
- `bw = 158; bh = 20;` — pill size.
- `cr/cg/cb` — HGM purple `(0.68, 0.35, 1.0)`. Round = green, Z = orange, time = grey.
- `fontscale = 1.2` — set to `1.0` for even smaller.
- Low threshold in `hgm_watch()`: `if (left <= 5)` — change to 3/8 to taste.
- Poll speed: `wait 0.25` — 0.2 snappier, 0.35 lighter. Don't go below 0.1 on full servers.

## Notes / limits

- ZM only. Uses `level.round_number`, `level.zombie_total`, `get_round_enemy_array()`, `flag_wait("initial_blackscreen_passed")`.
- `hidewheninmenu = 1`, `hidewhendead = 0` — stays visible while playing, hidden in menus.
- If you already run another counter, remove it first — two pills will overlap top-left.

Made from scratch for HGM.
