# Storm drama Card

`oasc.gen3.storm-drama`, F3 option `gen3Card_stormDrama` / GEWITTERSTIMMUNG.
Default on; own `cards.stormDrama` settings: enabled, lightningLight,
lensDrops (.6), fogBands. Off quality disables it. Display resolution,
normal camera, engine data and saves are unchanged.

The generic `lighting` chain receives the atmosphere before environment light
and the shadow pass. During the first bright 26 ms of the existing deterministic
lightning pulse, this Card returns reusable copies of the atmosphere/solar rig.
Its cool 70-degree light and shadow shear use the same existing flash bearing.
The shared day/night rig is never mutated. Old additive flash fill and cloud
attenuation are suppressed only during that pulse, avoiding double illumination.
Thunder scheduling/audio remain with SkyEvents. Late secondary pulses retain
the previous lighting. This is time-based, not a render-count trigger.

Eight lens droplets have deterministic positions, descend slowly, and appear
for 2–4 seconds per 20-second period (at most 20% temporal coverage). They use
an included analytical 64x64 RGBA normal texture, two scene taps and a vector
clamp of three output pixels. Nothing is drawn outside the burst or in clear
weather. The pass receives scene color before the native battle HUD is composed.
It keeps nearest output filtering and does not resize the scene.

Three drifting, noise-bent mist bands follow the horizontal storm rain direction.
They use the existing four-sample VolumeFog integration and depth-aware resolve.
Since storm weather does not itself enable the ordinary fog-weather pass, the
Card owns an isolated VolumeFog instance through its own `StormFogPass` helper, invoked
before Finish; it releases all five fog resources when disabled. Generic
`fog.uniforms`, `fog.density`, `bindFog` seams inject the density modulation
in that isolated pass. The legacy VolumeFog module and the baked geometry cache
remain byte-identical. No consumer means byte-identical original fog source.

The owned fog pass keeps its color, light, anchor, shape, pocket and size
payloads per instance. All sixteen base uniform bindings use UniformState;
an unchanged frame sends none, while advancing only time sends the shape
vector once. Input vectors/matrices are compared by value, so in-place camera
and lighting changes still update correctly. Recompile/release invalidates
only the owned shader caches. No fog density, resolution or samples are reduced.

Remove the single StormDramaCard entry from `cards/index.lua` and all four
owned files: this document, `lib/cards/StormDramaCard.lua`, `lib/cards/StormFogPass.lua`,
`data/weather/drop-normal.png`. No other module imports this Card. The generic
lighting/fog seams remain inert. Config, presets, callbacks and owned resources
are removed on deactivate. Health reports CPU submission times and explicitly
marks GPU timer availability false; these are not GPU execution measurements.

Acceptance sources: `tests/gen3_storm_drama_test.lua` checks weather gating,
shared rig immutability, physical shadow shear, temporal duty cycle, unchanged
engine RNG, resource/config cleanup and GPU refraction/alpha bounds.
`tests/gen3_storm_drama_play_test.lua` covers 14 Medium/High scene pairs with
frozen clocks, exact non-storm equality and repeated rollback, plus separate
fog, moving-drop and directional-shadow comparisons. Release evidence belongs
in `output/oasc-storm-drama-20261008`; target hardware GPU budgets remain open.

`tests/gen3_storm_fog_uniform_test.lua` compares 44 actual GPU outputs against
the unmodified RC53 factory in `tests/fixtures/rc53`: RGBA8/HDR, odd/even sizes,
day/night/indoor tint, in-place parameter changes, altered projection/depth
scale and resource recreation. Pixels are exact; payload reuse and skipped
sends are checked independently. These counts do not establish a GPU speedup.
