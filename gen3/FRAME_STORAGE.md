# Renderer frame storage

Renderer owns reusable draw/atlas/cutaway lists, battle-prop filtering, weather
and fog contexts, forest veil colors, camera scratch and shader-bind context.
It resets map/mesh references on invalidation and release, clears lists before
reuse and explicitly writes optional fields (including nil). Camera obstruction,
actor shadow drawing and shader binding use persistent functions. The room-depth
profile is computed once per frame instead of once per shader pass.

Public `Renderer.stats` stays a distinct completed-frame snapshot. No global
pool changes WorldAdapter's actor ownership or native gameplay objects. Shader
source, visual formulas and pass order stay unchanged. WorldAdapter records and
other helpers still allocate; this is part of F4, not completion of the entire
allocation/performance audit.

`tests/gen3_frame_storage_play_test.lua` compares a supplied previous renderer
with the candidate in a private native host. Clocks and random state are frozen
and engine updates do not run between captures. It checks eight maps, four weather
modes, two viewport sizes, hidden actors and return to the field layout: 48 cases,
zero pixel difference, all visual statistics equal. The cumulative WorldRain
build counter is excluded: the two independent renderers hold different native
heightfield identities, so alternating between them legitimately rebuilds rain.
The initial strict-counter failure is retained with the diagnostic evidence.

Four alternating measurement rounds of 24 frames per renderer, after warm-up,
with Lua GC stopped during the measured loop, produced mean allocated KiB/frame:

| Scene | Before | After |
| --- | ---: | ---: |
| Viridian City | 139.37 | 135.61 |
| Oak's Lab | 97.48 | 93.97 |
| Viridian Forest | 145.73 | 141.50 |

These are transient Lua allocation deltas, not retained memory or GPU memory.
Submission/wait times were effectively unchanged (about 4–6 ms in this small
480×320 fixture); no sustained-frame-rate improvement is claimed. Native play,
battle and pending-build resize validation are separate from these captures.
Evidence: `output/oasc-frame-storage-20261008`.

## Cloud shaft allocation profile and reuse

The next native allocation profile identified CloudShafts.draw and its actor
bindings as the largest measured outdoor sources: 67–70 KiB/frame combined in
the tested city/forest. The shaft module now reuses its vertex/corner rows and
uniform payloads; it selects nearby sites once for an unchanged site catalogue
and focus position. A moving focus refills in original source order before the
same distance sort, preserving equal-distance selection. Release clears the
selection, payload and vertex pools. Growing/shrinking draw counts use explicit
mesh/uniform ranges so inactive rows cannot leak into later frames.

`tests/gen3_cloud_shaft_storage_play_test.lua` passed 60 frozen image comparisons
on city, forest, route and interior scenes; 32 had visible shafts. Every active
GPU vertex, shaft count and nearby-site/radius selection matched the old code.
The test moves the focus, returns to old positions and releases/recreates the
module. The actor material receives the same footprint through UniformState.

At rest the instrumented draw/bind functions allocated no Lua heap after warm-up.
A separate controlled moving-focus run (four alternating 32-frame batches per
variant, no engine update between frames) measured total allocated KiB/frame:

| Scene | Before shaft reuse | After shaft reuse |
| --- | ---: | ---: |
| Viridian City | 208.58 | 138.34 |
| Viridian Forest | 212.30 | 144.83 |

This is approximately 32–34% less transient Lua allocation in those fixtures.
The moving draw submission/wait times stayed near 6–7 ms; do not turn this into
an FPS gain claim. It is not a full walking simulation or a weak-GPU benchmark.
The static function profile uses inclusive allocation totals, which must not
be summed across nested stages. Both Renderer and CloudShafts are outside the
serialized scene producer; RC11/RC12 geometry payloads and fingerprints remain
unchanged. Other allocation sources, especially actor and shadow helpers,
remain open.

## Actor mesh storage

Each Renderer actor slot now keeps its CPU vertex rows alongside the existing
stream mesh. Full shadow sprites and clipped room sprites have separate slots.
The UV math, six-vertex winding, material and nine-float layout remain identical;
only the lifetime of the rows, fallback rectangle and billboard target changes.
Uploads and draw ranges specify the active count, including after a clipping
result shrinks. Empty clipping results or missing sprites/frames cannot reuse a
previous visible sprite. Renderer.release frees both meshes and their pools.
Renderer.invalidate intentionally retains these reusable actor rows, as before;
the next draw advances the frame tick and overwrites the active geometry.

Validation uses the rc.13 module as the baseline, rather than a duplicate
implementation of the new geometry. `gen3_actor_storage_play_test.lua` compares
native GPU vertex values, ranges, visibility and textures across lab, city and
Rocket actors, all four directions, walking/flip/pose variants, raised offsets,
flat/upright settings, clipped/full passes and changing clip counts. It also
checks missing graphics/frames, cut-tree scale and release/recreate.
`gen3_frame_storage_play_test.lua` additionally passed all 48 frozen full-image
comparisons (zero differing pixels, visual stats equal).

Four alternating rounds per variant, 24 measured frames after warm-up, gave:

| Scene | rc.13 KiB/frame | Pooled actors KiB/frame |
| --- | ---: | ---: |
| Viridian City | 136.27 | 86.99 |
| Oak's Lab | 94.34 | 50.26 |
| Viridian Forest | 142.20 | 83.25 |

These are total transient Lua allocation measurements in controlled 480×320
fixtures, not retained memory or an end-to-end FPS guarantee. CPU submission /
wait averages ranged from 4.1–7.1 ms before and 4.1–6.3 ms after; this short
fixture is insufficient for a sustained-frame-rate claim. Renderer is outside
the serialized scene producer, so the scene-cache payloads remain unchanged.
Evidence: `output/oasc-actor-storage-20261008`.
