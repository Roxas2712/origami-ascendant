# Native battle animation preparation

`lib/BattleAssetWarm.lua` prepares FireRed's existing ROM-extracted animation
pack through the engine's cooperative `Warm` queue. It publishes the complete
pack with `Anim.loadPack`; animation scripts and battle rules stay native.

The initial cache read, Lua compilation and metadata construction yield
separately. Image hydration then yields after each tag. This removes the
all-images-at-once load from the first attack when preparation has completed.
Lua compilation itself is synchronous: this is not a guarantee that every
startup frame meets 16.7 ms. Attack sound synthesis is a separate, unresolved
source of stalls.

If an animation starts before preparation finishes, the native loader wins.
Unpublished images are released. Missing data or image allocation errors leave
the original loader available. A discarded Warm queue releases private resources
before retrying; switching away from FireRed abandons the pending pack. No ROM,
save, animation script or engine source is written.

Rollback: remove the `BattleAssetWarm.install()` call in `gen3/main.lua` and the
module. Published images belong to the native animation host; removing this
service does not require a cache or save migration.

Validation:

- `tests/gen3_battle_asset_warm_test.lua`: partial publication, native-loader
  race, queue reset, missing/malformed data, allocation failure, edition switch.
- `tests/gen3_battle_asset_equivalence_test.lua`: private native LÖVE host,
  original loader versus prepared pack; exact metadata, RGBA and index pixels.
- Five native Bridge battles: storm, fire, snow, Diglett Cave and indoor trainer,
  including command selection, attacks, victory and return to the field.

Native evidence: `output/oasc-battle-assets-20261008` outside the repository.
The Mac run compares 293 RGBA images and 290 index images with zero differences.
This does not constitute physical iPhone testing or overall performance approval.
