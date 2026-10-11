# Optional prebuilt render geometry

`GeometryCache` restores local, read-only scene artifacts when an exact key and
source manifest match. It is optional: absent artifacts, unsupported engines,
changed settings/native layouts, checksum failures and decode errors fall back
to `WorldGeometry.build`. The shipping demo is switched separately after QA.
No player saves or imported cartridge data are written by the runtime cache.

Index version 2 stores payloads as `<SHA-256>.data`; each logical scene key
still maps to its expected SHA-256. Identical scenes share a file without
changing their decoded bytes. Version 1 key-named payloads remain readable.
All engine, source, native-layout and payload checks remain mandatory. The
bake tool writes version 2; convert or rebuild a legacy base before extending
it. A storage-format change alone does not justify weakening source guards.

The current validator uses the mod's existing compute permission, including on
public engines without `mod:engineFingerprint`. A finite worker verifies the
actual engine and mod source bytes asynchronously. Missing compute support or
rejected sources retain native building. Engine/mod changes require a restart,
as do loaded Lua modules. The historical engine fingerprint patch is optional.

Keys include the edition, LÖVE version, native source blobs and atlas slots,
complete map definition/layout/overrides, offset, geometry projection, instancing,
view-row preservation and geometry-relevant DioramaConfig values (see
GeometryConfig below). Unknown settings remain guarded. This prefers
safe misses to incomplete invalidation. The cache does not change existing
in-memory renderer eviction or native map-event invalidation.

The bundle must include the intended user's graphics profile. High/default QA
does not prove cache coverage or frame pacing for Ultra, tall terrain or custom
toggles. `qa_graphics_profile` applies a scalar-only fixture to private QA options;
seed that fixture before loading the mod (some settings cache their first read),
and reapply it after fixture presets. Never copy or modify a player's save to
obtain a graphics fixture. Other unbaked configurations safely use native meshing.

Records use bounded, lossless zlib envelopes (legacy LZ4 remains readable); checksums cover compressed bytes to
reduce read and hashing costs. They contain binary float32 GPU meshes and instance placements, original
float64 render metadata, contact data, heightfields, cave section triangles and
per-entry glass masks. Animated flower templates are rebuilt from the live
native frame, with matching statistics and heightfields. Non-instanced rendering
uses ordinary meshing. Cave triangle references are reconstructed in their grid;
shared cap identity matters to section deduplication. Furniture registration is
replayed for room lights, healing surfaces and actor anchors. This remaining
CPU work means a cache hit is not a guarantee of a hitch-free frame.

Baking runs in the private native-map QA host, with `qa_geometry_cache_bake` as
`QA_TOOL`, `OUT` as an existing output directory and `QA_SOURCE_LIST` containing
packaged geometry dependencies and engine source paths. Generate the list with
`python3 tools/geometry_cache_sources.py --mod <frozen-mod-root>
--engine <host-root> --output <qa-output>/sources.txt`. The tool follows complete
modules from SceneGeometry and the cache codecs/validator. It ignores Lua
comments/strings, handles the two audited dynamic builders explicitly, and
rejects unknown loader references. Mixed geometry/lighting modules remain
fully hashed; there is no fragile function-body slicing or fixed 15-file list.
Renderer shader code, PaperFinish and unrelated UI are outside the closure.
DioramaConfig is data-only and guarded by the actual projected values in each
artifact key. Each new dependency is included by the next bake, while edits to
the requiring module invalidate older indexes.

The bake hashes actual virtual engine sources in the private QA host and uses
the production validator's schema/size rules; no engine API patch is required.
It disables artifact loading while
recording. Building templates are cleared before each recorded entry so its
glass capture cannot inherit another map's panes. Generated index/data files
belong outside Git and are installed under `gen3/render-cache/` in a frozen
package. A bake is tied to its frozen package and engine, not the live worktree.

Validation:

- `gen3_render_cache_codec_test`: lossless data, malformed/truncated payloads,
  non-finite numbers, unsupported types, duplicate keys, nesting and size bounds.
- `gen3_geometry_cache_play_test`: exact GPU attributes, contacts, instance
  batches, heights/cave metadata, furniture registration and key invalidation
  against freshly built imported maps.
- `gen3_geometry_cache_fallback_test`: stale engine/mod sources, missing entries,
  corrupted/malformed records and isolated/merged glass captures.
- `qa_geometry_cache_probe`: actual renderer hits, misses, key cost and load cost.
- `qa_transition_frames`: thirteen private map-load fixtures, recording complete
  update/draw callback CPU costs and draw-to-draw wall intervals without image
  readbacks. Run separately with `QA_DISABLE_CACHE=1` and with the cache enabled,
  `LIST=''`, `CAPTURE=0`, and matching clocks/settings. It does not simulate
  walking through warps or measure GPU time directly.
- `qa_field_frame_profile` runs those same fixtures with nested native update,
  tileset animation, texture upload and mod weather/settings timings. Its nested
  durations overlap; they diagnose stalls and are not additive frame costs.

Release QA must also compare native scenes at the same camera/time, include
weather/cutaways and battle return, and cover map connection offsets. The static
426-map audit alone does not establish traversal coverage or frame pacing.
Disabling `GeometryCache.enabled`, removing the bundle, or restoring the previous
frozen mod/engine package returns to ordinary meshing.

For a demo boot fixture, create its bundled seed before applying the private
user-profile settings. `SaveData.save(seed)` also flushes the seed's embedded
options; applying a profile first can leave a mixed configuration (for example
High render resolution with tall terrain). Assert the effective render scale,
terrain height and DOF after startup, and distinguish fresh-save creation from
continue. `qa_cache_identity_probe` records the actual config/map key inputs for
private diagnostics; it never changes keys or bypasses cache guards.

## Cave-cap restore allocation

The cap decoder keeps the existing float64 format, range checks, bounds checks,
vertex order and shared grid references. It unpacks directly into locals and
constructs the three vertex arrays directly. This avoids a temporary 36-element
unpack table (including the unpack cursor) and nested table-copy loops per cap.
The explicit coordinate checks are intentional: changing them back to a
row-table loop loses much of the measured LuaJIT restore improvement.

`tools/qa_cap_restore_equivalence.lua` compares the actual private decoder in a
frozen baseline and candidate, including shared table identity. The 2026-10-06
cache fixture covers 170 records / 65 unique cap payloads / 292,774 caps, plus
malformed lengths, non-finite values in every field, range and bounds failures.
It does not prove overall map-transition latency: meshing furniture, source
fingerprints and GPU uploads are measured separately. A changed source still
requires a fresh guarded cache bake; do not re-label an old source fingerprint.

## Scoped furniture registrations

Cinnabar's Fire Gym, the Power Plant, the four Elite Four chambers and seven Tanoby chambers
now store their measured room blockers with the scene. Their builders were
reviewed for side effects: after live `Furniture.plan`, only an empty actor
anchor table, empty relief tables, healing-room binding and the room blockers
need registration. The Mansion extension is described below. Unexpected ramps, invalid actor
anchors, relief data or blocker fields prevent capture, retaining live building.

On restore, live planning still initializes family state and native quiz-gate
objects. The existing whole-layout cache key rejects changed metatiles and
configuration. `FurnitureRestore` validates identity/version, finite bounds and
supported blocker fields, then copies the boxes into freshly initialized room
state; later moving Tanoby cuts cannot mutate the persisted data. Older records
without this optional field use the ordinary live builder.

`gen3_furniture_restore_play_test.lua` exercises all 13 native layouts, compares
full blocker/anchor/ramp/relief data before and after restoration, checks malformed
records and copy ownership, checks native-edit key invalidation, and exercises
missing-field fallback in each of the four room families. Final GPU captures,
source-guard bakes and cache-load tests remain separate release requirements.

## Mansion actor anchors

The four Pokémon Mansion floors also preserve the numeric cell-to-front-plane
anchors registered by the live builder. These position paper actors against
furniture. Anchor keys must be in the map, and front planes must be positive
16-pixel boundaries within the layout. Restored tables are independent copies.
Old box-only records are accepted only for the previously audited room families;
a Mansion record without anchors is rejected and falls back to live meshing.
Unexpected ramps or relief still prevent capture.

`gen3_furniture_restore_anchors_play_test.lua` covers all 17 eligible maps and
compares actor height and paper-anchor results at every map cell, in addition
to full blocker/anchor/ramp/relief state, malformed anchors, ownership and native
edit invalidation. It also exercises live-builder fallback in all five families.
A passing functional test alone does not activate this extension: fresh guarded
cache bakes, same-camera GPU comparisons and native-event tests are required.

## Comparing bakes with native animation

A byte comparison of bakes from different runs is not automatically a geometry
regression: native sand/water/flower frames can differ at capture time. For
animated flower batches, the only allowed statistical normalization subtracts
`originalVertices * count` from `stats.vertices` and `originalVertices` from
`stats.storedVertices`, exactly matching the contribution replaced by the live
frame in `GeometryCache.restore`. Placements, dynamic descriptors and all other
fields must still match.

Static silhouette differences must not simply be ignored. The private tools
`qa_geometry_cache_fixed_frame_bake` and `qa_geometry_cache_frame_target` rebuild
both frozen runtimes with native tile animation fixed at frame zero. The latter
preserves the original map-load sequence and rebuilds only the requested key;
other maps retain ordinary guarded cache loads. Require exact paired payloads,
matching source/engine guards and matched render captures before installing the
fresh candidate entries. Keep the original failed comparison as evidence.
Directly loaded map variants can have additional keys; include only actually
rebuilt, verified entries, never re-label an old source fingerprint.

## Optional engine SHA-256

`engine-patches/cache-byte-hash.patch` adds `mod:sha256(bytes)` and
`mod:sha256Backend()`. The first accepts a byte string up to 128 MiB and returns
its SHA-256 as lowercase hexadecimal. It exposes no path, native pointer, FFI
object or filesystem operation. The mod sandbox and its denied modules remain
unchanged. Apply this after the render-cache fingerprint engine patch.

The engine's `ByteHash` uses CommonCrypto on macOS only after known-vector
self-tests; other platforms or unavailable/failing native libraries use LÖVE.
The mod's `CacheHash` also tests the bridge and falls back on older engines,
bridge failure or malformed results. Neither path skips cache integrity checks.
`GeometryCache` uses the bridge for the same byte strings as before. Source
and engine guards must include the new modules: old artifacts cannot simply
be re-labelled. Rebuild and verify fresh guarded records before release.

The headless backend microbenchmark is distinct from end-to-end map loading.
Require an actual sandbox test, payload equivalence and native transition
measurements before attributing a frame-time improvement to this change.

## Runtime preparation and exact metadata (2026-10-07)

`runtime-sprite-atlas-metadata.patch` applies after the FireRed RC1 engine
integration. Native 64×64 portraits register CPU alpha contours and occupied
height while their imported RGBA is available. Image keys are weak; retained
metadata contains neither ImageData nor RGBA. Animation frames use the same
registration. Unknown/older-engine images keep the original readback fallback.
The engine also advances `tileset.renderRevision` on animation and scripted
palette uploads. `AtlasComposite` only reuses images with that contract; older
engines compose each frame. Palette edits, native texture-ring rotation,
renderer invalidation and window/fullscreen dimensions invalidate the result.

The shared, previously uncommitted battle/main integration is kept separately
in `tools/patches/runtime-optimization-integration.patch`. It moves identity
validation and shader/foley preparation into mod loading, avoids the discarded
world-target blit when a screen override is active, and shares texture decoding
with terrarium alpha extraction. It does not replace full source fingerprints,
change cache payload geometry, or introduce an asynchronous map loader.

`tools/bake_foley.lua` generates twelve original deterministic WAV voices in a
private LÖVE QA host (`QA_REPO`, `OUT`). Add them as `gen3/data/foley/*.wav` to a
release; each WAV is decoded and checked against its original PCM. The mod
preloads the bank before play. A development checkout without these generated
files retains the prior generators. The files contain no imported game audio.

Native QA in `output/oasc-runtime-optimization-20261007`: 998 real portrait
silhouettes/metrics exactly match GPU readback (the FireRed import supplies no
extra mon-animation-sheet frames); 25 animated atlas banks/584 phases and
rollback, cache GPU/metadata parity, twelve foley voices, four complete battles,
window/menu return, and fourteen byte-identical terrarium captures. Uniform
reuse matches twelve day/night/dusk map views; instanced precipitation matches
24 GPU views. These are local regressions, not full RC/performance approval.

## Packed heights and background lookahead (2026-10-07)

Scene record version 2 stores sparse height rows as a bounded `HGT1` byte string.
Coordinates and heights remain float64, including fractional values and signed
zero. The decoder unpacks at most 128 pairs per call; duplicate/non-finite keys,
truncation, trailing bytes and excessive counts fail closed. Version 1 table
heightfields remain readable. Index versions and the OGC2 envelope are separate
versions and have not changed. A new bake emits version 2 records.

`GeometryPrefetch` uses the manifest's `compute` capability for one mod-owned,
read-only worker. It reads only hash-named payload files inside this mod's
`gen3/render-cache` directory, verifies SHA-256 and runs the same bounded envelope
and metadata decoder as the synchronous loader. Only the mod's packaged source
is executed. Cache payloads and channel messages are data, never Lua source.
No engine changes, save writes or additional imports are required. If the host
withholds threads/compute, the existing verified synchronous path remains.

The bake adds optional `index.scenes` metadata (map, offset, config fingerprint,
projection and the destination views which used that entry). `GeometryCacheLookahead` ranks nearby warp and
connection destinations using existing native definitions; it does not load
maps or switch tilesets. Compatible destination entries are queued first,
followed by their baked neighbor offsets, within the four-entry limit. Earlier
hints without `views` still support canonical destinations. Older indexes
without hints keep synchronous loading. A hint never
selects geometry for rendering: the complete native/config/layout key must
still resolve to the expected digest in `GeometryCache.load`.

The pool retains at most four records and 32 MiB of decoded *serialized* bytes;
Lua table overhead is additional, so this is not a total RAM claim. It never
waits for a worker during drawing. Late results for obsolete destinations are
discarded. A record is consumed once because flower restoration mutates its
statistics. Rapid releases wait non-blockingly for the retiring worker before
starting another. Workers stop on renderer release and normal exit. Disable
`DioramaConfig.renderCache.prefetch` to use the same artifacts synchronously;
that toggle does not invalidate their keys.

Tests cover actual worker I/O, checksum/malformed-data rejection, pool bounds,
obsolete requests, one-shot consumption, lack of thread capability, destination
ranking, config/offset filtering and bypass of main-thread read/decode for ready
records. Native QA rebuilds guarded fixture records and exercises laboratory →
Pallet → Route 1 → Viridian, plus exact GPU/height/flower/furniture restoration.
Artifacts are in `output/oasc-cache-prefetch-20261007`.

### Incremental GPU preparation

`GeometryGpuWarm` consumes verified CPU records and restores static meshes,
instance placements, packed heights, cave caps and contact meshes in a coroutine.
Checkpoints between mesh uploads and height/cap chunks share a default 2 ms CPU
submission budget. One scene is resumed per renderer draw. Individual LÖVE mesh
uploads are atomic, so this is a soft budget, not a strict GPU-time guarantee.
Four pending/ready entries retain at most 64 MiB of estimated mesh attribute
bytes; driver overhead, height/cap tables and other Lua data are additional.
Serialized mesh strings are dropped once their upload finishes.

Preparation never loads a native tileset, changes its animation bank, plans
furniture or registers room lights. `GeometryCache.load` first resolves the
full actual native/layout/config key, then claims the matching payload digest.
Only then does it rebuild flowers from the current animation frame and register
furniture/room light state. Partial entries are never drawn. Obsolete jobs and
ready entries release their meshes; renderer release and normal quit release
the entire preparation pool. `renderCache.gpuWarm=false` retains CPU prefetch;
`renderCache.prefetch=false` immediately selects the synchronous verified path.
Neither switch changes geometry keys.

If a requested scene is still uploading, the loader completes its remaining
work synchronously rather than constructing a duplicate or leaving a hole.
This is counted as `forced` separately from ready hits. Corrupt staging data,
unsupported threads, oversized records and absent hints preserve the verified
synchronous path or ordinary mesher fallback. SHA-256 is not weakened.

`gen3_geometry_gpu_warm_test` covers cancellation, one-shot ownership, forced
completion, failed restores, feature disable and resource bounds. The native
cache test compares exact GPU attributes/metadata/registrations after yielding,
forbids live-state operations during staging, and checks all five native flower
frames selected after staging. The native transition fixture in
`output/oasc-gpu-prefetch-20261007` bakes fresh source-guarded records, then tests
laboratory → Pallet → Route 1 → Viridian and Diglett's entrance → B1F, including
their visible neighbor entries. It also checks synchronous rollback.

P2 is still not a fully asynchronous map transition. Native atlas loading,
missing-cache meshing, global source validation, more than four predicted
entries and initial unpredicted destinations can still stall. A full release
needs a new all-map/profile bake and separate frame-pacing measurements; fixture
bakes and test-time image readbacks do not establish gameplay performance.

### Border CPU work (2026-10-07)

`WorldBorder` now resolves map-specific vegetation/deck profiles once per build,
memoizes tree types and FireRed terrain kinds locally, and reuses repeated
ground groups without allocating a stamping closure for every cell. FireRed's
kind classifiers read metatile/collision plus the unchanged map/profile; the
memo never crosses a build, so script and setting changes cannot reuse it.
Emerald terrain kinds retain their original per-cell path. `CaveSectionMesh`
also resolves its material profiles once and shares immutable donor UV arrays
within one collection. Triangle and spatial-grid ownership stay independent.

`gen3_border_cpu_play_test` compares a frozen baseline's actual GPU attributes,
instance order, contact data, metadata and cap grids across 15 native locations,
three positions and both instanced/non-instanced paths (90 cases), with native
edit invalidation and input immutability checks. The local diagnostic in
`output/oasc-border-cpu-20261007` includes CPU phase samples and a separate
611-interval transition run without screenshot readbacks. Its p99 interval was
21.64 ms but the maximum was 80.29 ms: remaining spikes are not resolved by this
optimization. No frame-time release approval is implied.

### Finish shader lifetime at battle resize (2026-10-07)

`PaperFinish` and `HdrBloom` now release only their render targets when size,
HDR format or mip count changes. Compiled programs survive these changes and
are released on full teardown. `Renderer.prepareShaders` warms the finish
programs; battle setup also asks the existing native palette API to prepare its
shader. No engine source or supplied engine patch changes.

The native GPU regression compared 72 resize/HDR/mip/DOF/bloom combinations
against frozen previous implementations: byte-exact output, nearest final
filter and correct full/partial cleanup. Four real battles (fire, snow/electric,
indoor trainer, cave Hyper Beam) ran through intro, moves, victory and return.
In this instrumented local run, calls over 1ms to newShader during non-setup
combat disappeared; maximum PaperFinish.apply fell from 17.982ms to 1.780ms.
These are CPU call timings, not GPU timings or a release frame-pacing pass.
Cold archive audio decoding, first sprite readbacks and GC still cause spikes;
map fixtures intentionally include cold setup work. Evidence and limitations:
`output/oasc-battle-spikes-20261007`, including raw TSV and summary.json.

### Zlib envelope (2026-10-08)

New bakes use OGC3: magic, uint32 decoded length, uint32 compressed length,
then zlib level 6 bytes. OGC2/LZ4 remains readable. Index version 2 still
content-addresses each payload by SHA-256, so duplicate geometry is stored once.
Keys are unchanged; LZ4 used to fingerprint key inputs is not a payload codec.
The shared GeometryPayload decoder is used by both synchronous restores and the
existing compute worker. Invalid lengths, truncation, checksum failures and
malformed records retain the native-mesher fallback.

Evidence: output/oasc-cache-zlib-20261008. Fifteen historical geometry records
round-tripped without a metadata change: 3,824,355 bytes LZ4 to 1,755,373 bytes
zlib (54.1% smaller). Six freshly built native scene entries matched restored
GPU attributes, heights, cave caps, contacts and furniture; all five native
flower frames stayed live. Worker cancellation/limits/checksum tests passed.
These are data and correctness tests, not gameplay frame-rate measurements.

The public 0.3.61 engine has no mod:engineFingerprint API. The previous production
validator therefore rejected prebuilt indexes there. The test verifies
that rejection; legacy fingerprint branches use a scoped QA fixture only. No
production cache is enabled by this codec change. The next section adds public-engine validation. Source dependency selection
and a fresh bake are still required before a new bundle is shipped.

### Asynchronous source validation on public engines (2026-10-08)

GeometryValidation starts one finite compute worker when a cache index exists.
The render thread reads the index and the three mod-owned worker modules, then
returns immediately. GeometryIndex validates the decoded schema, sorted engine
source paths, source sizes, SHA-256 fingerprints and content addresses inside
the worker. The fingerprint formula matches the old engine bridge exactly:
SHA-256 of concatenated `path .. NUL .. binary_sha256(source)` rows. Source
bytes remain in the worker; only the verified data index returns. No engine
patch, raw host path, downloaded code or weakened version-only check is used.

Renderer polls validation without waiting. While pending, absent, unsupported
or rejected, native cooperative builds remain available. Accepted indexes can
feed the existing prefetch/upload paths. GeometryCache.resetIndex() is the
explicit QA/reload operation; it refuses to reset while the finite worker is
running. Production never writes cache data or player saves. The manifest's
existing compute permission covers this worker.

The native regression runs on public 0.3.61 with no engineFingerprint API. It
accepts an exact fixture, rejects changed engine/mod hashes, unsafe paths and
malformed data, checks absent-file and worker-start failures, and then loads
Pallet, Oak's Lab and Diglett's Cave through native fallback. A mod-read spy
ensures no source-dependency read occurs in the main-thread validation path.
GeometryIndex's isolated test also covers duplicate/unsorted engine paths,
content-address validation and per-source limits. Evidence:
`output/oasc-cache-zlib-20261008/public-validation.log`. This proves the validator,
not a complete production cache, all-map coverage or release frame pacing.

### Presentation settings and geometry keys (2026-10-08)

GeometryConfig omits only audited presentation settings from artifact keys:
post-processing, clock policy, cache-loader policy, selected menu/preset controls,
render resolution, runtime light/firefly budgets, hemisphere/transmission,
sprite rim and aerial/god-ray controls. Baked facade shading, room bounce,
lamp placement and every unknown field remain guarded. Card namespaces remain
in the key because a future card may alter contact meshes or other baked data.
This projection does not change or remove the actual runtime settings.

The quality-preset audit also excludes `settings.shadowScale`,
`settings.shadowSoftness`, `shadows.enabled` and `fireflies.count`: these are
consumed by runtime shadow/particle preparation, not SceneGeometry. The other
fields in those namespaces still invalidate artifacts. On the public 0.3.61
host, low/medium/high/ultra produced identical keys and packed scene artifacts
at six locations (27 cross-preset comparisons). See
`tests/gen3_geometry_quality_play_test.lua` and
`output/oasc-cache-coverage-20261008/public-config.log`. Terrain height,
projection and camera elevation remain distinct geometry configurations.

Shallow snapshots still detect nested edits, replacements and signed-zero
changes. Six native locations (11 scene entries) produced byte-identical packed
artifacts and keys after changing the audited presentation controls. Geometry,
unknown-field and Card changes invalidated the key. See
`tests/gen3_geometry_config_test.lua`, `tests/gen3_geometry_config_play_test.lua`
and `output/oasc-cache-dependencies-20261008/public-config.log`.
Source fingerprints are independent; a fresh source-guarded bake is still
required before this change enables any shipped cache.

### Scoped source manifests and RC10 public-engine fixture (2026-10-08)

SceneGeometry owns the unchanged artifact-producing body formerly in Renderer.
The frozen native fixture resolves 358 complete mod modules; mixed geometry /
lighting helpers are deliberately retained. It also checks 1,917 public engine
Lua files (about 45 MB combined), asynchronously. Validation time varied under
local QA load; the final warm run took 3.48 s, an earlier pass 19.48 s, and two
initial wait-limited runs timed out. Startup validation latency remains a
profiling item, not a claimed constant or an approved frame-time budget.

Two private configuration fingerprints produced 28 logical entries sharing
14 payloads. Eight locations (Oak's Lab, Pallet, Route 1, Viridian, Viridian
Forest, Diglett's B1F, Celadon and Saffron) matched fresh native rendering at
zero pixel tolerance. After a graphics-profile change, the old key correctly
missed; the second fresh bake restored coverage without relabelling old keys.
The final lab → Pallet → Route 1 → Viridian traversal used CPU prefetch and
incremental GPU preparation. Four native battles, F3 field/battle/return and
pending-build resize also passed. Evidence: output/oasc-cache-dependencies-20261008.

These RC10 fixtures did not provide all-map or all-profile coverage. The full bake,
startup-validation latency and end-to-end frame-pacing measurements remain
release work. `tests/gen3_geometry_sources_play_test.lua` is the reusable native
pixel check; `tests/geometry_cache_sources_test.py` tests conservative traversal
and rejection of unreviewed dynamic loader references.

### Full FireRed inventory for RC11 (2026-10-08)

The new bake covers all 425 imported FireRed maps and the public engine's
generated Union Plaza, at 50-degree perspective with both normal and tall
terrain. Low/medium/high/ultra share these scene artifacts. Other elevations,
projection modes, geometry changes and script-modified layouts still miss
safely and use the cooperative native builder.

The index contains 1,506 logical entries (including connected-map offsets),
deduplicated to 1,038 zlib payloads totaling 216,092,326 bytes. A fresh native
process validated the sources and restored all 852 primary map/profile pairs.
Twenty-nine frozen full-render comparisons matched the native build exactly:
ten locations in both terrain profiles plus three locations on low, medium
and ultra. This includes the department-store roof, Pokemon Tower, Rock Tunnel
and Cerulean Cave. The raw rc.4 shader source remains byte-identical.

The offline bake and exhaustive restore inventory omit WorldBorder, which is
a separate camera-position cache and is not serialized by SceneGeometry.
Full-render pixel comparisons keep the real border. Therefore this cache does
not fix border stalls: the Lost Cave border was measured at roughly 7–9 s in
the first unsuppressed inventory pass, versus about 0.2 s for its room geometry.
It remains a specific follow-up, not an approved frame-time budget.

QA lessons and evidence:
- `qa_graphics_profile` now synchronizes already-read F7 rows, not just stored
  options. `gen3_graphics_fixture_test` exercises the stored/live mismatch.
  The discarded first bake used the same actual terrain for both labels.
  Its data was not relabelled or shipped; the second bake was fresh and asserts
  distinct fingerprints and a 1.5x actual cliff-height change.
- All 852 builds completed; the old final assertion expected 425 layouts per
  profile and rejected the additional generated Union Plaza. The corrected
  inventory test independently matches every ledger row to the actual engine
  catalog and validated index. All 852 subsequent primary restores passed.
- `tools/qa_geometry_cache_all.lua`, `tests/gen3_geometry_cache_inventory_test.lua`
  and `output/oasc-cache-coverage-20261008/{public-all,public-verify}.log` retain
  the build/validation evidence, including the obsolete count assertion.

This is static cache coverage, not story completion, all camera-profile
coverage or evidence of sustained 60 FPS. Windows/Linux/Steam Deck GPU budgets
and remaining render/frame-time work still require separate validation.

### Lost Cave border reuse (2026-10-08)

WorldBorder now uses the existing Diglett instancing path for `frLostWall` too.
Each template is local to one border build and keyed by rock kind plus the
center and four cardinal neighbors' metatile/collision values. These are all
shape inputs to FireRedLostCave.stamp; positions remain instance translations.
The direct path remains available when instancing is disabled.

Native RC11/candidate comparisons at three camera cells on Lost Cave entrance,
rooms 1/14 and Diglett B1F passed at zero pixel tolerance with clocks/randomness
frozen. Lost Cave border construction fell from 6.9–10.3 seconds to 34–134 ms
in that run. This measures this border build only, not total map load or FPS.
Expanded GPU triangles, cave cutaway caps and their lookup grids also matched
the direct stamping path on entrance/room14 at three cells, normal/tall terrain.
The reusable regression is `tests/gen3_lost_border_instances_play_test.lua`,
sharing the existing Diglett topology comparator.

The camera-dependent border is outside the serialized SceneGeometry artifact.
The unchanged RC11 cache source guard must still validate before packaging;
no cache fingerprint is rewritten. Evidence lives under
`output/oasc-lost-border-20261008`. Remaining frame-time spikes and GPU budgets
are separate work; this is not a sustained-60-FPS certification.

## Cooperative restore, including unfinished GPU warm-ups

The native build queue also budgets cache restoration. `GeometryCache.restore`
uses BuildBudget.check at heightfield chunks, cave caps and mesh boundaries
when called by that queue. Its partial GPU resources belong to a queue-owned
cleanup scope: error cleanup empties the same list, preventing a later cancel
from releasing them twice. A complete scene is published only after activation.
Synchronous tools keep their original synchronous behavior.

Claiming an unfinished `GeometryGpuWarm` job from the native queue now resumes
it with finite 2 ms submission budgets and yields between unfinished slices.
Cancelling that handoff drops its partial scene. After transfer, ownership passes
to the cache activation scope; old warm-up cleanup cannot free the transferred
resources. Atomic GPU uploads and compressed payload decoding still cannot be
interrupted; this is not a strict GPU-time or total-map-load guarantee.

`gen3_geometry_gpu_warm_test.lua` covers synchronous and cooperative handoffs,
cancel, failure, disable and bounded storage with double-release detection.
`gen3_cache_restore_slices_play_test.lua` compares real synchronous/queued GPU
meshes, instance placements, stats, heightfields and cave caps for Diglett,
Rock Tunnel, Viridian and Oak's Lab, then cancels partially uploaded native meshes.
In one controlled test Diglett's 100.6 ms restore became 51 slices (maximum
3.56 ms, total 103.5 ms); Rock Tunnel's 68.3 ms became 35 slices (maximum 4.47 ms).
This redistributes CPU submission work; it does not reduce total work or promise
shorter loading time. A new native cache bake is required because complete
producer modules, including restore code, are source-guarded. Existing packaged
RCs and cache source fingerprints must never be rewritten to pass that guard.
# Presentation-only Card settings

`GeometryConfig.registerPresentation(owner, namespace, fields)` declares exact
runtime-only fields within `DioramaConfig.cards[namespace]`. It does not exclude
the whole namespace: unknown fields and other Cards remain in the geometry key.
Namespace ownership is exclusive and removable via `unregisterPresentation`.
The projection version invalidates memoized configuration fingerprints even
when registration changes without a config-table mutation. Empty Card containers
are normalized away. Cards changing baked geometry must leave those settings
guarded and prove restored-versus-native geometry parity.

Changing this generic projection or its consumers still invalidates the source
guard. Generate a fresh native cache; never rewrite old source hashes to pass it.
