# Native battle sound preparation

`BattleSoundWarm` reads the already loaded native animation tables and schedules
the engine's `Audio.prewarmSe` for the current party's moves. The first opposing
party is included at `battle.started`. No animation script is executed; cries,
move rules, volume and playback remain native.

Pan variants use the engine's existing source builder and LRU, with at most 16
extra move variants and the six common hit variants per plan. PCM, source cache
limits and playback functions are unchanged. Jobs abort if the edition or audio
pack changes before execution. Changing sound gain or mono requests a new plan.

Validation (private native FireRed QA, High, 960×640 battle canvas):

- Five complete battles: storm Thunderbolt, Ember, snow Thunderbolt, cave Hyper
  Beam and an indoor trainer. No `Audio.playSe` call over 3 ms in the final run;
  previously the measured first sound calls reached about 50–60 ms.
- Seven sound IDs, 950,544 raw channel samples exactly equal to native cold load.
- Unit checks cover label cycles, branches, sound tasks, cry exclusion, panning,
  cache budget, deduplication, event/update hooks and edition changes.

This is preparation, not a guarantee that every sound is resident: new moves,
unpredicted dynamic tasks or native cache eviction can still require native
loading. Overall frame-time acceptance and physical iPhone testing remain open.

Rollback: remove the `BattleSoundWarm.install()` line in `main.lua` and this module.
It owns no separate sound sources or persistent data and does not modify engine
source. Native hooks are owned by the mod lifecycle.
