# Exact light contribution rejection

## Axis-aligned room shadow specialization (2026-10-08)

Retina battle profiling isolated the laboratory's five-ray room shadows:
full-effect frame intervals were about 28–29 ms; diagnostically removing only
room occlusion reduced them to about 16.7 ms. These are native frame intervals,
not GPU timer measurements; the host does not expose GPU queries to mods.

`RoomShadowProgram` prepares the five unchanged ray directions once per source
and receiver for axis-aligned blockers. It retains slab division, epsilon,
blocker order, per-ray minimum transmission, conservative bounds and all five
equal-weight samples. Rotated/sloped blockers select the existing general
implementation. Relief, single-ray and legacy cross sampling retain their
existing dispatch. `ActorLighting.begin` binds the specialization flag from
the current room state without changing geometry/cache dependencies. The flag
resets for every light state. No light or blocker budget is reduced.

Specialization happens only at shader compilation; `buildShaderSource()` and
the exported room shader remain unchanged. A compile failure retries the
reference shader with actor vertex lighting before trying the existing fragment
fallback. There is no new canvas, sampler, render pass or engine modification.

Private evidence: `output/oasc-retina-profile-20261008`. Real GPU comparisons
cover 72 fixtures / 73,728 receivers including zero/24 blockers, rotations,
slopes, transparency and sampling modes; maximum difference was zero. Twelve
native comparisons (six maps at 768×528 and 1920×1280) were byte-identical.
Retina laboratory command-phase intervals improved to roughly 17–19 ms in
the initial repeated runs. Outliers remain; this is not a universal 60 FPS
or Steam Deck performance approval. The normal desktop host still decides
whether its window is high-DPI; this optimization does not force Retina.

After the user-requested resolution rollback, validation was repeated at the
normal 50-degree camera setting with RC29's 960×640 battle composite. Four
complete battles (fire, snow/electric, cave Hyper Beam, indoor trainer) passed.
Twelve frozen scene comparisons at 768×528 and 960×640 are byte-identical;
the test counts both reference and specialized uniform bindings to ensure
the comparison exercises the two paths. GPU visibility tolerance is zero.

The normal-resolution ABBA laboratory run (240 warmed frames per block)
measured reference intervals of 16.662/16.660 ms and specialized intervals
of 16.649/16.668 ms (medians). Both are effectively at the 60 Hz cap; this
does not demonstrate a normal-resolution FPS increase. CPU submission medians
were 3.807/3.708 ms versus 3.762/3.441 ms, with remaining interval outliers
of 22–33 ms. Do not describe the previous Retina improvement as a gain in
the restored normal mode. Evidence: `output/oasc-room-shadow-normal-20261008`.
The initial measurement harness incorrectly asserted the feature on auxiliary
shaders; that failed run is preserved separately, not counted as acceptance.

The world shader retains the original ordered dynamic and static light sources.
It skips calculations only when a source has zero power, the fragment lies
outside its sphere, or the final outward factor (including facade bounce) is
zero. These branches precede cone, room shadow and material calculations; they
do not change attenuation, colours, source selection or window schedules.

Dynamic sources are conservatively bounded in groups of four. `LocalLights.send`
computes XZ rectangles from the actual uploaded positions and absolute radii,
expanded by one world pixel to keep floating-point boundary decisions safely
outside contributing spheres. Bounds are cached only on the current prepared
light state, which is rebuilt each frame. Terrain and actor shaders share that
state. The shader skips a complete group only outside its rectangle, preserving
source order and the first static source when the last dynamic group is partial.
Static window sources remain indexed over the entire loaded map area.

Private validation: `qa_field_draw_cost` interleaves complete-render controls
with pass exclusions, without screenshot readbacks during timing. Those
exclusions are diagnostics, never shipped quality settings. `qa_light_count_views`
compares complete indoor/outdoor renders for 19 source counts from 0 through 24,
including zero power, radial points, cones, facade bounce, wall-only lights and
non-quadratic falloff. Compare against the frozen previous renderer. Real map
captures, battle/weather integration and fresh geometry-cache bakes are separate
release checks. Shader/source changes invalidate the guarded render cache.

## Separate static loop and shared room transforms

Dynamic sources run first, then the same ordered static cell list in a separate
loop. The explicit constant `fixedSource` lets the macOS GLSL compiler eliminate
room-shadow and dynamic-uniform paths from static evaluation. The two loop bodies
intentionally retain matching material calculations; changes to shared light
response must update both. No source budget, radius, falloff, colour or sampling
quality was reduced.

Balanced room area lighting still uses the centre and four quincunx rays with
equal weights. `roomBalancedVisibility` visits each blocker once, sharing its
frame, slope and transformed receiver across five independent intersection
tests. Each ray retains its own minimum transmission and original source offset.
Authored relief, single-sample and legacy cross sampling retain the prior path.

`tools/qa_room_shadow_equivalence.lua` compares the actual baseline/candidate
shader outputs in float canvases: 72 fixtures, 73,728 receivers, 0/1/7/24 blockers,
rotations, slopes, opacity, receiver heights, area sizes and legacy modes. On the
validation Mac the maximum visibility difference is 1.2e-7 (rounding). All 38
light-count images are pixel-identical. Of 15 real-map images, three differ by one
pixel and one 8-bit colour step; the other 12 are exact. This is not a bit-exact
claim for the split shader, nor a claim of 60 FPS on every map.

## Conservative subdivision of static cells

The original32-world-pixel cells still choose at most24 sources, in their
original score order. Each selected list is then filtered into four16-pixel
subcells. A source is removed only if its XZ sphere cannot reach any point of
the subcell (with one extra pixel of margin), or a positive-radius facade source
is entirely behind its outward/bounce support (with one extra pixel of margin).
Height and material tests are deliberately not approximated. Subcells never
admit a source that overflowed the original24-source list, and never reorder
retained sources. The shader uses the matching16-pixel index coordinates.

`qa_static_grid_equivalence.lua` loads both actual grid builders in a headless
LÖVE fixture and checks ordered membership at231,324 positions, including cell
boundaries, negative coordinates, radial sources and overflow. The headless
fixture replaces only GPU image creation; real ImageData contains the indices.
In addition,15 full real-map captures are pixel-identical to the prior shader.
Four-map repeated full-effect timings check the practical GPU benefit and the
unchanged interior path; first-load tests separately retain setup/upload costs.

## Packed static fetches and conservative room-ray bounds

The renderer fetches each four-ID static index texel once and reads its channels
in the original source order. Empty lists and map boundaries still terminate the
loop before sampling light data. Position/radius is fetched first; colour and
material parameters are read only after the unchanged sphere attenuation says
the source may contribute. The final light arithmetic is unchanged.

For balanced five-ray room shadows, a conservative AABB encloses the receiver
and all five source samples. It is expanded by one world pixel, including the
reference slab test's safe-direction epsilon. Only unrotated, unsloped blockers
entirely outside this volume are skipped. Rotated or sloped blockers, authored
relief and other sampling modes retain their reference path. Blocker order and
per-ray minimum transmission are unchanged.

Private checks: `qa_static_light_count_views` renders all source counts 0..24 in
outdoor and indoor scenes, including zero power, cones, points, facade bounce,
wall-only response and non-quadratic falloff. `QA_STATIC_CLUSTER=1` additionally
requires the real index texture to contain every source up to the full24 slots.
`qa_room_shadow_equivalence` compares actual float GPU shadow outputs, including
rotated/sloped and translucent blockers. `qa_geometry_fixed_frame_views` pins
native tile animation for reproducible live-built geometry comparisons; use
`QA_DISABLE_CACHE=1` on both baseline and candidate. These are private diagnostics,
not changes to the player's native animation or quality settings. Fresh guarded
cache bakes and native gameplay checks are required before package activation.

## ACES exposure balance (2026-10-07)

The legacy scene is already display-lit. Applying the ACES fit with unit
exposure raised 18% grey to about 27%, visibly washing out caves and nights.
`post.acesExposure=.72` now anchors that midpoint while preserving the HDR
shoulder and bloom. It multiplies the user `post.exposure` only when ACES is on;
ACES off retains the previous exposure exactly. Set it to 1 to reproduce the
initial unbalanced implementation. This does not alter lights or cave rules.

Native same-camera comparisons in `output/oasc-tonemap-balance-20261007` cover
Diglett's Cave, Viridian and Pallet at day/evening/night. The measured average
encoded RGB luminance (not display nits) changed from +47% to +2.8% versus the
legacy path in Diglett's Cave at night, and +44% to +0.5% in Viridian at night.
The default midpoint and disabled path have GPU assertions in
`gen3_color_grade_test`; 24 native HDR/legacy-off comparisons also pass. These
are brightness/regression checks, not Steam Deck GPU timing or RC approval.

## Hemisphere ambient and aerial perspective (D / G, 2026-10-07)

`EnvironmentLight` adds directional sky/ground ambient and low-wall bounce to
the existing scene shader. Actors receive 40% of the ambient change; caves
and rooms use neutral ambient/bounce rather than outdoor sky hue. Bounce is
scaled by ambient luminance, so it cannot behave as a new lamp at night.
Directional ambient is luminance-limited to the established world tint before
bounce. This intentionally calibrates the brief's unbounded ambient formula
against the corrected ACES exposure instead of reintroducing its brightness bug.

The atlas mean is sampled once per CPU ImageData/overlay identity (8-pixel
grid), using the native importer image data already in memory. There is no
Canvas readback. Weak keys allow unloaded atlas data to be collected; replacing
the overlay invalidates the mean. `Renderer.stats.bounce` exposes the albedo.
New uniforms use persistent vectors and `UniformState` in every scene shader.

Aerial perspective uses radial distance for perspective and view-forward
depth for orthographic cameras. Its 160–420 range is relative to the focus
plane (the focus maps to the start), not the camera's telephoto setback. This
keeps the player clear through zoom changes. Only outdoor scenes enable it;
fog coverage continuously reduces its strength to 30%. Sky colour follows
DayNight and is capped to ambient luminance. Existing emission is preserved
after the aerial term. No new render pass or canvas is needed.

Config blocks: `lighting.hemisphere` and `atmosphere.aerial`. Both are off in
the base config. Presets apply hemisphere amounts 0/.3/.45/.6/.6 and aerial
amounts 0/0/.2/.35/.35 for off/low/medium/high/ultra. Full off retains native
rendering; an effect amount of zero retains the previous scene pixels.

Evidence: `output/oasc-environment-light-20261007/index.html`, frozen candidate,
original Renderer, scripts, logs and TSVs. `gen3_environment_light_test` checks
albedo caching/invalidation, projection/focus policy, fog attenuation, cave
neutrality and disabling. `gen3_environment_light_play_test` compares 7 native
maps × 4 times × both projections: all **56 disabled comparisons are byte exact**.
Enabled comparisons range from −5.224% to +0.098% mean encoded RGB luminance;
there is no renewed global brightness lift. Pallet day, Route 1 dusk and
Diglett night were also inspected visually. Both native test processes exited 0.

480 alternating warmed Medium CPU samples without screenshots (60 per state
per map) yielded median Renderer.draw times: Pallet 2.471→2.509 ms, Viridian
Forest 3.228→3.220 ms, Mt. Moon 7.980→8.016 ms, Pokémon Tower 4.934→5.019 ms.
These measure CPU submission on this Mac, **not GPU execution or Steam Deck**.
The brief's Steam Deck timing gate, full RC testing and package replacement
remain outstanding. The player demo and original engine were not changed.

## Thin-paper transmission (E, 2026-10-07)

`PaperTransmission` adds albedo-squared coloured sunlight to backlit foliage,
grass, stationary/cut-tree crowns and masked window/skylight panes. Character
cards and solid walls are excluded. Cut-tree props share the actor material
range, so their explicit foliage flag is handled separately. Pane frames are
excluded by the existing glass mask. Snow reduces transmission by up to 85%.

The term uses view/sun direction, a configurable power (3), direct irradiance,
shadow visibility and the existing cloud transmission. `CloudDaylight` exposes
its already computed per-fragment transmission, avoiding another cloud-noise
evaluation. The later legacy cloud-shadow multiplication also affects the term.
There is no new full-screen pass, canvas or texture. Two persistent uniform
vectors are sent through `UniformState` for ordinary and instanced geometry.

`lighting.transmission` defaults off. Presets off/low/medium/high/ultra set
strengths 0/0/.25/.45/.45. TimeOfDay continuously interpolates transmission:
dawn/golden 1.4, noon .5, dusk .7, night 0. Indoor rendering is disabled before
binding; material and daylight gates additionally protect sprites/night/caves.

Evidence: `output/oasc-paper-transmission-20261007` contains a frozen candidate,
baseline Renderer, scripts, logs, 56 same-camera comparisons and CPU TSV.
`gen3_paper_transmission_test` renders the actual production fragment for eight
material cases and tests front light, no daylight, blocked clouds, snow, and
time interpolation. `gen3_paper_transmission_play_test` covers seven native
maps × four times × two projections: disabled output is byte exact, and enabled
night/cave/interior cases remain byte exact. Pallet golden-hour output was
inspected visually. Both native runs exited 0 with no renderer fallback.

480 warmed, alternating Medium CPU samples at golden hour (no image readbacks)
gave median Renderer.draw times: Pallet 2.443→2.434 ms, Viridian Forest
7.769→7.823 ms, Mt. Moon 7.818→7.808 ms, Pokémon Tower 4.849→4.879 ms.
These are Mac CPU submission times, not Steam Deck GPU timing. Full RC testing,
the remaining graphics tasks, and replacement of the player package are open.

## Actor foot-point lighting (F, first part, 2026-10-07)

`ActorLighting` evaluates local and whole-map spatial lights at the character's
world foot in the vertex shader. The value is constant across the painted
card, so a lamp tints the character consistently instead of lighting only a
strip. It preserves the source radius/falloff, facade cone, wall-only exclusion,
cave actor gain and room cone/area/relief visibility. The existing room shadow
helpers are shared with the vertex stage; there is no alternate shadow model.
The normal fragment spill limiter remains in place, and sprite colours are
preserved instead of being whitened by facade spill.

Native field sprites and mapped battle layers bind their actual world foot.
This is a uniform because CPU-posed and folded battle vertices do not all
carry a usable BillboardAnchor. Fold animation does not move the illumination
origin away from the foot. Cut-tree props retain their existing fragment path.
Tail-flame sources explicitly retain localized per-fragment lighting, avoiding
a whole-body glow on Charmander. Other actor lights skip the two 24-source
fragment loops; they are evaluated per vertex (six vertices for a flat card).

Config: `billboards.footLighting.enabled`, default false; preset `actorFoot`
is true from low upward and false for off. A real shader compile probes vertex
texture/shadow support. If unsupported, it logs the reason and compiles the
established fragment-light variant; the main renderer need not fall back to
the native 2D view. Instance geometry retains its existing fragment variant.
Foot/mask uniform storage is reused, with resets between actor and world passes.

Evidence is in `output/oasc-actor-foot-light-20261007`: frozen candidate, baseline
Renderer, native logs, image comparisons, shader tests and CPU samples.
`gen3_actor_foot_light_test` runs the production vertex helper on the GPU:
constant card colour, radial attenuation, cone direction, wall-only rejection,
room blocking, cave gain, static-grid parity/bounds and flame exclusion all
pass. Simulated lack of vertex support successfully takes the legacy path.
`gen3_actor_foot_play_test` verifies 56 native disabled comparisons (7 maps ×
4 times × both projections), all byte exact, plus complete native off.

480 warmed Medium samples without screenshots gave median Renderer.draw CPU
times: Pallet 2.347→2.452 ms, Forest 2.630→2.794 ms, Mt. Moon 2.666→2.817 ms,
Pokémon Tower 1.719→1.866 ms. The extra binding/submission cost is measured;
GPU execution savings and Steam Deck timing are not yet measured. Player-house
night and the mapped Charmander battle were visually inspected.

The final candidate also passed four native battle loops: wild Ember, snowy
Thunderbolt, indoor trainer and Diglett cave Hyper Beam, through victory and
return. All generated move lights were present and runtime SE synthesis was
zero. Native menus and four window aspect ratios also passed.

**F remains incomplete:** the directional sun/moon silhouette rim is still
outstanding. This commit covers anchored local lighting, not the full F gate
or RC readiness. The player demo and distributable were not replaced.

## Exterior sprite rim (F, second part, 2026-10-07)

`SpriteRim` adds the directional sun/moon edge to field characters and mapped
battle cards. A cached native-pixel mask flood-fills only transparent pixels
connected to the outside of each sprite frame. Fully enclosed transparent
holes do not generate edges. Four-connected exterior normals are stored in a
nearest-filtered texture; the default width is one native sprite pixel.
Atlas frames are processed separately. Screen derivatives transform those
normals through flips, affine poses and folded meshes. The celestial direction
is projected through the actual camera, including viewport aspect ratio.

The existing solar colour, moon fill, direct-light strength, cloud transmission
and shadows control the contribution. Outdoor-only gating leaves cave and room
lighting unchanged. No fullscreen pass or HUD modification is added. Native
scanline/substitute animations temporarily retain their established lighting
because their distortion is not affine; no stale contour is applied to them.
Alternate terrarium shaders lacking the rim uniforms retain their own lighting.

Config: `billboards.rim={enabled=false,strength=.35,width=1}`. Preset `actorRim`
is 0 for off/low, .20 for medium and .35 for high/ultra, wired through
`EffectSettings`. Width is bounded to 1–2 source pixels. The full main-shader
compile probes support; if that fails, the mod logs the reason and compiles
without the rim while retaining the normal 3D renderer and actor light fallback.

Field masks consume existing CPU sprite data. Battle masks reuse the small
portrait/support readbacks already performed by the fixed RC1 engine path.
A previously unseen frame without CPU pixels uses a single cached source-image
readback, never an animated scene readback every frame. Masks are weakly keyed
by source image; old-width masks are released when replaced. Uniform vectors
are persistent scratch arrays. Native sprite and HUD filtering stay nearest.

Evidence: `output/oasc-sprite-rim-20261007` contains the frozen candidate and
baseline Renderer, 56 native comparison triples, CPU samples, a Pikachu contour,
and four completed native battles. The GPU regression checks hole rejection,
frame boundaries, one-pixel width, directional sign, mirrored and rotated
capture coordinates, actual Pikachu coverage and simulated shader fallback.
Disabled output is byte exact in all 56 map/time/projection comparisons; all
32 room/cave comparisons stay exact even with the rim enabled. All 24 outdoor
comparisons have a nonzero localized contribution. Field golden-hour and the
mapped Charmander battle were visually checked.

The final battle run exercises golden-hour sun and night moon/snow on Route 1,
an indoor trainer and cave Hyper Beam. It observes actual mapped rim source
images, verifies interior/cave gating, runs intro→command→attack→victory→return,
checks four window aspects and native menus, and reports zero runtime SE bakes.

480 alternating warmed Medium CPU samples (no screenshots) give medians:
Pallet 2.456→2.568 ms, Forest 3.376→3.471 ms, Mt. Moon 3.351→3.502 ms,
Tower 1.986→1.982 ms. This is CPU submission, not Steam Deck GPU time. Native
combat still has draw-CPU outliers around 32–42 ms; the command-window test also
includes captures/resizes and is not a steady-state timing gate. RC fluidity is
not established. F's field/mapped-battle implementation is now covered; target
hardware performance and alternate terrarium acceptance remain open, alongside
C, O1/O2 and the broader optimization/release checklist. No player demo or
release package was replaced.

## Disabled finish parity (2026-10-08)

The original RC1 `PaperFinish.lua` is retained unchanged as a test oracle in
`tests/fixtures/rc1`, with archive/member hashes. Compiling all new effects and
setting their strengths to zero still produced one differing 8-bit channel in
a warm 768x528 fixture. When HDR, ACES, LUTs, dither and depth CoC are disabled
and exposure is one, PaperFinish now compiles the original finish arithmetic.
The active shader source stays unchanged. Finish snippets and frame LUT
overrides select the modern shader; prewarming retains that choice without
alternating programs every frame.

96 native GPU fixture combinations and 14 same-input real-scene finish pairs
match RC1 with zero differing bytes. Five active-effect cases plus a frame LUT
override match RC51 exactly; stable-mode program reuse, release/rebuild and
CoC failure fallback pass. Evidence: `output/oasc-legacy-finish-parity-20261008`.
This proves parity of the finish pass on identical inputs, not parity of the
entire current world with RC1 geometry or its historical lighting defaults.
Target-device performance and the separate environment-light parity audit
remain open.
