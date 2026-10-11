# Regional color script

Card `oasc.gen3.color-script`, capability `ascendant.color-script.gen3/v1`.
F3 → Render-Cards → REGIONALE FARBSTIMMUNG. Default enabled for medium/high/ultra;
low/off bypass it. Its configuration is exclusively `cards.colorScript`:
`{enabled=true,amount=.7,regions={}}`. Map overrides name one of the ten palettes
or `neutral`; unknown regions and ordinary interiors retain their existing look.

The ten day/night pairs cover Pallet/Route 1, Viridian/forest, Mt. Moon,
Cerulean, Lavender/tower, Celadon, Fuchsia/Safari, Cinnabar/Mt. Ember, Seafoam,
and Indigo. The 32³ RGB strips preserve luminance while changing chroma.
`tools/make_region_luts.py` reproducibly generates the 16-bit PNGs and checks
luminance/gamut. Existing day/night lighting, red dusk, warmth and saturation
remain in charge of brightness and time-of-day appearance. The Card does not
alter the native UI, camera, sprite filtering, resolution or geometry cache.

`prepare` selects the region; `beforeFinish` supplies an owned `lutOverride`
through the generic finish seam. Regional changes ease over 1.5 seconds. Small
1024×32 float LUT canvases snapshot the currently displayed palette, including
an interrupted blend, without a third full-screen grading stage. All 20 LUTs
load once at activation, not during map crossings. Two existing scene samplers
remain sufficient. The transition clock is `V.clock()` for deterministic QA.
`fogParams` copies existing fog parameters and adjusts color/light chroma while
preserving their luminance and density; it never adds fog to a clear scene.

The Card owns 21 textures (20 regions plus neutral), one mix shader, and at most
three 1024×32 rgba16f canvases. Unsupported float canvases or missing assets
fail closed and release partial resources. Deactivation removes hooks, config,
preset entries, the geometry-fingerprint exclusion and all owned GPU objects.
Removing the single index entry and the 22 `impact.files` removes the Card.
Neutral LUT assets matching the shipped identity use an exact bypass.

`health()` reports region, night blend, transition, resource count, `updateMs`
and `mixMs` (CPU submission times), and availability/errors. GPU timing is
explicitly unavailable on this host; CPU timings are not GPU budget approval.

Tests: `gen3_color_script_test.lua` exercises real GPU grading, luminance,
identity, interrupted transitions, fog-copy ownership, presets, RNG stability,
release and missing-asset cleanup. `gen3_color_script_play_test.lua` covers six
native maps at 06/12/20 in medium and high, all additional regions, red dusk,
fog, interiors, an unmapped route, repeated rollback and the F3 menu. `gen3_color_script_crossing_test.lua` walks across the native Route 1 → Viridian
border and verifies the full 1.5-second fade without texture reloads. The GPU
test also checks continuity at the first and interrupted blend frames. Fresh
processes with the Card disabled versus its 22 files physically removed produce
identical raw pixels. Eighteen High references are in
`tests/references/color-script/` with pinned clocks and SHA-256 metadata.
