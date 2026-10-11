# Environment particles

`oasc.gen3.particles` is an optional, default-on Card. Its only registration is
`lib/cards/index.lua`. Removing that entry and its `impact.files` removes
it entirely. F3 → Cards → UMGEBUNGSPARTIKEL deactivates its hooks, releases its
atlas, shader and both meshes, and removes its configuration/preset ownership.
No engine or save data is modified. Existing atmosphere effects remain owned
by the original renderer; this Card does not patch or replace them.

`cards.particles` contains `enabled`, `budget` (hard maximum 300), `emission`
and `maps`. Low quality caps this at 80; off disables drawing. The default map
presets are route pollen (40), forest leaves (25), volcanic embers (30), electric
gym sparks (15), plus dust at actual active shafts, exterior cave warps and
smoke at surveyed native chimney mouths. Per-map overrides
are `{kind='pollen',count=40,radius=6,height=16}`; replace the maps table after
editing placement settings. Unsupported rooms have no inferred effects.

The original 128×16 RGBA atlas has eight hand-authored 16px motifs, with clear
borders: pollen, dust, ember, leaf, snowflake, steam, spark and lint. It contains
no native-game or third-party artwork. Colors come from per-instance tint.
One instanced draw uses the existing world projection and scene depth buffer,
with `lequal` depth testing and depth writes disabled. Ember/spark RGB exceeds
1 in the HDR canvas and therefore feeds the existing bloom chain. No new
fullscreen pass or shader fragment is added to the world shader.

A fixed pool of 300 reusable rows supplies deterministic, world-anchored
trajectories. Time comes from the render context; global randomness and camera
movement never spawn/reseed particles. Pollen fades at night and is suppressed
in rain/storm/snow. Snow suppresses forest leaves. Allocation and map sampling
happen on setup; steady pool updates allocate no tables. Setup cost is reported
separately. `health()` reports actual CPU `updateMs`, `drawMs`, maxima, setup cost,
counts and resource state. GPU query timing is unavailable and explicitly
reported as such. Missing instancing/failed resource creation disables only
this effect and reports the reason; it does not select the native renderer.

Native acceptance (2026-10-08): seven maps show the effect and return to exact
baseline pixels after deactivation/repeated activation. The optimized pool is
compared numerically with the frozen RC46 implementation over all eight styles,
300 particles, six times, three wind values and both placement modes (288 cases).
The seven native scenes also compare active pixels directly against that pool.
A separate cold boot with the Card's files and registration removed is compared
to a disabled boot with visual clocks frozen (NPC walking excluded).
All eight atlas motifs, foreground occlusion and HDR values >1 are checked on
the actual GPU; release frees all owned resources.

The pool computes emitter-wide phase, style, color and dimensions once per
emitter, retaining the exact per-particle arithmetic order. No particles,
update frames, resolution or effects are removed. A native alternating
before/after run (600 samples each, exactly 300 particles, high preset) measured
update medians 0.1314 → 0.1079 ms and combined update/draw medians
0.1609 → 0.1381 ms; combined p95 was 0.1893 → 0.1612 ms. These are CPU wall
measurements, not GPU queries. One candidate sample reached 0.4698 ms total,
so the strict 0.3-ms tail budget is NOT certified. Setup is unchanged and
reported separately (largest previously sampled site setup ~3 ms).
First-use graphics stalls and Steam Deck/GPU timings remain open.

The prepared map-site path now walks the precomputed site array directly;
the emitter-origin path is unchanged. All 288 numerical reference cases plus
16 wrapped-site/shared-pool cases remain exact. In an alternating RC49/candidate
native run (600 samples each, 300 particles), combined submission median fell
from 0.1347 to 0.1113 ms and p95 from 0.1568 to 0.1304 ms. Both sides stayed
below 0.3 ms in this run; this does not certify an unconditional tail bound or
target-device performance. `os.clock()` measures process CPU including worker
threads and must not be reported as the particle render thread's CPU cost.

RC56 compacts temporary walkable-cell candidates into numeric cell indices;
only selected emitter sites get coordinate tables. Selection order, all filters,
seeds and coordinates remain exact versus the RC55 archive oracle. Seven
native map setups compare every emitter/site field, including chimneys, cave
entrances and gym sources. In 60 alternating setup samples per variant, forest
median wall time fell from 0.8285 to 0.6064 ms; Route 12 from 0.5536 to
0.4855 ms. A separate GC-stopped allocation sample fell from 199.07 to
22.98 KiB for the forest and 85.15 to 18.98 KiB for Route 12. Unchanged
chimney/gym/entrance branches are not claimed faster. First-use shader
compilation was unchanged in RC56; these are setup measurements, not total frame/GPU
cost or certification of the strict 0.3-ms update/draw tail.

Resources are now prepared when the Card activates, during mod loading or an
explicit menu toggle. An off preset skips this allocation. The first visible
prepare reuses the atlas, shader and two meshes; a renderer release or a change
from an off preset retains the lazy reconstruction path. `resourceMs` reports
the latest allocation/compilation separately; it is not removed work. Failures
at each allocation stage release all partial resources and do not retry each
frame. Deactivation still releases everything, and reactivation can recover.

In 60 alternating native RC58/candidate cycles, the first prepare's median
fell from 1.4443 to 0.5013 ms (p95 13.2574 to 0.9358 ms). Candidate activation
instead took a 1.0100-ms median and 12.4163-ms p95. All 60 shader creations
moved from prepare to activation, and all 300 particle rows remained exact.
This measures timing within one process with a warmed driver cache; it is not
a cold-device boot measurement or an overall loading-time reduction. Driver
first-draw costs, map-specific setup, full-frame stalls, the strict 0.3-ms tail
and physical target-device acceptance remain open.

## Local chimney smoke (RC92)

`ChimneySmoke` recognizes native mouth tiles in Alabastia/Oak's laboratory,
Vertania, Prismania, Bill's cottage, Metarost and Laubwechselfeld. LeafGreen
uses its verified semantic tileset identity while retaining its own artwork.
The survey checked 200 Kanto/Sevii and 129 Hoenn building silhouettes; capped
vents, tanks and the abandoned power plant are not household chimneys.

Only the current map is inspected, once on map/layout/camera changes; only
candidate buildings need their native silhouette. Every 48 seconds a private,
map-seeded draw chooses zero to all heaters, with staggered 19–32 second burns
and smooth fades. Camera movement neither rerolls nor spawns extra heaters.
Snow, including automatic winter, enables all heaters. Forced clear weather
restores the normal schedule. Openings in one Fallarbor stack share a cycle;
merged terraced houses in Celadon receive independent cycles.

Each plume is frustum-culled before particle trajectories are evaluated.
Offscreen chimneys have no particle updates. Visible smoke reuses the existing
steam atlas and fixed 300/80 particle pool, without another shader or draw call.
`health()` additionally exposes chimney groups, visible/active mouths and rolls.
Map battle rendering uses the same presentation hook. No resolution, geometry,
lighting, save data or gameplay RNG is changed.

RC102 route presets compute density once at map setup from walkable cells
(`cellsPerParticle=30`, cap 300), with pollen size 2.5. Custom count-only presets
retain their exact old sites and trajectories. An optional emitter size override
changes only quad size; motion, colour, RNG and the global/Low budgets remain
unchanged. No new town emitter or per-frame map scan was added.
