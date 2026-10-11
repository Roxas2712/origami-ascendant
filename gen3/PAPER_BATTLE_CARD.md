# OASC Paper Battle Card

Standalone Origami Ascendant module, ID `oasc.gen3.overworld-battle`, capability
`ascendant.paper-battle.gen3/v1`. Enable under START → ASCENDANT → KAEMPFE →
KAMPFANSICHT. **KARTE (Map) remains the default**. FireRed/LeafGreen offer
Original → Karte → Terrarium; Emerald offers the same three choices with its own paper popup provider. Options persist through the existing mod options system; the
saved choice initializes each battle. F6 / 5 switches the current battle view
immediately and saves the preference for the next battle. No battle state is written to saves.
The legacy package ID `VOXEL_ASCENDANT` is compatibility metadata, not a runtime
dependency on VASC. The local `core/Ascendant*` kernel originated in VASC's
neutral Card infrastructure; only these local generation-neutral modules are used.

## Ownership and files

- `cards/Gen3PaperBattleCard.lua`: registry lifecycle, capability and impact manifest.
- `battle/Gen3BattleAdapter.lua`: binds exactly one owned Game3/battle, replaces
  only its background/draw scope, latches options, reports health, releases hooks.
- `battle/PaperBattleScene.lua`: selects clear map footprints and sightlines,
  fits the arena between native HP skins and command box, owns a separate camera.
- `battle/PaperBattlePresentation.lua`: captures native animated front sprites,
  draws upright world layers using Renderer depth and lights, returns those layers
  to the native particle Z bands. It preserves Transform, Substitute, affine,
  alpha, visibility, palette and animation handling in the engine sprite pass.
- `Renderer.lua`: optional presentation callbacks; calls without that parameter
  keep the normal field actors/camera/effects. All scene lighting is shared.
- `LocalLights.lua`: battle emitters use the existing radial 3D point-light path.
- `main.lua`: Card activation, battle observation and reset retirement.
- `engine-patches/battle-presentation.patch`: optional Engine UI API v2. Apply
  after the existing paper-engine-integration patch. It touches only battle/ui.lua.
  Nil presentation preserves the original engine drawing. No rule/input patch.
  Emerald v0.3.33 uses `battle-presentation-emerald.patch` instead, preserving
  its shiny/personality sprites and native front animation frames.

Pokémon on both sides use their ROM front art; the player's image is mirrored.
Trainer fronts use RED/LEAF in FireRed/LeafGreen and the engine's BRENDAN/MAY
constants in Emerald; the enemy uses its native trainer portrait ID. The enemy trainer is absent in wild battles. Ground anchors derive
from opaque sprite bounds; nearest filtering preserves pixels. Sprite captures
and the scoped final battle target use at least 4× internal resolution, rising
to the physical window fit scale (maximum 8×). Sprite layers use that same
resolution and sample the existing world depth, avoiding a second downsample
through the lower-resolution scenery target. Scenery and original UI
skins retain their native raster; the host canvas is restored after every frame. Scene placement
never moves the native player, objects, collision grid or encounter terrain.

Original Chrome/Healthbox rendering supplies every border, label, bar and icon.
The compositing pass changes opacity/light response, not the skins. HP boxes
occupy the top corners; readable command text stays native. World sprites are
lit by existing window/crystal/environment lights. Luminous fire species add
one world point light per visible battler; Dig/Fly disappearance hides that
light too. Cave lighting still respects OASC's no-lantern policy.

## Tuning (`DioramaConfig.lua`, `battle`)

| Value | Default | Purpose |
|---|---:|---|
| enabled | true | Master Card presentation gate |
| fovDegrees / elevationDegrees | 24 / 42 | Battle camera only |
| distance | 400 | Minimum camera distance; automatic fitting may increase it |
| safeFrame | x 12–228, y 48–106 | Actor area in native 240×160 frame |
| focusOffsetX / focusOffsetZ | 0 / 0 | Base target offset before automatic fitting |
| spriteHeight / trainerHeight | 28 / 34 | World-pixel body height |
| layoutScales | 1 / .8 / .65 | Compact arrangements for narrow rooms; no map changes |
| spacing / depth | 64 / 12 | Pokémon spacing |
| trainerOffset / trainerDepth | 30 / 8 | Trainer spacing behind Pokémon |
| searchTiles / footprint | 9 / 8 | Local stand search / clearance |
| spriteResolution | 4 | Minimum integer sprite/compositor resolution |
| spriteScreenResolution | true | Fit sprites/layers/compositor to physical window pixels (maximum 8×), with sampled world-depth occlusion; false restores the previous fixed-resolution path |
| renderScale | 3 | Internal stage multiplier × quality render scale (maximum 3) |
| panelOpacity / healthOpacity | .42 / .72 | Original skin translucency |
| skinLightResponse | .10 | Subtle ambient tint on original skins |
| contactOpacity | .28 | Soft foot-contact shadows |
| lightsEnabled | true | Additional battler lights (global light setting also applies) |
| flamePower / flameRadius | .90 / 76 | Luminous fire-species point lights |
| flameSpecies | explicit species set | Which fronts have visibly luminous fire |

## Failure and cleanup

Unsupported special battles (double, ghost, Safari/tutorial, link), headless mode,
no safe clear arena or disabled diorama use the original presentation. A renderer
exception retires only this session's Paper visuals and logs the cause once;
combat remains native. Missing Engine API leaves the Card inactive with a warning.
Later-owned wrappers are never removed by teardown. Reset releases GPU canvases,
mesh, shader, sprite metrics and Card hooks. At most four actor layers are retained.

## Verification

- `tests/gen3_paper_battle_card_test.lua`: exact owner, option latch, special/off
  fallback, GPU failure, later hook ownership, reset/reactivation.
- `tests/gen3_paper_battle_scene_test.lua`: real camera math, wild/trainer layouts
  at every supported rotation; all actor bounds outside native UI, field camera unchanged.
- `tests/gen3_paper_battle_play_test.lua`: native LOVE/FireRed execution with
  a supplied read-only QA checkpoint; screenshots, native-input wild/trainer win,
  escape, cave/indoor rendering, GPU sprite visibility, return position and reset.
  It requires a private LOVE identity and `PAPER_BATTLE_QA_SAVE`,
  `PAPER_BATTLE_MOD_ROOT`, `PAPER_BATTLE_QA_OUTPUT`; never use a player's live identity.
  Fixture encounters do not prove every move or scripted encounter in FireRed.

## Emerald integration (2026-09-30)

The Emerald branch uses the same accepted camera, sprite resolution and skin
configuration. The private native runtime driver also supports
`PAPER_BATTLE_QA_VERSION=emerald`; this creates an in-memory party via the native
mon factory, opens no player checkpoint and writes no save. Set
`PAPER_BATTLE_QA_GENDER=1` for May. Its Hoenn cases cover Petalburg Woods, Granite
Cave and a Littleroot interior. FireRed retains the checkpoint path.

Wally's tutorial (`kinds.tutorial`), recorded/link battles, Old Man and Poké Dude
explicitly retain native presentation. Missing clear space also retains native
presentation. Only supported Emerald Paper maps can supply the arena.

Emerald native runtime verification: wild/trainer wins with both player fronts,
escape, cave/interior rendering, high/low quality, Dig sprite/light disappearance,
Ember, same-position/map/camera return, reset and unsupported-map fallback.
The 48-map landscape and map-space fog/light regressions also pass after merging
the battle renderer. This is fixture coverage, not every move/scripted encounter.

## Live view and sharper sprites

F6 / 5 is handled before native battle menus, so it also works during attacks
and submenus. Held key repeats are ignored. Switching preserves the exact
battle table and fitted arena, with no turn advance or HP/PP changes. Special
battle/map restrictions still apply. The field camera/mode is unchanged.

Emerald's separately drawn command/move frames are captured together with the
base panel before opacity is applied. Text remains native and fully opaque;
HP/EXP skins retain their existing opacity.

`PAPER_BATTLE_QA_SHARPNESS=1` captures fixed-camera detail and opacity comparisons
and tests F6/5 view changes. `PAPER_BATTLE_QA_DEPTH=1` (high quality) compares GPU
alpha against hardware depth pixel-for-pixel and verifies complete occlusion.
`PAPER_BATTLE_QA_FIXTURE=1` also creates a native in-memory FireRed party without
a checkpoint. Explicit fixture moves keep attack tests independent of wild AI
move selection. No player save is read or written.

## Battle rendering cost

Sprite lighting uses conservative scissor rectangles from the actual native
geometry/pose, and the final composite draws only that portion of each layer.
Full-size nearest targets keep depth UVs and native palette/particle coordinates
unchanged. Affine rotation is bounded conservatively; scanline distortion and
substitute fall back to the full target. Unchanged trainer portrait captures are
reused, keyed by image, target, fitted position and scale; lighting remains live.

`PAPER_BATTLE_QA_BOUNDS=1` checks actual GPU source alpha outside the proposed
regions for idle, affine, off-screen, scanline and hidden poses.
`PAPER_BATTLE_QA_LAYER_REFERENCE` points to a previous presentation module and
compares every actor-layer pixel against it (identical alpha; sparse GPU lighting
rounding capped at four 8-bit steps, mean below 0.1 step over opaque
pixels). This also avoids treating tiny-sprite reprojection area differences
as new occlusion. `PAPER_BATTLE_QA_REFERENCE` can run that previous module alone.
`PAPER_BATTLE_QA_PERF=1` runs a frozen in-memory battle benchmark: 60 warmup frames
then 240 end-to-end frame intervals per variant. Screenshots happen only during
warmup. `PAPER_BATTLE_PERF_VARIANTS=baseline,full,full,baseline,baseline,full`
interleaves comparisons; `PAPER_BATTLE_PERF_BASELINE` points to the previous
`PaperBattlePresentation.lua` outside the repository. Run without other QA
capture processes; concurrently running game windows affect absolute FPS.

## Kanto Terrarium view

`gen3BattleView` stores `paper` (Map/default), `native` or `terrarium`. The former
`gen3PaperBattles=false` migrates to Original; existing explicit choices remain.
F6 / 5 cycles the available views even during attacks, and F3 / V contains the
same live setting. Per-battle scenes are cached; switching never restarts combat.

`battle/BattleViews.lua` selects the provider by edition. FireRed/LeafGreen load
the Kanto provider below; Emerald loads `battle/terrarium/EmeraldScene.lua` and
never imports the Kanto host or its assets.
`battle/terrarium/Locations.lua` maps native FR/LG IDs to the authored Kanto
locations, including gyms, League, forest, caves and special buildings. Silph's
occupied design checks the live Rocket story flag; unavailable designs use the
existing generic family bowl. Native Safari, ghost, double and tutorial/link
battles retain their original presentation.

`battle/terrarium/Scene.lua` hosts the existing portable Terrarium factory with
OASC matrices, native sprite captures and GPU depth. It renders only the compact
arena: no field renderer, neighboring maps, field shadows or field post passes.
Meshes and baked contact lighting use bounded caches; dynamic lighting has at
most three stage lights and two visible battler lights. Sprite texture lookup is
screen based because the original Terrarium camera has regular perspective.

`vendor/PROVENANCE.json` records the source revision and SHA-256 of every reused
file. The 30 authored designs, credits and branding are unchanged. These local
files are standalone; no installed VASC runtime is required. This commit adds
no Hoenn terrarium art. The backdrop and its halo/frame read `EditionAccent`,
matching each edition's UI (FireRed red, LeafGreen green); the authored bowl
materials retain their original colors.

Tests:
- `gen3_terrarium_card_test`: Map default, legacy migration, FR/LG three modes,
  Emerald's separate provider, exact ownership, scene reuse and entry selection.
- `gen3_terrarium_assets_test`: native ID reachability, live Silph flag, all 30
  authored designs/both layouts, finite geometry, bounded mesh/lightmap caches,
  one bake per cached entry, lighting off and full release.
- Native play driver: `PAPER_BATTLE_QA_VIEW=terrarium`, optionally
  `PAPER_BATTLE_QA_CYCLE=1`; real FireRed forest, gym and cave captures, native
  wins, depth parity, Dig disappearance, live cycling and return/reset.
- `PAPER_BATTLE_PERF_VARIANTS=paper,terrarium,terrarium,paper` compares complete
  views after warmup, without readbacks in the timed samples.

LeafGreen shares the Kanto provider and is covered by the version/routing tests;
a native LeafGreen ROM run has not been performed in this workspace.

## Trainer hand send-out

The optional engine `presentation.ballPosition` callback remaps only the drawn
player send-out ball. `TrainerBall.lua` anchors it to RED/LEAF/BRENDAN/MAY's
portrait hand using the same mirror, scale and foot alignment as the trainer.
Native rotation supplies the existing 25-frame flight progress; opening frames
meet the projected Pokémon release point and native opening particles, with
no writes to ball/battle state. Original
mode retains the original ball rendering. Both engine presentation patches now
include the optional callback and need refreshing on existing installations.
`gen3_trainer_ball_test.lua` verifies both genders/editions, start/end alignment,
opening continuity, absent-hand fallback and native-state preservation.

After the native opening phase (12 frames), a presentation-only 25-frame return
arc brings the closed ball back to the trainer. Its timer observes `Anim.update`;
it neither adds battle tasks nor changes when commands become available. During
flight/opening/return, the small held-ball pixels in the portrait are replaced by
a closed-hand fill, then restored on catch. The trainer source cache includes
this visibility state, so unchanged portraits remain cached.

## Animated sprite ground contact

The optional native `presentation.poseCenter` callback runs after choosing the
actual front-animation image and its final scale, mirror and rotation. OASC
caches that image's opaque row endpoints and lifts the rendered center only if
transformed visible pixels penetrate the projected floor line. Transparent
padding does not count as feet. This covers affine squash/stretch, rotation,
positive bob offsets and Emerald frame changes, on Map and Terrarium floors.
Upward jumps are not pulled down; Dig/Fly invisibility remains native, and fainted
Pokémon retain their native sinking exit. Pose/battle tables are never changed.
The corrected center also supplies the sprite scissor bounds. Image readback
occurs once per cached source image, not once per frame; reset drops the cache.
`gen3_sprite_ground_test.lua` checks real opaque pixel corners across rotations,
mirrors, stretches and sloping projected floors, plus neutral/jump behavior.


### Motion and species scale follow-up

Native command bounces run from 0 to +2 screen pixels. Merely clamping them to
zero erased the entire idle motion. The presentation now redirects these
excursions above the floor, including small positive attack offsets. Long
positive exits are bounded to six pixels of upward motion so Dig cannot launch
a Pokémon into the health panels. Negative jumps, scale, rotation, frame changes,
visibility and the native battle clock retain their own inputs. Fainting remains
outside the ground correction.

ROM Pokédex height supplies the ordering, while a square-root curve compresses
size differences for readable gameplay: `28 * sqrt(heightDm / 12)`, bounded to
16.8–42 world units. A literal scale made Charmander much too small. It now uses
about 19.8 units (roughly waist height against the 34-unit trainer), Snorlax 37,
Pikachu 16.8 and Charizard 33.3. Width and height use the same factor. Missing or
invalid dex metadata retains 28. The existing 42-unit map fitting/sightline
envelope remains sufficient for every species. Ball-release targets and
flame-light height follow the same species scale.

Four native Emerald review pairings (Charmander/Snorlax, Pikachu/Charizard,
Bulbasaur/Onix, Squirtle/Gyarados) are captured under
`Recompile/output/origami-battle-proportions-20260930/`.

`gen3_sprite_size_test.lua` checks the ROM-height mapping and limits.
`gen3_sprite_ground_test.lua` also checks native positive bounce/attack samples.
`gen3_battle_motion_play_test.lua` is a private-host temporal GPU probe: call its
factory with `ex`, `sample()` after each native draw, and `finish()` after using
Ember and Scratch. It verifies changing visible player pixels at the command
prompt and changing nontransparent attack-FX pixels, without fabricated poses.
Review host, captures, native battle logs and clip are under
`Recompile/output/origami-battle-motion-20260930/`.

## Emerald paper popup (2026-09-30)

`battle/terrarium/EmeraldScene.lua` renders the reviewed spherical paper ball
directly in LOVE. The landscape and shell textures are the same approved
artwork as the conversation preview; `data/EmeraldTerrarium.lua` defines its
traced paper cutouts. There is one rear lid hinge, stationary lower shell,
silver inset panels fixed to the lid, a blue latch/seam prelight, small trainer
rock pedestals and continuously flowing waterfall highlights. All supported
Hoenn encounters currently share this one authored jungle scene; biome variants
are not provided. Kanto keeps its existing authored terrariums.

Battle entry starts small, flies in and grows before opening. A live view switch
starts at full size and only opens. Selecting the already active mode does not
replay the animation. Re-entering a cached terrarium does replay the short
opening. The native `Audio.playSe('SE_BALL_OPEN')` call fires once as the lid
starts moving, using the installed game's audio pack and sound settings.
The closer default camera has independent mouse-wheel/trackpad zoom (see below).
Blue-white bloom and radial rays follow both rim loops from the closed-ball
prelight through lid release, then fade completely before the figures rise.

The optional provider `enter/update` hooks own this presentation timer. A live
view switch holds native updates for 0.4 seconds, preserving attack poses, HP,
PP and the battle object. The full cinematic battle entry also holds updates.
The default fast wild entry releases native updates after 0.3 seconds and
composites the original battle UI during the remaining scenery folds.
`FastIntro.lua` copies the pending native intro step list and shortens redundant
background slides/undarkening/healthbox motion. It retains all original messages,
shiny checks, cries and send-out callbacks. Nothing rewrites combat state.

The saved `gen3TerrariumIntro` choice is NORMAL (balanced, default), SCHNELL or FILMISCH.
Normal unfolds the scenery over 1.7 seconds, opens the latch at 0.55 seconds,
and overlaps native wild text from ~0.68 seconds. Enemy/trainer folds take
0.55/0.35 seconds. Advancing the first message cannot raise the trainer before
the stage is physically unfolded; sprite spawn motion waits for the actual fold. Fast
entry overlaps flash, flight and prelight; the lid opens at 0.3 seconds and all
paper scenery is unfolded by 0.9 seconds. Native wild text appears during that
opening (~0.43 seconds in QA). `PopupDialogue.lua` waits for the wild message to
be dismissed before raising the trainer. In fast mode, the native Go line and
throw run concurrently; its printing/queue remain owned by native UI. The paper
ball follows native release frame 32, landing frame 57 and 12-frame emergence.
Film mode retains the original 5.2-second scenery reveal and deliberate staging.
Selecting a different intro mode applies to the next battle; mode switches
always use the short opening. Trainers and Pokémon rotate around fixed feet.
The player trainer makes a short windup, throws the native ball sprite from the
hand to the player's arena foot position, and the player's Pokémon unfolds only
after landing.
The view-switch entry unfolds the existing actors without replaying a throw.
Intro cutouts use current ROM front portraits and Pokémon. After the reveal,
these placed cutouts remain through the native intro phase, covering its second
send-out, ball and particle visuals. Wild entry gates advancement of the intro
sequencer during the brief trainer/player folds, while its native tasks, dialogue,
audio and eventual command handoff retain ownership of combat.
Normal combat uses the existing native pose/particle/depth pipeline, including
Dig/Fly disappearance. No checkpoints or player state are changed by the renderer.

Emerald attack scripts retain native coordinates during VM launch/update, in all
views. `EffectFit.lua` fits particle trajectories between the current two arena
anchors, scales art and excursions with the displayed Pokémon, and restores all
sprite fields after drawing (including failures). Task-drawn effects use the
corresponding arena transform. Native view therefore retains its original effect
space; switching views mid-move does not reinitialize the move. Terrarium sprite
motion offsets are fitted to the actor scale as well.

Fainting observes the native `faintMon` tween instead of replacing its timing or
completion callback. During that tween, the defeated Pokémon is rendered as a
rigid front cutout folding backward around its foot hinge; the native completion
still hides it and its healthbox. The record is tied to the battler, so a new
Pokémon in the same slot does not inherit a defeated pose.

`gen3_emerald_popup_test.lua` checks 1,200 hinge samples, both entry modes, blue
prelight timing, one sound trigger and continuing water time. The native driver
accepts `PAPER_BATTLE_QA_POPUP=1` to play a complete mode switch while asserting
identical battle/phase/pose/HP/PP. `PAPER_BATTLE_QA_DEPTH=1` checks sampled GPU
occlusion; `PAPER_BATTLE_QA_CYCLE=1` checks F6/5 ownership and held-key suppression.
`gen3_popup_actor_test.lua` checks fixed feet, rigid rotation, pedestal timing,
hand-to-ground throw endpoints and the landing-before-player-fold ordering.
`gen3_popup_dialogue_test.lua` checks wild/trainer/send-out order and arbitrary
reading delays. `PAPER_BATTLE_QA_DIALOGUE=1` checks those stages in the native
wild driver and captures the actual message frames.
`gen3_effect_fit_test.lua` verifies effect anchors, scale, restoration on failure
and the backward faint hinge. `PAPER_BATTLE_QA_FAINT=1` checks the real native
faint tween and fitted attack effects after drawing (`ember` and `paper` cases).
`PAPER_BATTLE_QA_HANDOFF=1` with the Emerald wild `paper` case uses Snorlax and
checks stable rendered cutouts throughout the actual native entrance and handoff.
Private QA hosts and captures: `Recompile/output/oasc-emerald-popup-20260930/`.

Emerald front appearances use the ROM's front animation frames and affine poses
once each paper Pokémon is fully unfolded. This is a presentation-owned MonAnim
sprite; native combat timing remains unchanged; fast intro presentation is described above.

Dig observes native down/up tasks and clips the sinking front cutout at its
projected planted feet. The paper hole stays open through the hidden and pre-rise
phases, then closes after native ascent. The two DIRT_MOUND tiles share the same
foot baseline and local sprite scale. Hidden Pokémon emit neither contacts nor
flame light. `gen3_dig_presentation_test.lua` and `PAPER_BATTLE_QA_MOTION=1` check
real descent/occlusion/return and animated Emerald front appearances.

The floor overlaps the inner rim and has a paper collar; the lower shell's UVs
cannot sample the red lid. Water motion covers falls, connecting streams and
pools; native GPU QA checks all three horizontal water regions separately.

Default Emerald framing is 1.34 (previously 1.04). Mouse wheel/trackpad adjusts
only this battle scene, from 65% to 250% of the default framing. Zoom is retained
when changing views within a battle. The VASC nine-second idle delay, alternating
0.075-radian rocking and synchronized blue button pulse are reused from
`terrarium/vendor/Terarrium.lua`; the complete scene is moved through the camera.
Input, menu changes, attacks and zoom reset idle time. `gen3_terrarium_camera_test`
checks timing/reset/limits, and `PAPER_BATTLE_QA_CAMERA=1` exercises the live wheel
handler, camera poses, blue pulse and unchanged combat/field camera state.

Scenery now renders at 1.5× the physical window fit (4–8× the logical battle
canvas), rather than a fixed 3×. At 1280×800 this is 1920×1280 instead of
720×480; original paper artwork is retained.

### Close camera, VASC impact sound and paper shadows

`gen3TerrariumZoom` saves 75/100/125/150/175/200/250% presets. Mouse wheel
remains temporary within the battle; zoom-in pivots around the combatants and
shifts them upward enough to retain their feet above the native command panel.
The field camera and battle state remain unchanged. F3/V at the Emerald command
menu opens a zoom/sound/intro panel. Its input is stepped separately while
native combat pauses, so setting changes cannot select a move underneath.
Outside battle the same settings are in ASCENDANT > KAEMPFE.

`IdleSound.lua` ports VASC's original synthesized 0.42-second resonant impact.
One impact fires at phase 0.42 of each 0.56-second alternating roll, after the
nine-second idle delay. The source is cached, follows native SFX volume and
stops on input, zoom, menus, view changes, battle end and teardown. The saved
`gen3TerrariumIdleSound` toggle mutes it independently.

Foreground grass paper meshes and current trainer/Pokémon cutout alpha now
cast short shadows onto the circular floor from the same front-left direction.
Three offset samples soften the silhouettes. Dig-clipped/hidden sources and
faint folds also drive their shadows. `gen3Shadows` controls the pass; source
textures and native actor/effect poses are not modified.

Native camera QA checks real F3 input isolation, saved presets, audible playing
Source/beat timing/mute, zoom bounds and GPU shadow on/off differences. Captures
and logs: `Recompile/output/oasc-emerald-sound-zoom-shadows-20260930/`.

Fast intro QA: `PAPER_BATTLE_QA_INTRO=balanced|fast|cinematic` chooses the saved mode in
the private driver. `gen3_fast_intro_test` verifies private step copies and the
single native Go overlap; popup/dialogue units cover 300ms arrival, 900ms scene,
400ms mode switches, cinematic pacing and message-controlled actor ordering.
Native captures: `output/oasc-emerald-fast-intro-20260930/` and
`output/oasc-emerald-film-intro-20260930/`.


### Hoenn art quality and coverage (2026-09-30)

The first procedural habitat experiment was rejected for visual quality and
removed from the active renderer/source. Its archived draft and diagnostic
renders are under `output/oasc-emerald-habitats-20260930/`, not release assets.
A GPU render success is **not** an art acceptance criterion.

`EmeraldHabitats.lua` resolves all 519 imported Emerald map IDs into location
and encounter-surface families, including Route 111 sand vs grass, surfing,
diving, Shoal Cave tides, gyms and the League. This mapping is not a claim
that every design has finished art. `EmeraldTerrariumArt.lua` registers only
illustrated assets: forest, route families, all eight gyms, five League rooms,
Sky Pillar, dry cave, Rustboro, Aqua hideout, Birth Island and sea/diving.
Other families still require illustrated assets and
visual review; they must not use the rejected procedural draft.

The dry cave uses `cave-paper-v2.png` and `cave-floor.png`, with individually
traced UV cutouts in `EmeraldCaveTerrarium.lua`. Shell, hinges, mirrors, actor
anchors and renderer remain shared. Generated art uses the built-in imagegen
tool with the approved landscape/floor as edit references. Prompts and source
provenance: `gen3/data/emerald-terrarium/ART_PROVENANCE.txt`.

Native cave capture and result: `output/oasc-emerald-cave-art-20260930/`.
Normal timing + actual escape/music restore: `output/oasc-emerald-balanced-20260930/`.
The playable private demo bypassed BattleBridge by calling Battle.start directly;
its missing onDone now invokes native Audio.restoreMapSong. Normal gameplay
already restores music in BattleBridge. QA also checks the final song identity.

Sea uses a recessed reef basin, one animated water surface, dry trainer pillars
and dry combatant rock platforms above the waterline. The latest lid carries a continuous paper island/sky
insert and two matching overlapping wave contours from `sea-composition-v3.png`.
The earlier rectangular wave-strip assembly was rejected; it is no longer in
the active layout. The sea lid opens farther back to keep its full silhouette
in frame. This is still a visual work in progress, not user-approved final art.
Ten independent reef props occupy the side and foreground slopes. Alpha also
masks their reverse faces, preventing opaque rectangular cards when unfolding.
The lid mirrors are restricted to its perimeter in this variant.

`AmbientMotion.lua` schedules quiet-menu details independently of combat: cave
pebbles, forest leaves, Rustboro chimney smoke and a rare sea-only Kyogre shadow.
Events pause in place during actions and reset on entry. The sea GPU probe
(`PAPER_BATTLE_QA_SEA=1`) checks visible water/wave movement, shadow pixels and
an identical paused frame. Native camera QA also checks actor/paper shadows,
zoom, VASC idle sound and unchanged battle state. Captures and logs:
`output/oasc-emerald-sea-art-20260930/`. Additional source prompts and reference
credit are in `ART_PROVENANCE_ADDITIONAL.txt` next to the images.

The private playable starter now begins at sea. F4 cycles forest, cave,
Rustboro, sea, rock gym, Aqua hideout and Birth Island; F5 restarts the fixture battle, F3 opens zoom/intro settings.
It uses only the dedicated QA identity, never player saves.

Latest style direction: Paper Mario-like thin, flat illustrated cutouts, many
overlapping contours and restrained shadows between layers. Avoid chunky 3D
architecture, cylindrical pipes, faceted voxel-like rocks and photo-textured
volume. Review concepts: `output/oasc-paper-style-review-20260930/` (sea and
Aqua hideout). The revised Aqua concept is now registered as a playable scene.

### Flat paper pass (2026-10-01)

Cave and Rustboro use revised illustrations. Rock gym, Aqua hideout and Birth
Island now have their own traced layouts rather than only review concepts.
They share the ball shell and folding system while using separate architecture,
rock, sea and foreground plant cards. Aqua has its own illustrated floor.
Asset prompts and edit references: `FLAT_PAPER_PROVENANCE_20261001.json`.

Quiet-menu accents: rolling pebbles in the rock gym, teleporter pulses in Aqua,
star glimmers on Birth Island. Aqua harbor water and Birth Island sea have
animated highlights. No battle RNG or combat state is consumed.
`PAPER_BATTLE_QA_ART_SET=1 PAPER_BATTLE_QA_AMBIENT=1` runs all five actual map
fixtures, checks visible GPU accents and their exact paused pose, actor
visibility, animated water, and return to map music. A native silent map song
(0xFFFF) correctly restores silence (reported as 0), not battle music.

Review captures and native log: `output/oasc-paper-style-review-20261001/`.
These are reviewable implementations, not a claim of user-approved final art.
Other cities, seven other gym designs, Magma, League and other special-event
settings still need individual artwork; map classification alone is insufficient.

### Living paper and explicit coverage (2026-10-01)

The user rejected the static-looking sea and requires all rock platforms to
protrude from the water. Sea now uses one connected surface with visible flowing
crests, edge foam, pillar wakes, water tint and small screen-space refraction.
It samples a separate scene canvas and respects opaque rock depth. New authored
alpha-cut columns replace stretched or stacked low-platform crops; both Pokémon
stand at y=7.5 above the y=-1.8 waterline. Source image and final prompt are in
`SEA_ROCK_COLUMNS_V2_PROVENANCE.json`; asset: `sea-rock-columns-v2.png`.

Continuous motion complements occasional events: foreground grass/kelp and
wave folds, city chimney smoke, falling cave dust, lit gym displays, circulating
Aqua teleporter light, flowing harbor/island water. These loops use the water
clock; rare events still freeze during battle actions. Native GPU tests now
check continuous movement separately from rare-event appearance/pause.

`EmeraldArtCoverage.lua` distinguishes dedicated, base, baseline, shared and
missing art. A generic cave or sea asset does not count as bespoke landmark art.
The resolver separately identifies all eight gyms, seven Frontier facilities,
Trainer Hill and the three tents; Regi chambers, event caves, submerged ship and
crater, weather institute, Devon and Hall of Fame retain distinct identities.

The read-only audit (`PAPER_BATTLE_QA_HABITATS=1`) exports `art-coverage.tsv`.
`python3 tools/build_emerald_art_review.py <audit-output>` creates searchable
`Kampfplaetze.html` and `design-review.json` with requirements and missing assets.
The route audit has 519 imported maps and 108 design contexts, including
noncombat rooms. These are not 108 finished scenes or 519 validated battles.
The dated audit exports describe coverage at their capture time; the registry
is the current list of installed artwork. User acceptance remains outstanding.

Evidence: `output/oasc-living-paper-20261001/`. The sea clip flag
`PAPER_BATTLE_QA_SEA_CLIP=1` captures 96 environment-only native frames at 24 fps.
The clip isolates environmental motion rather than freezing a mid-send-out
Pokémon pose into a purported live battle video. Dig/faint and music restoration
are checked separately in the real native fight.

## Green layered stage (2026-10-01)

`EmeraldGreenTerrarium.lua` assembles 36 independent scenery cards for the
forest family. The existing round shell, single lid and silver mirrors remain.
Four hanging canopy/cloud cards follow the actual lid hinge; elevated terraces
use rigid folding support strips rather than staying suspended during opening.
Three versioned transparent atlases live under `data/emerald-terrarium/`;
`GREEN_V3_PROVENANCE.json` and `GREEN_V3_DETAILS_PROVENANCE.json` retain the
built-in imagegen prompts and visual reference. This is a new forest prototype,
not evidence that every location has received the same revision.

The art registry optionally defines `camera`, `anchors` and a raised `platform`.
Anchors are copied per battle, feeding the existing native presentation path for
sprites, throws, effects, shadows, Dig and fainting. The green stage separates
Pokemon by 70 world units laterally and 23 in depth, versus 49.8 and 3.3 in the
previous shared layout. Other registered habitats retain their existing anchors.
The 61-unit paper platform has a real horizontal top and four thin edge layers.
Dig uses that plane; illustrated sea/pond caps retain their separate treatment.

Evidence: `output/oasc-green-layered-20261001/`. GPU checks cover all seven
route/forest art cases, continuous and rare motion, freeze during combat and
complete folds by 1.7 seconds. Native green checks exercise both Dig holes at
three zooms, a wild encounter, a full trainer battle against Snorlax, actor
visibility, camera controls and return to map song 366. These QA readback runs
are not frame-rate benchmarks. The playable private starter now begins in the
green forest stage; F4 selects the other habitats.

## City paper interiors (2026-10-01)

`EmeraldCityTerrariums.lua` adds Fortree (20 separate cards), Pacifidlog (18)
and Sootopolis (19) inside the existing shell and mirror lid. Each uses the
authored anchor and raised-platform path introduced by the green stage. Water
encounters in Pacifidlog and Sootopolis keep their city silhouettes and animate
the surrounding water. Stage cache keys include the resolved art key so land
and water scenes sharing an atlas cannot reuse the wrong floor material.

The nine original generated assets and prompts are recorded in
`data/emerald-terrarium/CITY_PAPER_PROVENANCE.json`. Ambient details include
Fortree leaves and windchime, Pacifidlog waves/flags and spray, and Sootopolis
water/foliage and fountain accents. These remain visual prototypes awaiting
user acceptance; the registry is not a claim that all locations are finished.

Evidence: `output/oasc-city-paper-20261001/second-gpu.log` and
`native-verified.log`. All five land/water cases passed unfolding, independent
continuous motion, event pause, actor visibility, both Dig holes at three zooms,
and map-music restoration. The Pacifidlog trainer fixture finishes an actual
battle using Ember against Wingull (Dig cannot hit its Flying type). The private
playable starter exposes these five cases after the forest through F4.

## Volcanic and tidal cave interiors (2026-10-01)

`EmeraldCavernTerrariums.lua` composes six distinct stages from individual paper
flats: Fiery Path, Magma Hideout, Mt. Chimney, Shoal Cave high tide, low tide and
ice room. The exterior crater has no ceiling fringe; the cave ceiling cards
follow the existing mirror lid. Magma machinery is separate from the rock
layers, and low tide replaces cascades with exposed salt shelves. Dry raised
platforms keep the battlers above the surrounding water or magma.

Ten original texture assets and prompts are recorded in
`data/emerald-terrarium/CAVERN_PAPER_PROVENANCE.json`. The shader selectively
animates red magma while leaving basalt unchanged; ice has slow light glints
instead of water flow. Separate quiet events add vent puffs, embers, droplets,
salt fragments or frost flakes. Their clocks pause during battle actions.

Evidence: `output/oasc-cavern-paper-20261001/final-gpu.log` and
`native-verified.log`. Six cases pass artwork motion, quiet-event pause,
independent folds, complete actor visibility, full Dig holes at three zooms and
map-song restoration. Magma and ice fixtures additionally finish actual native
battles (Dig and Ember respectively). These synthetic fixtures are not claims
that every scripted encounter or all remaining cave landmarks are finished.
The private playable starter includes all six scenes through F4. Environment
clips are rendered at 24 fps without actors; they are not performance tests.

### Battle Frontier paper interiors (2026-10-01)

`EmeraldFrontierTerrariums` supplies seven independent interiors inside the
unchanged ball shell, hinge and mirror assembly: Arena, Dome, Factory, Palace,
Pike, Tower and Pyramid. Each has 15–19 independently folding flats, its own
floor material, two trainer stands and the authored raised battle platform.
The Factory fan rotates about its centre; cloth and foliage move; cyan/warm
indicators animate; the Palace cascade flows. Quiet events include leaves,
confetti, a vent puff, chime motion, motes/glints and Pyramid pebbles. Pyramid
pebbles remain outside the raised battle circle. All original generated PNGs
and prompts are recorded in `FRONTIER_PAPER_PROVENANCE.json`.

QA: `output/oasc-frontier-paper-20261001/native-verified.log` exercises all seven
maps with native battle actors, full Dig holes on both sides at three zooms,
ambient pause and restoration of map music. Factory and Palace synthetic
trainer battles play through to victory. The QA-only Frontier fixture disables
room entry/return script choreography in memory because no facility challenge
has been initialized; this does not verify rentals, judging, autonomous Palace
move selection or other special Frontier rules. No production room script is
changed. The Pyramid top represents the shared Pyramid theme; a distinct summit
variant and full challenge traversal remain future work.

`clips-gpu.log` plus `arena-final.log` validate folds and environment motion;
4-second clips show environment animation only. `coverage-native.log` audits all
519 imported maps and renders 45 registered illustrated cases. The current 110
context audit still has 51 missing designs, 15 shared substitutes and 13 general
motifs; the 31 exact designs are implemented, not a claim of user acceptance.
The private F4 play host now contains 44 selectable scenes. Its generated
artifacts live outside the repository. GPU readback test FPS is not a benchmark.

### Story locations and Regi chambers (2026-10-01)

`EmeraldStoryTerrariums` adds six location-specific interiors: Mossdeep Space
Center, Weather Institute, New Mauville, Desert Ruins, Island Cave and Ancient
Tomb. All retain the existing round ball, single lid and mirrors. The Space
Center radar and New Mauville turbine have independent rotating paper meshes;
the Weather Institute anemometer rotates above a supported window frame. Rain
material 17 moves streaks only on blue panes, leaving the wooden frame fixed.
Material 18 gives the separate Ancient Tomb metal plate a slow subdued sheen.
Regi chambers use different stone, water, frost and dust details, with a cold
stone floor in Island Cave rather than the earlier warm generic cave floor.
Foreground research cables, cases and measuring equipment are whole transparent
cutouts; no rectangular console crops remain. Prompts and original files are in
`STORY_PAPER_PROVENANCE.json` and `STORY_DETAIL_PROVENANCE.json`.

Final checks: `output/oasc-story-paper-20261001/native-verified.log` covers all six
with native battle actors, full Dig holes on both sides at three zooms, ambient
pause, map music and field-position return. Space Center (Dig) and Regice (Ember)
play through to victory. These synthetic encounters test presentation, not story
unlock scripts or legendary capture persistence. `clips-gpu.log` exercises all
folds and continuous/quiet motion and produces six four-second environment-only
clips. The 519-map audit now renders 51 registered illustrated cases. The 110
context review has 37 exact designs, 13 base motifs, 15 shared substitutes and
45 missing designs; these categories are not acceptance or performance claims.
The private F4 starter contains 50 scenes. No player save is used by these checks.

### Deep caves and legendary chambers — 2026-10-01

Added `EmeraldDeepCaveTerrariums.lua`: Meteorfälle, Tiefseehöhle, Ozeanhöhle,
Terrahöhle, Granithöhle and Urzeithöhle, each with 17 independently folded
cliff/ceiling/water/foreground cards in the existing mirrored shell. Nine new
builtin-imagegen assets and exact prompt/source records are under
`gen3/data/emerald-terrarium/DEEP_CAVE*_PROVENANCE.json`. No source bitmaps were
post-edited. The water and lava perimeter is below a dry raised battle plate;
trainer plinths remain above the surface. Extra foreground rock/fern/tang
cutouts break up repeated pools and waves. Continuous water/lava, granite dust,
and location-specific quiet events are active. Granite pebbles roll at the
raised platform height; Marine Cave bubbles rise from free foreground water.

QA: `output/oasc-deepcaves-paper-20261001/` (outside repository). GPU folding,
continuous motion, rare details and combat pause passed for all six; native
actors plus full Dig holes on both sides at three zooms passed. Meteorfälle
(Bagon) and Granithöhle (Aron) were played through a Dig win and field/music
return. Kyogre and Groudon are actual native sprites in private synthetic
encounters on the correct maps; legendary unlock/capture/weather progression
has NOT been verified. Main native evidence is `native-verified.log` through
Terra, then `granite-final.log` and `origin-final.log`. The earlier log failure
on Granite was fixed by placing dust in front of the cave mouth and pebbles on
the raised plate, not by weakening visibility thresholds.

`Hoehlen-und-Legendaere.html` contains six 24 fps environment clips and native
battle captures. Readback/visibility tests stall the displayed FPS counter;
those screenshots are not a performance benchmark. The private F4 host now
contains 55 scenes. All 519 imported map classifications and 57 registered
illustrated variants rendered in the audit. Remaining design-context counts:
43 dedicated, 13 base, 13 shared, 41 missing; 110 contexts include non-combat
rooms. This is unfinished coverage, not a claim that all terrains are complete.

### Rainforest, uplands and island groves — 2026-10-01

`EmeraldWildPlaceTerrariums.lua` adds seven location compositions: Route 119,
Safari Zone, Route 114, Jagged Pass, Mt. Pyre exterior, Faraway Island interior,
and Southern Island interior. Trees, rope bridge, ledges, clouds, vines, mist,
fern clusters and foreground details unfold independently inside the unchanged
ball/mirror assembly. Nine generated assets and exact source/prompt provenance
are recorded by `WILD_PLACES_PROVENANCE.json` and `WILD_DETAILS_PROVENANCE.json`.
Continuous foliage, water, cloud/mist motion and quiet location events are active.
Raised dry anchors leave a full Dig hole visible; front ferns were shortened and
moved outward after the native sprite-visibility test exposed covered feet.

Evidence: `output/oasc-wildplaces-paper-20261001/native-verified.log` and
`clips-gpu.log`. All seven passed native sprite visibility, authored anchors,
Dig on both sides at three zooms, visible continuous motion, quiet-event pause,
and map-music return. Route 119 and Route 114 played through a Dig win. The
Safari and legendary encounters are presentation fixtures, not validations of
Safari capture rules, legendary unlocks or persistence. The gallery
`Aussenbereiche-und-Inselwaelder.html` contains seven environment clips and
native captures. These images do not constitute a performance benchmark.

### Ruins, memorial tower and cave passages — 2026-10-01

`EmeraldRuinTerrariums.lua` adds six 17-card compositions: Mt. Pyre interior,
Sky Pillar interior, Mirage Tower, Sealed Chamber, Victory Road and Desert
Underpass/Fossil Maniac tunnel. Existing ball, mirrors and hinge are retained.
`RUIN_PLACES_PROVENANCE.json` records six unmodified generated kits. Separate
banners, sand ribbons, dust clouds and rock ceilings supplement the wall flats.
Muted blue-green water uses opt-in shader material 19, so low-luminance streams
move without animating grey tablets or green moss. Sealed Chamber dot patterns
are decorative; they are NOT a transcription of the game's Braille puzzles.

`output/oasc-ruins-paper-20261001/native-water.log` passes all six actual native
battle fixtures, full Dig visibility on both sides at three zooms, native actor
visibility, continuous motion, quiet-event pause and field/music return. Mirage
Tower and Victory Road play through Dig wins. `clips-gpu.log` passes folding and
visible motion for all six and writes four-second 24 fps clips. Early failures
(particles behind stone layers and a bright-water threshold missing muted water)
were corrected in rendering, without weakening the tests. One intermediate run
also failed during a concurrent RoomLightRig/config edit; the final fresh run
passes. These fixtures do not verify puzzle progression or event unlock rules.

### Ship rooms, Trainer Hill and Trick House — 2026-10-01

`EmeraldRoomTerrariums.lua` adds Abandoned Ship, S.S. Tidal, Trainer Hill and
Trick House, each with 17 separately folding paper cards. Four generated alpha
atlases and their exact prompt/source records are in
`ROOM_PLACES_PROVENANCE.json`. The current ball and mirrored lid are reused.
Wreck water surrounds a dry raised timber platform; cabin walls, foreground
objects, hanging sails/curtains/banners and rotating puzzle cogs are independent.
The wreck's asymmetric clip polygons must be mirrored with their UVs to avoid
sampling adjacent wave fragments into the sail. No bitmaps were post-edited.

All four private trainer-battle fixtures passed actor visibility, full Dig holes
on both sides at three zooms, motion, event pause and field/music return in
`output/oasc-rooms-paper-20261001/native.log`. Wreck and Trick House were played
through to Dig victories. This does not validate Trainer Hill challenge rules,
ship travel, Trick House puzzle progression or event persistence. The private
F4 host now offers 72 scenes; restart it to reload the new code and assets.

Final room checks: `wreck-final.log` and `wreck-gpu-final.log` recheck the
corrected mirror/gutter mask, including another Dig win and 96-frame clip.
`clips-gpu.log` covers the other three clips. `Schiffe-und-Raetselraeume.html`
contains all four clips and native battle screenshots. Habitat and ambient
unit tests pass; the coverage assertions were updated for Granite Cave and
Faraway Island now having dedicated artwork rather than shared placeholders.
The fresh 519-map classification audit renders all 74 registered illustrated
variants. The review still has 28 missing designs and 9 shared substitutions,
alongside 56 dedicated and 17 base contexts (110 total, including noncombat
rooms). This is unfinished coverage, not visual acceptance or performance QA.


### Towns, museum and battle tents — 2026-10-01

EmeraldTownTentTerrariums adds Mauville, Lilycove, Slateport, Oceanic Museum and
three different Battle Tents, each with 17 separate folding cards. Native
fixtures pass actors, full Dig at three zooms, continuous motion, ambient pause,
and field/music return (output/oasc-towns-paper-20261001/native.log).
Mauville and Museum include Dig victories. Seven 96-frame motion clips and
native screenshots are in Staedte-und-Kampfzelte.html. TOWN_TENT_PROVENANCE.json
records built-in image generation and all prompts/sources. This does not test
rental teams or the tents' special rules. F4 test host has 79 scenes at this step.

### Secret bases, Navel Rock and submerged wreck — 2026-10-01

EmeraldBaseEventTerrariums adds cave/tree/shrub interiors, Navel Rock summit and
bottom, and the underwater Abandoned Ship. Six preserved-alpha atlases, 17
independent cards each; BASE_EVENT_PROVENANCE.json contains original prompts
and built-in imagegen sources. Hanging banners, drifting clouds, flowing water,
swaying kelp and quiet events are separate from the original ball/mirror shell.
Water surrounds raised dry platforms. Wreck bubbles use the visible foreground
water instead of spawning behind the raised arena.

output/oasc-baseevents-paper-20261001/native-verified.log passes all six native
fixtures; tree base and underwater wreck include Dig victories. clips-gpu.log
passes all six motion/fold/pause checks and 96-frame clips. Review gallery:
Geheimbasen-und-Nabelfels.html. Private QA excludes native map-entry/return scripts
for these synthetic fixtures; the initial cave-base test otherwise started a
scripted walk. No event-unlock, capture, base-decoration or persistence claim.
The wood interior currently shares its artwork with general house contexts;
this is not a claim that each house has individually matched furniture.
F4 test host now has 85 scenes; fully restart to reload.

### Remaining town set, suspended cards and aspect composition — 2026-10-01

Ten additional town contexts now have illustrated layers: Dewford, Lavaridge,
Mossdeep, Frontier exterior, Ever Grande, Petalburg, Littleroot, Oldale,
Verdanturf and Fallarbor. REMAINING_TOWNS_PROVENANCE.json preserves generation
prompts and original sources. Their native fixtures, full Dig holes at three
zooms, ambient motion/pause and field/music return pass in
output/oasc-towns2-paper-20261001/native.log; Dewford and Lavaridge include Dig
victories. Weitere-Hoenn-Staedte.html contains ten motion clips. F4 offers 95
scenes. These are presentation fixtures, not city-script progression tests.

Lid cards now attach to the original hinged mirrored lid with visible threads.
Attachment endpoints follow each card's actual alpha edge. Disconnected alpha
islands in rectangular lid cards split into separate meshes and staggered folds;
Littleroot therefore has four independently suspended clouds and 19 cards.
This does not semantically split connected buildings or foliage in every atlas.
hanging-final.log and the Littleroot clip cover the split clouds and settling.

ResponsiveLayout samples usable window aspect, not pixel resolution. Portrait
uses compact anchors; landscape interpolates toward wider anchors; expansion
is capped at 21:9. Trainer anchors and podium cards move together. Pokémon on
raised platforms reserve 18 world units around their anchors for full Dig holes.
Authored anchors remain immutable across repeated resize operations. Camera
framing follows the same bounded interpolation; the ball remains round.

gen3_terrarium_camera_test covers aspect equivalence, bounds and repeat resize.
gen3_responsive_terrarium_play_test checks both Dig holes at three zooms in four
aspect layouts and actual window changes at 600x900, 960x540, 1280x720 and
1400x600. Responsive-Papierbuehne.html compares the layouts in identically sized
captures. These earlier captures still used the native 240x160 outer frame. The separate
window/HUD composition described below now replaces that outer-frame limit.
The actual mode-change test found the static paper swatch was a Canvas cleared
by setMode. It is now retained as an Image. responsive-window-fixed.log passes
all four window sizes, ambient visibility/pause and native battle/music return.

Fresh coverage review: 519 map classifications, 97 registered rendered variants,
110 design contexts: 79 dedicated, 17 base, 5 shared substitutions, 9 missing.
Missing: contest/link, Devon/lab, Center/shop, Hall of Fame, harbor/truck.
All 97 GPU variants rendered in coverage.log. Counts describe implemented
coverage, not visual acceptance, universal matching or performance approval.

### Devon, Birch's lab and Hall of Fame — 2026-10-01

EmeraldResearchTerrariums uses three preserved-alpha atlases, each containing
twelve different objects rather than one assembled backdrop. Fifteen separate
cards compose Devon/lab; eighteen compose the Hall. Atlas bounds were measured
from alpha-connected components, avoiding cut edges at nominal grid boundaries.
RESEARCH_PROVENANCE.json records built-in imagegen prompts and original sources.
The existing shell/mirrors and safe raised battle platform remain unchanged.

Devon's paper rotor turns, cyan monitors animate, and a quiet steam puff emerges
at the restoration chamber. The lab has a suspended botany chart and independent
plant motion. The Hall has individually suspended drapery, wreath, star and
ribbons; six record lights appear in sequence during an idle event. Early
captures exposed clipped upper hanging props, which were repositioned before
the final native and GPU runs.

output/oasc-research-paper-20261001/native-final.log passes all three native
fixtures, including full Dig holes on both sides at three zooms, actor visibility,
ambient motion/pause, and field/music return. Devon includes a Dig victory.
gpu-final.log covers folds and three 96-frame clips. ambient-unit.log passes.
The review is Forschung-und-Ruhmeshalle.html; the private F4 host now offers
98 scenes. Lab and Hall battles are synthetic presentation fixtures, not claims
of natural encounters there. Map scripts are excluded in QA only; Hall record
persistence and actual story progression were not exercised.

The fresh audit renders all 100 registered illustrated variants and classifies
519 maps: 82 dedicated, 17 base, 5 shared and 6 missing design contexts. Still
missing: contest, link, Center, shop, harbor, truck. Shared underwater contexts
and quality refinement remain unfinished. These counts do not prove visual
acceptance, complete location fidelity or runtime frame-rate targets.


### Aspect composition refinement (2026-10-01)

ResponsiveLayout now interpolates explicit portrait, 3:2, 16:9 and 21:9
profiles. The previous single wide interpolation gave ordinary 16:9 only
4.7% extra actor spread; the dedicated landscape stop gives 12%, with the
same bounded maximum at 21:9. Green's native actor gaps are 58.8, 70, 78.4
and 82.59 world units after the full-Dig platform safety clamp. The actual
ball geometry is not stretched. All sampling still uses safe window aspect,
never framebuffer resolution.

Panel positions, support strips, static shadow placement and upper hanging
thread attachments now share ResponsiveLayout.panelX. Previously the lid
thread tops used unscaled author coordinates while the hanging card moved
with the responsive scenery. Native Green four-aspect / three-zoom tests and
actual window changes pass in output/oasc-responsive-review-20261001/native.log.
Unit coverage checks the landscape stop, continuous monotonic transitions,
720p/4K aspect equivalence, trainer/podium alignment and 100 round-trip resizes.
Vergleich.html contains native comparative renders. The existing 240x160 HUD
compositor remains a separate limitation; this does not provide edge-to-edge
ultrawide rendering.

The trainer battle resize regression exposed cached trainer Canvases becoming
blank on setMode. Trainer capture keys now also include logical window and
framebuffer dimensions, so same-aspect size changes redraw both portraits.
The native responsive test explicitly checks nonempty trainer captures after
every mode change and redraws after restoring the original mode. The complete
trainer battle then wins and returns to map music in trainer/native-fixed.log.


### Bespoke submerged scenes and service/travel interiors (2026-10-01)

Five former shared underwater substitutions now have separate illustrated
atlases: reef routes, Sealed Chamber, Seafloor Cavern entrance, Sootopolis
crater, and Marine Cave entrance. EmeraldUnderseaTerrariums composes kelp,
coral, rock slabs, ruins, independent fish and hanging current ribbons. The
original hinged mirrored lid is retained. A separate `basin` flag selects the
curved wet floor, refraction, bubbles and shadow pass without reusing the old
sea lid arrangement. Raised limestone-paper ground and trainer columns remain
above the water. The new opaque floor is `undersea-sand-floor.png`.

Undersea UV review found neighboring coral tips beneath three ribbon crops.
Marine's bounds end before those tips; reef and braille now use shaped polygon
cuts to retain the complete low wave tips while excluding the unrelated
adjacent motifs. Bitmap alpha is not rewritten. Native `native-edges.log`
passes all five scenes with both trainers, full Dig at three zooms, map/music
return, plus reef/cavern victories. After the cut refinement,
`gpu-cutouts-final.log` passes all five motion/event/pause/fold checks and
96-frame clips. Marine's Kyogre shadow follows the front water lane at y=-6
with peak alpha .22; the event changed 1107 pixels in the final GPU probe.
Evidence: output/oasc-undersea-paper-20261001/Unterwasserwelten.html.

Four further illustrated contexts are registered via EmeraldServiceTerrariums:
Pokémon Center, Poké Mart, harbor/shipyard, and the moving truck. Each starts
from twelve different original cut-paper atlas objects. The resulting scenes
have 15, 15, 17 and 17 cards, including separated hanging motifs. Center has
six sequential healing socket lights; the shop has a floating receipt and a
small rocking product carousel; harbor has suspended gulls, flags, a rocking
ferry and water movement; truck straps swing and its cargo occasionally rocks
with dust. These rare events pause during combat and reset between battles.
They do not heal Pokémon, alter inventory or consume game RNG.

Harbor's dock props now stand on thin side piers, clipped to the round bowl,
with downward paper posts. Shadow receivers include those pier tops. The
central combat platform remains above the water with full Dig clearance.
Foreground props were repositioned after the native probe found a medicine
cart covering part of the player trainer. Final native captures show all four
actors unobscured. `native-final.log` passes all four contexts, both Dig holes
at three zooms, ambient visibility/pause, continuous motion and map/music
return; Center and Harbor also complete actual Dig victories. The harbor
victory fixture uses Marill: the initial Wingull fixture was immune to Dig
and correctly could not be defeated by the single-move test driver.
`gpu-clear.log` validates all four folds and 96-frame clips at 24 fps.
Ambient and habitat unit tests pass. The low FPS overlay in synchronous
pixel-readback QA screenshots is not a gameplay performance benchmark.

Assets `service-*-kit.png` are unmodified built-in image_gen RGBA outputs.
Exact prompts/source locations: SERVICE_PROVENANCE.json. Original underwater
prompts are in UNDERSEA_PROVENANCE.json and UNDERSEA_FLOOR_PROVENANCE.json.
The private F4 test launcher now includes 107 scenes, with the four new
service/travel scenes first. Restart the launcher to load the revised code.
Tests use synthetic native battles on these maps and suppress fixture map
scripts; they do not add encounters to Centers, shops or the original truck.
Review: output/oasc-services-paper-20261001/Innenraeume-und-Hafen.html.

Fresh complete audit: 519 maps, 110 design contexts: 91 dedicated, 17 base,
2 missing, zero shared substitutions. All 108 registered variants rendered in
coverage.log. Missing artwork contexts: facility:contest and facility:link.
This is not full goal completion: double/link/safari and other special native
battle paths remain outside this single-battle provider; every existing scene
still needs the broader fidelity/quality and performance acceptance audit.
The native 3:2 HUD compositor also still limits edge-to-edge ultrawide layout.


Special battle follow-up evidence: the native double UI calls draw_mon_sprite
with battler IDs 0..3, but presentation.drawBattler/poseCenter still receive
only player/enemy (src/core/game3/battle/ui.lua:1924,1995). Removing the
adapter's st.double guard alone would therefore duplicate/misplace sprites
and effects. Completing doubles needs an optional battler-ID presentation
seam, four independent capture/effect/ground anchors, target/order handling,
and native multi-battle regression fixtures. Link/contest artwork alone would
not establish support for those native game modes.


### Separate Emerald battle window / HUD composition — 2026-10-01

BattleViewport now places the native healthboxes at the available top corners
and the native command/dialogue panel at the bottom of the usable window.
The lit world and native FX are composited separately on black, with uniform
scales (no ball/sprite stretching). Native 240x160 coordinates and engine menus
remain unchanged internally. The scene's existing aspect-based battle anchors
remain the shared source for actors, shadows, throws, Dig and native effects.

Portrait fits the actual final opened shell in its source camera before window
composition, so its formerly clipped lid is no longer a floating flat cutoff.
This fit is cached per scene, independent of opening progress; manual zoom still
works. Touch controls reserve the lower deck using their actual custom positions,
with the hotbar reserved above the HP panels. The camera samples this same usable
rectangle. Bag, party, Help and other fullscreen menus remain whole centred native
surfaces rather than being split into HP/menu pieces. Native screen veils cover
the full output. On exit or a native/map view, the normal compositor resumes.

The small additional engine patch is gen3/engine-patches/battle-viewport.patch
(applied after battle-presentation.patch). It adds optional beginHud/endHud draw
callbacks and presentationHudVersion=1. Engines without it retain the previous
3:2 frame. The local Emerald launcher already uses the patched engine. No player
save is read or written by these QA runs.

Evidence in output/oasc-responsive-review-20261001/full-window/:
- portrait-framed, touch-framed and ultrawide-final: real trainer battles, all four
  actor bounds within the available window, native move menu, bag, party menu,
  native/terrarium switches with identical HP/AP, Dig victory and map/music return.
- ultrawide-final also covers both complete Dig holes at three zooms in four
  aspects, actual window changes, trainer recapture and resolution independence.
- wide: original 1280x720 smoke run of the new compositor; wide geometry remains
  unchanged by the subsequent portrait-shell fit.
- wild-balanced: native dialogue during opening, native throw during Go text,
  correct actor order, 11 distinct appearance poses and 76 Dig partial-cutout
  frames through descent, underground, emergence and restoration, then victory.
- wild-cinematic: 353 observed native intro frames, no second Snorlax entrance,
  Dig hiding, victory and map/music return.
- gen3_battle_viewport_test.log: proportional layout at 720p/4K, HP/menu bounds,
  touch deck/hotbar reservation. Camera/card lifecycle regression tests pass.

The earlier full-window/wild run used the cinematic-only handoff probe with a
balanced overlapping intro and failed its observation-window precondition. The
explicit balanced-dialogue and cinematic-handoff runs above cover the respective
modes. Intermediate portrait/touch folders document the menu-split and lid-cutoff
repairs; the *-framed and ultrawide-final folders are the final viewport evidence.
This is not completion of all Emerald battle situations: double/link and other
special battle support and the full art-quality audit remain separate open work.

Current aspect-ratio request revalidated against the working tree:
`output/oasc-responsive-review-20261001/current-validation/native.log` covers
portrait, 3:2, 16:9 and 21:9 with both Dig holes at three zoom levels, actual
600x900 / 960x540 / 1280x720 / 1400x600 window changes, native menus, view
switches and a completed battle with map music restored. The two 16:9 windows
produce the same actor spacing (78.4 world units); portrait uses 58.8 and 21:9
uses 82.5916 with the Dig safety margin. `current-touch/native.log` repeats the
native menu and battle lifecycle checks at 600x900 with touch controls enabled.
These checks cover the Green single-battle stage; they do not certify unfinished
double-battle work or every authored habitat's placement.

### Emerald four-slot terrariums

`battle/BattleSlots.lua` preserves native battler IDs 0/1/2/3 across sprite
capture, fitted geometry, pose centres, target bounce, particles, send-outs,
Dig, faint folding, shadow casters and point lights. The optional engine seam
`engine-patches/battle-slots.patch` adds the ID as a trailing callback argument
and advertises `presentationSlotsVersion=1`; apply it after the viewport patch.
Older engines retain native doubles. Battle commands, damage, parties and
native animation callbacks are unchanged.

The Emerald scene owns four distinct depth anchors. Shared raised floors keep
all four Dig apertures within their edge. `terrarium/DoublesLayout.lua` gives
sea and freshwater scenes four separate dry paper rock caps and moves those
caps with their actors during aspect changes; the single-battle art is not
mutated. One front freshwater reed is moved aside for the front partner's Dig.
Each native ball-open event drives that slot's foot-anchored paper unfolding.
Four native HP panels retain their target highlighting and values. The stage
shader now accepts four flame lights at the corresponding floor heights.

Evidence: `output/oasc-double-paper-20261001/`:
- `psychic-menus`: Mossdeep scene, six independent visible figures, four complete
  Dig apertures at three zoom levels, native move/bag/party menus and native/view
  switches preserving HP/PP for all four battlers, two targeted Digs, two enemy
  faint folds, victory and map-music restoration.
- `forest-touch`: the same lifecycle on the raised Green floor at 600x900 with
  touch controls and all figures inside the usable viewport.
- `sea-verified` and `pond-clear`: four dry caps, all four Dig apertures at three
  zooms and both native player Digs through enemy fainting and map return.
- Six unit/regression logs cover slot identity, particle host/target mapping,
  self-target transforms, native-state restoration, aspect changes, pedestal
  alignment, engine feature gating, HUD bounds and presentation teardown.
- `single-regression` retains the native wild dialogue, animated Charmander
  appearance, 76 partial Dig cutout frames, victory and map-music restoration.
- `forest-floorlight` additionally checks the flame's actual elevated floor
  height and repeats four-slot Dig geometry and the full native battle lifecycle
  after that lighting adjustment. `Doppelkaempfe.html` links the reviewed scenes
  and actual partner-Dig phase captures.

The native QA fixture uses the same OT ID for both own Pokemon. Earlier runs
used a foreign OT for Squirtle, which correctly triggered native disobedience
and did not reliably execute the requested Dig; those are diagnostic runs,
not final evidence. An early render also exposed a missing partner source
capture, now covered by six-source pixel checks. `psychic-final` encountered a
transient, unrelated DioramaConfig parse error during concurrent world work;
`psychic-menus` is the subsequent verified run. `pond` records the front-reed
occlusion repaired and verified in `pond-clear`.

This enables ordinary Emerald doubles in terrarium view. Multi-trainer/AI
partner support is described below. Link, Safari and tutorial presentation
remain separate open work. Not every authored habitat has received a four-slot
visual audit yet; these tests do not claim completion of that audit or of the
overall art goal.

### Emerald partner battles and two opposing trainers

`BattleSlots.actorKeys` includes a second trainer on each side. The two native
`drawTrainer(side)` hooks compose those portraits independently; no additional
engine seam is needed. The partner portrait comes from the native trainer ID
(Steven for the Space Center story), and the second opponent uses `trainerB.pic`.
Each player-side ball resolves its actual owner through `BattleSlots.trainer`.
Steven's native 64px portrait uses hand pixel (14,35), mirrored with his portrait,
rather than borrowing Brendan's hand. Native spin still owns the throw clock.

`DoublesLayout.trainers` copies the scene's existing paper podium material for
each extra trainer, retaining its ground height and local foot offset. Two rows
at z=38/-24 remain distinct; `ResponsiveLayout.panelX` attaches the podium to its
own trainer across aspect changes. Stage cache keys distinguish partner and
two-opponent compositions. The original single/double artwork is not mutated.
Optional `multi` positions recompose individual authored props. In the Space
Center they move side consoles behind the rear podiums and low equipment into
the gap between trainer rows; the previous placement covered Steven's legs.

Evidence in `output/oasc-partner-paper-20261001/`:
- `space-clear`: four complete original trainer portraits, four mon sources,
  four full Dig apertures at three zooms, native AI commands, both enemy faint
  folds, victory and map music 399 restored. This is the small deterministic
  presentation fixture, with Charmander/Squirtle and two low-level opponents.
- `steven-surf`: native `Story.stevenParty` and `BattleBridge.twoOpponentFoe`
  supply Steven's three real Pokemon and all three Pokemon belonging to each
  Space Center opponent. The private player's Blastoise is level 100 so the
  run can exercise all six opponents, Dig, Surf, replacement send-outs and the
  win lifecycle. It is a presentation test, not a story difficulty benchmark.
  Native move/bag/party menus and native/terrarium view switches preserve all
  four battlers' HP/PP. All eight figures fit inside the available window.
- `two-trainers-forest`: three trainers/four Pokemon at 600x900 with touch
  controls, complete portraits and Dig holes, both player commands, menus,
  view switching and a real win followed by map/music return.
- `two-trainers-sea`: the same three-trainer ownership on the sea stage,
  original sea podium materials, four dry Pokemon caps, full portrait pixel
  coverage, both Digs, faint folds, victory and music 361 restored.
- `steven-touch`: repeats the real partner/six-opponent lifecycle at 600x900
  with touch controls, all eight figures inside the safe surface, unchanged
  HP/PP through menus/view switches, and the original partner hand/ball endpoint.
  Captures `multi-surf-15/40/70/110` expose a remaining visual defect: the native
  full-arena Surf task is passed through the two-point task shear and becomes
  a slanted rectangular wall. The move completes correctly, but this is not
  acceptable effect-quality evidence. Separate arena-wide task fitting from
  local attacker/target fitting next; preserve native frame, alpha and callbacks.
- `gen3_multi_trainer_layout_test` checks matching authored podiums for all
  109 current registry entries. It does not claim visual approval for all 109.
  Slot/ball, aspect, engine-gate, effects and presentation-lifecycle tests cover
  owner selection, independent anchors and unchanged single-trainer artwork.

Earlier `space`, `steven-story`, `steven-full`, `steven-verified` and `steven-six`
folders contain diagnostic runs: console occlusion; raw ROM-party fixture rows
that needed native normalization; too-short full-party timeout; a QA observer
using pairs() on metatable battler aliases; and real native losses with the
underpowered single Charmander. They are not completion evidence. The final
observer iterates native IDs 0..3 and counts unique party indices, including
opponents that switch out and return. No player save is read or written.

Remaining scope includes special-mode presentation (Safari/link/tutorials),
the outstanding location artwork, and a visual/animation audit across every
habitat. These partner-battle checks do not close the overall terrarium goal.

### Arena-wide Surf and current aspect regression (2026-10-01)

`terrarium/SurfWave` replaces only the Emerald terrarium drawing of the native
`CreateSurfWave` task. Three separate paper crests travel inside the circular
arena footprint; each crest tapers at the floor boundary. Other tasks retain
their local attacker/target transform. Task draw functions are restored after
each native draw pass, including on errors. The real pret task overrides the
older procedural implementation: its `data[2]` scroll counter and `_scan[1]`
blend coefficient supply progress and opacity. Native updates, sounds, hit
timing and callbacks remain in the engine.

`output/oasc-surf-paper-20261001/ported-clock` contains actual battle captures
at four Surf phases and a complete Steven partner battle through all six enemy
party slots, victory and restored map music. The observer verifies that drawing
preserves native counters, blending values and callbacks and actually creates
the crest mesh. The earlier `steven-touch` slanted-wall captures above are
historical evidence, superseded for this case. Geometry tests cover both travel
directions and the raised sea floor. Opponent Surf and the full range of stage,
zoom and aspect combinations still need native visual review; this is not a
claim that every attack effect has been approved.

`output/oasc-responsive-review-20261001/latest-check` revalidates the current
single trainer battle: portrait, 3:2, 16:9 and ultrawide compositions; complete
Dig apertures on both sides at three zooms; actual 600x900, 960x540, 1280x720 and
1400x600 window changes; native move/bag/party menus and view switches without
HP/PP changes; victory, field return and music 366. The camera unit test also
checks identical composition at 1280x720 and 3840x2160 and repeated resizing
without accumulated anchor drift. These are presentation checks, not FPS
benchmarks. The existing lid and mirrors stay round; individual lid cards
remain attached to their own suspension threads.

### Emerald Safari presentation (2026-10-01)

Emerald Safari now uses the terrarium with only the wild Pokemon and player
trainer. The native intro still announces the wild Pokemon; the paper dialogue
then becomes ready without inventing a player send-out. No player Pokemon
sprite, shadow, flame light or ball throw remains in this mode. Other editions
retain the existing native Safari gate.

`CatchPresentation` fits the native catch trajectory from the original trainer hand
to the wild Pokemon and paper floor. Catch simulation and BallOpen updates stay
in native coordinates; drawing fits the ball and opening particles only. The
native Pokeblock starts at the trainer offset (-18,+12) and ends below the wild
sprite (+32); `EffectFit` gives that projectile its own endpoints so it does
not launch to the left of the trainer. Callback coordinates and offsets are
restored after drawing. Emerald scenery has a transparent silhouette over a
separate black background, preventing palette flashes from exposing the edges
of the logical canvas on wide windows.

The engine previously updated the Pokeblock modal but did not forward input
to it during battle. `engine-patches/safari-pokeblock-input.patch` repairs the
native HUD for its owning Safari phase, preserving the opening-press guard.
Selection, cancellation, consumption and battle results remain engine-owned.
The patch is applied in the local Emerald engine and reverse-apply checks pass.

Native evidence in `output/oasc-safari-paper-20261001/`:
- `fitted-block`: case selection, native throw/reaction, exactly one Pokeblock
  consumed, flight from the hand toward the opponent, escape and map music 428.
- `verified-block_cancel`: cancellation consumes no Pokeblock, then escape.
- `black-flash`: actual successful catch, hand flight, shrink, floor bounce,
  preserved native catch state through drawing and an in-flight view switch,
  black margin during the palette flash, and map/music return.
- `fitted-catch`: six native attempts before success; exactly six balls spent.
  The test counts native catch starts, rather than assuming a first-ball catch.
- `fitted-breakout`: failed catch restores the native wild sprite, then escape;
  exactly one ball spent and map music restored.
- `near`: 600x900 with touch controls, GO NEAR and native wild flee, unchanged
  player party and map music restored.
- `catch-verified/safari-leaf-gust.png`: the Safari idle event emits separate
  leaf pieces. Its earlier `catch-on-floor.png` is an incorrectly timed QA
  capture and is superseded by the actual floor captures in `black-flash`.

Unit coverage includes Safari dialogue, mode/slot gating, the native modal's
input ownership, hand/floor endpoints and effect-state restoration. Ordinary
single-battle regression in `oasc-responsive-review-20261001/safari-regression`
rechecks the four aspect profiles, both Dig apertures at three zoom levels,
native menus/view changes, victory and map music 366. These are presentation
checks, not performance measurements. `safari-regression-touch` additionally
passes a complete 600x900 trainer battle with touch controls after the final
black-background fix. Six screenshot samples outside the silhouette confirm
that the catch palette flash leaves those margins black. The full location-art audit, link and
tutorial presentation, and remaining special-mode edge cases are still open.

### Wally, ordinary catching and detailed pond revision (2026-10-01)

Emerald's Wally tutorial now uses the terrarium, its original Wally front
portrait and a portrait-specific hand anchor. The native story special,
temporary Zigzagoon, two scripted attacks, recall and guaranteed Ralts catch
remain engine-owned. Other tutorials and other editions keep the native gate.
`oasc-wally-paper-20261001/route102` and `touch` validate the canonical
`EM_ROUTE102` story path, restoration of the original private QA party, no
Ralts added to that party, view switching without controller/state mutation,
and restored map music 359. The touch run is 600x900. Earlier `native-story`
used an invalid map key and is not evidence of correct field/music return.

Catch fitting now also covers ordinary Emerald captures and uses the actual
native target slot. Native callback coordinates stay unchanged; only drawing
maps the hand, flight, shrink particles and floor bounce into the paper stage.
The ordinary catch driver navigates the real Bag menu, consumes actual balls,
stores the caught Pokemon through native logic and checks unchanged player
HP/PP. `oasc-catch-paper-20261001/pond` passed with two attempts; the revised
pond run in `oasc-pond-v2-20261001/native` passed with ten. Both restored field
music 359. Closed-ball cinematics now explicitly fill their surrounding area
black, as the normal scene already does.

The pond replaces the simple distant hills with a transparent botanical atlas:
two distinct willows, wetland banks, reeds/iris and lily pads. Runtime cards
remain separate (23 panels); their existing four dry rock anchors are retained.
Independent plant sway, floating lily pieces, moving water and the pond idle
event remain active. Upper cloud cards in pond, meadow and ordinary route
layouts use the lid suspension attachment. The new bitmap was generated with
the built-in image tool; `data/emerald-terrarium/POND_V2_PROVENANCE.json` records
its full prompt and source. This is an authored revision, not user approval of
the whole art set.

`oasc-pond-v2-20261001/art` passes actual GPU continuous motion, idle-event
pause and four folding phases. `battle` passes a full native battle, both Dig
apertures at three zoom levels, ambient motion and restored field music 359.
The 109 registered multi-trainer podium layouts also pass their geometry test.
Those checks do not replace individual visual review of every battle location.
Link battles and the remaining location/animation audit are still open.

The final pond `double-trainer` run also passes four send-outs, both player
command owners, both native Dig sequences, both opponent faints, victory and
map music 359. Visual review confirms all four Pokemon stand on separate dry
rocks without foreground foliage cutting through them. The earlier `doubles`
folder requested an unsupported wild-double fixture and failed before a valid
double scene; it is diagnostic only. The final `safari-regression` catch passes
again after catch fitting was generalized, with one native throw, unchanged
player party and restored Safari music 428. `Pruefung.html` in the pond output
folder links the actual captures and logs, plus atlas/prompt provenance.

### Local-cable single/double battles and Link Colosseum (2026-10-01)

Emerald single and two-trainer double link battles now use a dedicated
`facility:link` stage, including off-field link launches. The existing ball
and mirrored lid remain. Fourteen separately mounted paper cards form the
scoreboard, red/blue communication stations, trainer steps, cable racks and
two suspended pennants. The terminals pulse continuously; a small connection
signal travels between them during quiet command menus and freezes in combat.
The generated transparent atlas and complete built-in ImageGen prompt are
`data/emerald-terrarium/link-colosseum-kit.png` and `LINK_PROVENANCE.json`.

Link scenes set `nonBlocking`: neither opening nor view switching returns a
native update hold, suppresses the original interface, or resets input when
opening ends. The shared engine supplies FR/LG Red/Leaf IDs (135/136); the paper
presentation resolves only those two IDs to Emerald Brendan/May front sprites.
Native trainer metadata and Union Room class portraits remain unchanged.

`tests/gen3_link_terrarium_play_test.lua` uses `Game3Link.loopback` and the
original `LB.beginBattle` controller. Its peer exchanges native action/switch
messages; it is not a second independently simulated game, so this does not
claim WAN synchronization testing. No relay or socket is opened. Native
post-link saving runs only inside the private QA identity; player saves are
never used. `oasc-link-paper-20261001/verified-single` passes seven exchanged
turn commands, a peer replacement, victory, field-party preservation, visible
Emerald peer portrait, view-switch/RNG invariants and field music 359.
`verified-double` passes the corresponding four-slot battle in four turns.
The earlier `single` and `double` captures lack the peer portrait and are
superseded. `art` passes continuous GPU motion, the idle-event pause and all
four folding phases. Four-player multi, spectator and recorded-link modes
remain gated pending their own ownership and runtime validation.

The refreshed `coverage` audit classifies 519 real maps plus seven surface
variants: 431 exact design matches, 82 base-family matches and 13 missing
competition-hall mappings (including unused halls). It renders 109 unique
designs, then completes an ordinary trainer battle and restores music 366.
This proves classification/renderability, not artistic approval or every
possible encounter surface. All 110 registered layouts pass the separate
multi-trainer podium geometry test. The remaining art/animation review and
special-mode work still prevent completion of the overall goal.

`oasc-link-paper-20261001/touch` repeats the complete local-cable single battle
at 600x900 with touch controls and the final first-frame UI fix. Both trainers
and both Pokemon remain visible above the controls. The popup lifecycle test
additionally checks all three intro preferences and both entry types: no link
clock hold, no interface suppression, no input reset, one opening sound.

### Four-player link and native spectators (2026-10-01, subsequent validation)

The preceding multi/spectator gate is now superseded for ordinary link battles.
Four-player scenes require the native double-battle flag and seat/gender maps.
BattleSlots resolves all four trainer identities, including the local player
in battler slot 2. Portraits use each seat's gender; both sides get two authored
podiums. Stage caching distinguishes multi from ordinary doubles. The current
ball, mirror lid, suspended pennants and aspect-based layout are retained.
Tower link multi and recorded-link battles still use native presentation.

`tests/gen3_link_terrarium_play_test.lua` now exercises original `LB.beginMulti`
with all four local seats. Protocol targets are canonical seat numbers, not
local rendering slots. The final evidence is in
`oasc-link-multi-20261001/verified-seat-0` through `verified-seat-3`.
Each run passes four native command turns, victory, unchanged field party,
correct trainer gender/ownership, both allied throw anchors, view-switch/RNG
checks and field music 359. Seats 2 and 3 use a 600x900 touch viewport.
Earlier non-verified seat 1/3 folders used an incorrect test-peer target and
are diagnostic only. Visual inspection of the final landscape and portrait
captures confirms all four trainers and their podiums remain separated.

`tests/gen3_spectator_terrarium_play_test.lua` drives the original
`LB.startSpectator` with in-memory setup/action packets. It asserts that the
viewer sends no battle commands, watched and local parties remain separate,
drawing/view switching do not advance RNG or turns, and opening never holds
the battle clock. Single, double and four-player modes complete one native
turn, victory, the spectator completion callback and restored map music 359.
Evidence is in `oasc-link-spectator-20261001/single`, `double` and `multi-touch`.
The last case uses a 600x900 touch viewport; all four watched trainers remain
visible. This validates presentation against native protocol/controller code,
not synchronization across independent devices or a live relay.

Relevant card, slot, popup lifecycle, viewport and all 110 registered podium
geometry checks pass. `oasc-link-multi-20261001/Pruefung.html` links final
captures and logs. Remaining work includes tower link, recorded cases and the
full location-specific art/animation audit; these results do not complete the
overall terrarium goal.

### Coastal paper layers, second art pass (2026-10-01)

Visual review of the current map sweep found rectangular water cards and a
detached atlas strip in the coastal backdrop. `EmeraldCoastTerrarium.lua`
replaces that layout with 21 independent cards: an irregular rock arch,
different palm/outcrop silhouettes, three overlapping alpha-bounded breakers,
dune plants, driftwood, shells and a small starfish. Two clouds and two seabirds
hang individually from the existing mirror lid. The waves hinge, flow and rise
at distinct phases; grasses/palm sway, birds gently move on their strings, and
the existing sea-spray event remains restricted to quiet battle periods.

The new `coast-botanical-v2.png` is the unmodified transparent built-in ImageGen
output after a refinement toward flatter cardstock and isolated contours.
`COAST_V2_PROVENANCE.json` records its source and generation request. The floor
and measured trainer ledges retain their original atlas and coordinates.
`floatPhase` is optional in the renderer; existing assets default to zero.

Evidence: `oasc-coast-v2-20261001/art` checks visible continuous motion, spray
and its combat pause, all folding stages, and contains 96 environment-only
frames at 24 fps. `battle` finishes an original trainer fight on Route 109,
restores map music 401 and preserves field/camera state. `responsive` repeats
that fight and checks both native Dig apertures at three zooms across four
aspect ratios, plus real window resizing with equivalent 960x540/1280x720
composition. All 110 registered multi-trainer podium layouts still pass.
`Pruefung.html` links the before/after images, animation frames and logs.
This is one corrected art family, not completion or approval of all terraria.

### Desert and ash route detail pass (2026-10-01)

`EmeraldDryRouteTerrariums.lua` replaces the rectangular desert ridges and
generic ash backdrop with two separately authored layouts. Route 111 sand
encounters have 19 cards: irregular mesas, overlapping dune silhouettes,
weathered fossil/ruin pieces, cactus plants, foreground dry vegetation and a
small rolling tumbleweed and two dust clouds suspended from the lid. The
tumbleweed is a textured card driven by
`AmbientMotion.cardPose`; it uses only the existing quiet-event clock and
freezes exactly during battle actions. It resets between scenes and is absent
outside the sand-gust habitat. No battle or RNG state is changed by drawing.

Route 113 has 19 cards: separate volcano/foothills, two different trees with
green leaves below the ash, glassmaker workshop with warm furnace detail,
three independently suspended smoke wisps, basalt and fern foreground pieces.
Vegetation and wisps move continuously; falling ash and occasional gusts remain
specific to that route. UV polygons exclude adjacent smoke fragments found in
the first visual review. The original floors and calibrated trainer podiums
remain unchanged. Both atlases are copied directly from built-in ImageGen with
alpha preserved; `DESERT_V2_PROVENANCE.json` / `ASH_V2_PROVENANCE.json` contain
the exact requests and source paths.

Evidence: `oasc-dry-routes-v2-20261001/{desert,ash}-art` passes GPU motion,
quiet-event freeze and folding checks and contains 96 frames at 24 fps for each
environment. `{desert,ash}-battle` completes native trainer wins and returns to
map music 360 / 418. Both runs also inspect both native Dig apertures at three
zooms and four aspect ratios and exercise real window resizing. The temporary
FPS values in those captures follow synchronous GPU readback/resize probes and
are not performance measurements; `*-runtime` supplies captures without those
probes. Ambient timing/pause/location checks, all 110 podium layouts and popup
lifecycle checks pass. Remaining locations and special modes still require
their own completion evidence; these two art passes do not close the goal.


### Open gym paper assemblies (2026-10-01)

The seven atlas gyms now omit their large opaque backing cards. Their open
roof/truss/tree frames show the existing mirror lid through the separate
structural pieces. Electric lamps (three), psychic moon/stars (five), sky
clouds (three), and water icicles (five) are individual lid-mounted cards with
independent fold timing, thread geometry and slightly offset floating phases.
The badge cards and other hanging assemblies also connect to the lid. Atlas
UVs preserve the authored shapes and original composition; the electric lamp
bounds exclude clipped wire fragments. No raster assets were modified.
Norman's seven individual doors retain three spatial tiers and the separate
banner assemblies. Floors and calibrated trainer podiums retain their original
materials and coordinates. Existing habitat effects remain: sparks, steam,
orbit details, dust motes, leaves and ice glints, alongside continuous motion.

Evidence in `output/oasc-open-gyms-20261001`: `art/native.log` covers all seven
folds, visible GPU motion, quiet-event pause checks and 96-frame sequences at
24 fps for each gym. `battle/native.log` completes seven native trainer battles,
checks that all four visible actor sprites remain unoccluded, and returns to
map music 364. `battle/water-final.log` repeats the water gym after separating
its icicles. These are private fixture battles in the gym maps, not the actual
leader teams. The QA cases now explicitly exercise combat instead of ending
after the art capture. `structure.log` checks independent geometry, per-piece
fold timing, hanging accents and Norman's seven doors. All 110 registered
multi-trainer podium layouts and the popup lifecycle tests pass.
`Pruefung.html` provides before/after, motion playback and battle captures.
The rest of the location quality audit and special-mode validation remain open;
this checkpoint does not establish completion of the full terrarium goal.

`psychic-double/native.log` additionally completes a native double fixture in
Mossdeep Gym: four send-outs, both player commands, two Dig sequences and two
faints, original victory and map music 364. This validates the four-Pokémon
layout with the revised scenery, not the actual Tate/Liza encounter script.


### Route 119 layered botanical revision (2026-10-01)

`EmeraldRainforestTerrarium.lua` replaces the photographic-looking rainforest
silhouette set with 25 paper cards: three different tree/leaf structures,
a separate rope bridge, stepped waterfall, hanging canopy strips and clouds,
individual foreground ferns, bromeliads, flowering leaves and a mossy log.
The original floor and measured trainer ledges remain intact. Lid cards have
actual strings and folding transforms. A UV polygon removes the adjacent
orange flower tip from both hanging canopy cards without editing the atlas.
`rainforest-layered-v2.png` is the unchanged RGBA output from built-in ImageGen;
`RAINFOREST_V2_PROVENANCE.json` records the exact prompt and source.

Three small textured rain cards share the habitat's quiet-event clock. They
fall at staggered times below the rain cloud, freeze during attacks, disappear
before leaving the scenery, and reset between battles. They cannot appear in
other habitats. Continuous water flow and plant motion use the existing water
clock. The shared card pose function retains the desert tumbleweed behaviour.

Evidence in `output/oasc-rainforest-v2-20261001`: `art/native.log` passes GPU
motion, event pause and folding checks and supplies 96 frames at 24 fps.
`art/water-ribbons.log` samples visible motion in all three waterfall ribbons,
separately from moving foliage. `battle/native.log` completes an original
Route 119 battle and returns to music 402; both native Dig apertures remain
visible at three zoom levels and four aspects, including real window changes.
Ambient pause/location/reset tests and all 110 multi-trainer podium layouts
pass. `Pruefung.html` contains before/after, motion playback and the native
capture. This is a verified art-family revision, not full-game completion.


### Native Duellturm Link Multi presentation (2026-10-01)

`Gen3BattleAdapter` now permits the Emerald Tower Link Multi setup when native
multi ownership and both NPC portrait IDs are present. Incomplete Tower setups
remain native. The existing `EmeraldScene` Tower exception keeps the
`facility:tower` artwork instead of using the ordinary link colosseum. Native
Frontier trainer pictures are retained; the two human avatars use their actual
Emerald genders. All four trainer podiums and throw anchors are stage-local.
The link clock is never held by the unfolding animation or a view switch.
No engine battle, AI, network or save code changed.

`gen3_link_terrarium_play_test.lua`, with `PAPER_LINK_TOWER=1`, now enters through
`TowerLink.startBattle`, exchanges the original Tower setup messages and drives
native multi actions/replacements to completion. The leader uses the engine's
virtual-seat AI callbacks. The guest receives AI action/switch packets produced
by those same original functions. Tests deliberately choose two different
Frontier trainer classes and compare the actual captured portrait image objects
against each native NPC image. Both human throw origins/targets and local menu
ownership are checked. All four opposing Pokémon, including both reserves,
must be seen. The original completion callback, field party HP/PP for both
members, released virtual ownership and field music 465 are checked on return.

Evidence: `output/oasc-tower-link-20261001/seat-0`, `seat-1` and `guest-touch`
complete native wins and callbacks; `guest-touch` also runs at 600x900 with
Touch controls. Rendering and native/terrarium switching leave battle RNG and
turn state unchanged. `Pruefung.html` shows both seats and the portrait run.
These are local protocol peers within one process, not a two-engine or WAN
interoperability test. The adapter unit gate covers complete/incomplete Tower
setups and still keeps the unvalidated ordinary map presentation gated.

The remaining `recordedLink` gate is separate: the current engine's Frontier
Pass queries `Rse.system('recordedBattle')`, but `Rse.MODULES` has no recorded
battle implementation and the record action returns to the pass when no
`play` function exists (`src/ui/game3/rse/frontier_pass.lua`). Saving likewise
reports the missing system in `natives_frontier.lua`. This is engine playback
availability, not evidence that recorded battles have been presentation-tested.
All-location visual review remains open.

`ordinary-multi/native.log` additionally rechecks ordinary four-player seat 3
through native victory and map music 359 after extending the shared QA driver.
### Mountain and Granite Cave layered art — 2026-10-01

`EmeraldMountainTerrarium` replaces the Route 114 backdrop with 21 independent
cards: three ridge depths, separate trail cliffs, a wind-bent tree, foreground
flora/stone/wood, two clouds and two birds suspended from the existing lid.
Polygon UV outlines exclude neighbouring atlas fragments. Wind pulses affect
the hanging birds and tree; continuous drift and foliage movement remain.

`EmeraldGraniteTerrarium` has 26 cards, including two transparent irregular
rock rims in front of a separate dark backing, five individually suspended
stalactites, separate side walls/ladders and foreground details. Three authored
paper pebbles replace the generic Granite event geometry. Their travel starts
at staggered times, rolls and bounces, and scales out at the interval ends.
The event pauses with combat, resets with the scene and remains Granite-only;
other caves keep their existing pebble events. Both variants retain the measured
trainer ledges, original arena footprint and responsive actor anchors.

Built-in Imagegen atlases `mountain-layered-v2.png` and `granite-layered-v2.png`
are copied as original RGBA; exact prompts/source names are in the matching
`MOUNTAIN_V2_PROVENANCE.json` and `GRANITE_V2_PROVENANCE.json` files.

Evidence: `output/oasc-mountain-granite-v2-20261001/Pruefung.html` links original
versus current renders, 96-frame environment clips, GPU fold/motion/pause logs
and native battle captures. Both native fixtures win, restore map music
(360/366), preserve field state and pass both Dig holes at three zooms/four
aspects plus actual window resizes. These are map-specific fixtures, not every
trainer script. Ambient timing, all 110 registered trainer layouts and popup
lifecycle regressions pass. Capture FPS includes synchronous image readback
and must not be presented as a runtime benchmark.
### Safari botanical layers and contest-name audit — 2026-10-01

`EmeraldSafariTerrarium` uses 23 independent cards from the unchanged built-in
Imagegen `safari-layered-v2.png` atlas. Exact prompt/source are recorded in
`SAFARI_V2_PROVENANCE.json`. Separate tree/forest planes, an open observation
stand, wetland water, reeds, fence, berries, log and suspended foliage/clouds
replace the previous large cutouts and repeated grass. Existing measured trainer
ledges and the native Safari anchor arrangement are retained.

A small paper butterfly occasionally rises over the foreground log using the
quiet-event clock. Its complete position/roll/yaw/scale pose pauses with battle
actions, is bounded to its event interval and resets with the scene. The shared
renderer now accepts optional ambient-pose yaw; previous ambient cards do not
use it. Ambient timing/location/reset tests and all 110 trainer layouts pass.

`output/oasc-safari-v2-20261001/Pruefung.html` contains before/after views, a
96-frame environment sequence, native Safari escape/PokeBlock/catch logs and
screenshots. The first unseeded catch fixture correctly let its target flee,
revealing that math.randomseed did not control the native timer/input RNG.
The QA driver now accepts optional `PAPER_SAFARI_SEED` through the engine's
existing rng argument, using its LCRNG arithmetic without overriding catch
rules. Seed 4 catches after three balls, leaves 27, preserves party HP/PP and
returns to map music 428. Unseeded escape and PokeBlock also pass.

The map audit found `CONTEST_HALL_SMART` matched the old substring MART check.
Shop recognition now requires the `_MART` suffix (department stores retain their
explicit rule). Tests cover the contest, a real Mart and a department store.
There are therefore 14 contest rooms without dedicated art, not the old count
of 13. Imported tables show no wild headers, trainer objects or direct battle
ops in the traversed static scripts. The output audit explicitly retains the
native-special/dynamic-target limitation, so these rooms are not yet excluded
from completion accounting on the strength of that static evidence alone.

### Canonical Emerald gym leader teams — 2026-10-01

`PAPER_BATTLE_QA_CANONICAL_GYMS=1` in the native paper battle driver now loads
the eight original first-match leader definitions through `Trainers.foeFromId`.
Their ROM parties, levels, moves, items, AI metadata and portraits are retained;
Tate/Liza uses the native double flag. The private QA party has two level-100
Mew to exercise presentation and replacements quickly. These fixtures start
through Battle.start, not the map's badge-award/progression scripts, and do not
write a player save or claim difficulty, rematch or progression coverage.

`gen3_canonical_gym_play_test.lua` checks native trainer portraits, party species
and levels, terrarium routing, every enemy party index entering the battle and
every paper faint. All eight native battles passed: 32 enemy Pokémon in total,
including both Tate/Liza replacements. The shared driver also checks victory,
map/player/camera restoration, map music 364, adapter cleanup and game reset.
All eight command-screen captures were visually inspected. There is no new
production behavior in this checkpoint; it strengthens the earlier generic
gym-fixture coverage with real leader teams.

Evidence: `output/oasc-canonical-gyms-20261001/Pruefung.html`, the seven leader
folders and `juan-fixed/native.log`. The initial `juan/native.log` is retained:
the QA controller repeatedly chose Thunderbolt against Ground-immune Whiscash
and hit the frame limit. The controller now chooses its own Psychic in that
case; enemy data and combat rules are unchanged. The corrected battle passes.
Use PAPER_BATTLE_QA_CASE with roxanne, brawly, wattson, flannery, norman, winona,
tate-liza or juan, Emerald version and terrarium view in the private QA host.

### Victory Road layered paper revision — 2026-10-01

The `cave:victory` registry entry now uses `EmeraldVictoryTerrarium`: 27
separate cutout cards replacing the previous miniature-rock composition.
An open cave rim reveals a deeper slate-paper recess; stairs, ladder, stream
and gently oscillating rope bridge occupy separate planes. Three stalactite
groups and two root cards hang from the existing mirrored lid. Foreground
rock/fern/mushroom silhouettes vary; original dry trainer ledges remain tied to
the same authored anchors. The ball, platform, viewport and battle hooks remain
shared with the other scenes.

`victory-layered-v2.png` is an unchanged 1536x1024 RGBA built-in imagegen output.
`VICTORY_V2_PROVENANCE.json` records the exact prompt and source. The actual
alpha is verified, including the opening through the cave rim. No atlas pixels
were postprocessed. Geometry selects and arranges its separate cutouts.

Victory Road now uses three textured rolling paper pebbles on the quiet-event
clock, with staggered starts, bounded travel, bounce and roll. Granite retains
its own cards; other caves retain their existing events. Unit tests confirm
travel, pause during battle actions, bounds, location isolation and reset.

Evidence: `output/oasc-victory-v2-20261001/Pruefung.html` has before/after scenes,
a 96-frame / 24fps environment sequence and the native battle capture.
GPU checks show animation in three individually sampled visible stream regions,
continuous motion, rare pebble motion, exact pause and all 27 folds complete.
All 110 registered multi-trainer podium layouts pass. The native Victory Road
fixture wins, restores map music 429 and verifies both complete Dig holes at
three zoom levels/four aspect profiles plus real window changes. Its actor
capture was visually inspected. The FPS overlay follows expensive QA readbacks
and is not a runtime performance benchmark. This is a scene-specific art/runtime
checkpoint, not completion of the remaining Emerald quality audit.

### Sootopolis land/lake paper assembly — 2026-10-01

`EmeraldCityTerrariums` now composes the crater rim from three independently
hinged contour meshes with overlapping cliff seams. The final masks retain
whole distant houses; initial split-house and vertical edge artifacts were
repaired before the final captures. Three clouds and two gulls hang from the
existing mirror lid with gentle drift/sway. They reuse unchanged existing
coastal paper atlases. Both crater variants have 26 cards and retain flowing
water, palm motion and the quiet fountain event.

The lake registry entry `sea:sootopolis` now selects a separate `crater_water`
layout rather than only swapping the promenade floor texture. Previously pots
and ornamental walls appeared to stand on the water. The lake layout copies
the land definitions, places small pots on the dry trainer ledges/front of the
main platform, and moves the walls to its dry rear edge. Native battle anchors
and the existing platform remain unchanged. The land layout retains its wider
promenade decoration; the copy does not mutate those definitions.

`gen3_multi_trainer_layout_test` checks all 110 podium mappings and the lake
decorations' dry support bounds at portrait, classic, wide and ultrawide aspects.
The first new test used a strict less-than-one depth allowance; the authored
enemy ledge is exactly one world unit behind its trainer feet. The check now
includes that boundary and all support tests pass.

`output/oasc-crater-layers-20261001/Pruefung.html` compares old/new land and
lake assemblies, includes a 96-frame/24fps land-scene animation and both native
battle captures. GPU tests confirm continuous water/prop motion, the quiet event
and its pause, and complete folds. Both native fixtures win, restore map music
445, preserve map/camera state, and pass both Dig holes at three zooms/four
aspects plus actual window resizes. Final captures were visually inspected.
These are presentation fixtures, not claims that those opponents occur naturally
in Sootopolis. The FPS overlays follow costly QA readbacks, not a performance
benchmark. The broader remaining art-quality audit is still open.

### Meteor Falls separate paper cascade — 2026-10-01

`EmeraldMeteorTerrarium` replaces the old three large deep-cave scenery blocks
for `watercave:meteor`. The assembly uses 36 cards: an open cave rim split into
three overlapping hinged contours, rear strata, separate stepped limestone
flats, three waterfall ribbons and four pool strips, supporting terraces,
three suspended stalactite groups, ferns, scree and a small meteor fragment.
An initial assembly left the pools floating; terraces and a central cliff now
connect the cascade to the ground. The round ball/mirror lid, dry battle disc,
authored trainer ledges and battle anchors are retained.
Elevated scenery uses the existing rigid rear paper supports, so the crown,
terraces and waterfall pieces rise from the floor during opening instead of
remaining suspended at their final height. The final fold capture and native
test were rerun after this correction.

`meteor-layered-v2.png` is the unchanged RGBA result of the built-in image tool;
`METEOR_V2_PROVENANCE.json` records its exact prompt and source. Source/destination
SHA-256 matched; the cave opening and atlas gutters have real zero alpha.
No generated image was cut or repainted offline. Runtime UV polygons select
the individual pieces. Other deep-cave registry entries retain their layouts.

Three textured `meteorDrop` cards now use the quiet-event clock, stagger their
fall beside the cascade, and disappear at the lower pool. Generic cave bubbles
are suppressed only for Meteor Falls, avoiding duplicate effects. Unit checks
cover staggering, gravity progression, combat pause, bounds, location and reset.
GPU checks sample each of the three falling ribbons and four pools in the final
composite; all seven visibly change independently of surrounding fern motion.
The event/pause and all 36 folds also pass.

`output/oasc-meteor-v2-20261001/Pruefung.html` contains the old/new comparison,
96 frames at 24fps, folding stages and the native battle capture. The private
native Bagon fixture wins and restores map music 386. Both Dig holes pass three
zooms/four aspects, actual window resize preserves actors, and all 110 registered
multi-trainer podium mappings pass. The fixture is presentation QA, not an
encounter-table claim. Final stage and native captures were visually inspected;
the FPS overlay after GPU readbacks is not a performance measurement. Remaining
habitat quality and coverage work is still open.


### Seafloor Cavern paper layers and Union Room entry — 2026-10-01

`EmeraldSeafloorTerrarium.lua` replaces the old three large Seafloor walls with
32 independently mounted cards: overlapping rear strata, side walls/ledges,
three lid-suspended stalactite groups, three water ribbons and three wave crests,
foreground shells/kelp/slate and three occasional paper spray droplets. The water
shares the low channel rather than floating on disconnected elevated shelves.
Native dry battle platform, trainer ledges, anchors and round mirror shell remain.
`seafloor-layered-v2.png` is the unchanged built-in Imagegen RGBA output; source
and exact prompt are in `SEAFLOOR_V2_PROVENANCE.json` (SHA256
`4ea35f531aa2914f3e9b6581f9cc4e1e4a42fee44fab2fdba6d3f666905c9aa1`).

Evidence: `output/oasc-seafloor-v2-20261001/Pruefung.html`. The GPU test isolates
each of the six water cards by hiding that card and comparing its visible pixels
with a second animation time; all six pass (both visibility and motion). Quiet
spray movement pauses during battle actions, is staggered/bounded, and cannot
appear in another cave. The 96-frame 24 FPS environment clip, opening poses and
native battle were inspected. Native fixture now runs an actual Dig attack and
wins against Carvanha (not an aborted preview); music 406 and map/camera state
return. Both Dig apertures pass three zooms/four aspects and actual window resize;
all 110 registered trainer podium layouts pass. This fixture does not claim to
exercise the complete canonical Aqua story script/roster. FPS captures include
synchronous GPU readback and are not performance measurements.

`PAPER_LINK_UNION=1` extends the native link fixture to boot the actual synthetic
`EM_UNION_ROOM_PLAZA` map and run its entry script. A test-only offline client
boundary installed before boot intercepts the map's joinPlaza call. The fixture
uses `Union.startActivity` -> `LB.startUnionRoomBattle` -> actual SETUP protocol
exchange -> `Union.pollInActivity`/`LB.pumpUnionSetup`, then normal link combat.
It verifies the native Union trainer class image (rather than a generic player
avatar), view-switch/RNG invariance, opponent replacement, victory, restored
field party and Union main state, same plaza map and map music 422. All occur over
an in-process cable, with no public relay. This is not a two-device network test.
The before/after field captures are identical outside the FPS rectangle (zero
changed pixels); the large plain green plaza floor already exists before battle.
Evidence: `output/oasc-union-plaza-20261001/native/native.log` and screenshots.

Coverage audit distinction: the ROM inventory contains 518 maps; the runtime
adds this 519th plaza. Existing battle.link selection correctly picks facility:link
for it, even though a terrain-only inventory cannot discover that choice. The
read-only battle-scope graph tool and its regression test are in tools/ and tests/;
current output is `output/oasc-battle-scope-20261001/`. Its 14 contest-map candidates
have no direct battle opcodes or wild tables, but this inventory alone is not a
proof of all possible native-special entry paths. Do not turn the registry's
map count or this single link fixture into a claim of complete quality/coverage.

### Marine Cave and Terra Cave individual cards — 2026-10-01

`EmeraldAncientCaveTerrariums.lua` replaces their large background slabs with
30 Marine and 32 Terra cards. Both use separate rear strata, side cliffs, dry
shelves, three lid-suspended stalactite groups and foreground details. Marine
has two waterfall ribbons, a ripple pool and four surf strips; Terra has two
lava falls, a channel and two foreground lava pieces. Dry native battle platforms
and trainer ledges retain their authored anchors. An asymmetric mirrored polygon
must mirror its geometry as well as its UVs; the new module does this to prevent
neighboring atlas fragments from leaking through the mirrored rear ridge.

`marine-layered-v2.png` and `terra-layered-v2.png` are unchanged built-in Imagegen
RGBA outputs. Exact prompts and original paths are recorded in
`MARINE_V2_PROVENANCE.json` and `TERRA_V2_PROVENANCE.json`. Three paper bubbles
or ember pieces use the quiet-event clock, stagger their rise, fade within bounds,
pause during combat, and reset on leaving the stage. Generic particles are
suppressed only for these two location variants to avoid duplication.

Evidence: `output/oasc-ancient-caves-v2-20261001/Pruefung.html` includes old/new
comparisons, two 96-frame 24 FPS environment clips, intermediate folds, native
battle captures and Dig/aspect screenshots. The GPU test isolates the visible
pixels of each water/lava card and verifies motion there: all seven Marine and
five Terra pieces pass. All 30/32 folds and event/pause checks pass. Ambient unit
checks and all 110 trainer podium mappings pass. Final stage, fold and native
battle captures were visually inspected; a stray rear-rock fragment was removed.

Both native fixtures execute Dig and win, then restore map/camera state and map
music 366. Both Dig apertures pass three zooms at four aspect ratios; real window
resizing also passes. These are level-3 Kyogre/Groudon presentation fixtures, not
proof of complete canonical level-70 encounter scripts, event flags or capture
conditions. FPS in captured runs includes synchronous readbacks and concurrent
QA work, so it is not a benchmark. Remaining habitat quality and full encounter
coverage are still open.

### Cave of Origin and Aqua hideout layered rebuild — 2026-10-01

`EmeraldOriginTerrarium.lua` replaces the old large painted cavern pieces with
30 cards: separate limestone sides and darker rear layers, five individually
suspended stalactites, two seep ribbons, three pools, ferns, limestone chips,
fossils and three timed paper drops. Two initially elevated ledges were removed
because their opening motion separated them from the falling-water cards; the
water now emerges directly from the rock faces. Original floor, dry trainer
ledges, platform and authored anchors remain. `originDrop` shares the deterministic
quiet-event implementation with Meteor drops but uses the Origin column heights;
unit checks compare each animated drop against its authored vertical bounds.

`EmeraldAquaTerrarium.lua` now has 25 cards instead of eight large scenery pieces:
separate cave contours, control console, door, two teleport decks, submarine,
two waves, three lid-mounted cable lamps and foreground slate/supplies. The
`aquaPeriscope` card rises behind the submarine hull and retracts before the quiet
event ends. Its lower end stays covered by the hull. An atlas-neighbor sliver
was removed with a contour on the first hanging lamp, without editing the PNG.
The Aqua floor now has a thin 70-unit-radius raised paper platform with UVs
matched to the underlying floor, and dedicated +/-35 Pokémon anchors. Portrait,
wide and ultrawide use the full responsive spacing range rather than the old
small scenery-only scale. Existing trainer podium shapes/materials remain.

Both new `origin-layered-v2.png` and `aqua-layered-v2.png` are unchanged RGBA
outputs from built-in Imagegen, copied into gen3/data/emerald-terrarium/. Exact
prompts and source paths are in ORIGIN_V2_PROVENANCE.json / AQUA_V2_PROVENANCE.json.
SHA256: Origin 79f4e008d44ac5b39939778d200e1a331739ea354e3a5001b75cf04d5293977f;
Aqua 9ff84ac44966b7ca9792713d3489c3a47c00a96fe78e1a6be18f3665d4afddac.

Evidence: `output/oasc-origin-aqua-v2-20261001/Pruefung.html` links old/new views,
96-frame clips for both, fold/native/aspect captures, prompts and logs. GPU
isolation verifies visibility and motion of all five Origin water cards and
both Aqua wave cards; a separate hide-card comparison proves the periscope is
visible rather than accepting only the blinking console. Final folds, stage
and native captures were inspected. Quiet-event pause/location/reset unit checks
and all 110 registered trainer podium layouts pass.

Native fixtures finish an attack and win, then restore field/camera state and
map audio (Origin 0, Aqua 430). Both Dig openings pass three zooms/four aspects,
including real window resizing. Origin uses Ember: the first Dig-only fixture
correctly failed to defeat Flying-type Golbat and timed out. Aqua now resolves
TRAINER_GRUNT_AQUA_HIDEOUT_1 through the Emerald registry, so its native trainer
portrait is the Aqua grunt, not the old default Hiker. Opponents remain level-3
presentation fixtures: this is not a canonical full-roster/story-progression
claim. Earlier failure logs are retained beside the successful runs.

A separate Aqua benchmark ran alone without readbacks during its timed intervals:
two 240-frame samples after warmup at 1280x720, full presentation, mean 5.675 and
6.202 ms; p95 8.726 and 9.645 ms. This is a frozen native battle rendering fixture
on this Mac, not full combat simulation or cross-device performance evidence.
The art QA screenshots' FPS is not meaningful due to synchronous image checks.
Full habitat quality and encounter coverage remain open.

### Magma, Fiery Path and Mt Chimney paper rebuild — 2026-10-02

EmeraldVolcanicTerrariums replaces the three volcanic entries' old combined
wall/ceiling/machine cards. Magma uses 30 separately hinged cards: irregular
cliff fins, separate red door, valve pipe and control console, six individual
lid-suspended teeth, lava ribbons and small foreground rock flats. Fiery Path
uses 27 cards with a dry floor and two vent openings; three textured paper
steam curls rise from the authored vents. Mt Chimney uses 24 cards with layered
crater rims, the existing meteorite apparatus, separate lava and paper embers.
The round shell, mirrored lid, native actors and shared responsive anchors stay
in use. The six ceiling teeth in both indoor variants retain hanging threads.

The new unmodified 1536x1024 RGBA atlas volcanic-layered-v2.png was generated
with the built-in image tool. Exact prompt, source and SHA-256 are recorded in
VOLCANIC_V2_PROVENANCE.json. Existing volcanic podium and meteorite assets are
reused as separate cards; tide/salt/ice layouts are unchanged.

Volcanic paper events use the quiet-event clock, stagger three individual cards,
pause exactly during actions, remain within bounded motion, and reset on exit.
The first GPU probe exposed a mismatched Mt Chimney key: the encounter resolver
returns volcano: while the registry fallback is volcano. The card guard now
uses the actual key; unit fixtures call the real habitat resolver to prevent
that mismatch recurring. Generic rare particles are suppressed for these three
events so they cannot duplicate the textured props. Quiet delays are 12 seconds
for Fiery Path, 14 for Magma and 11 for Mt Chimney; small background motion is
separate from these rare events.

Evidence: output/oasc-volcanic-v2-20261001/Pruefung.html links before/after,
native captures, folds, aspect captures and three 96-frame environment clips.
The GPU probe isolates each of five lava cards in Magma and Mt Chimney and
proves a visible moving contribution; each of all nine rare paper-event cards
is also isolated for visibility. Final GPU, ambient and multi-trainer layout
checks pass. The failed first volcano-art.log is retained as diagnostic history.

All three native fixtures win and return to field/camera and music (Magma 430,
Fiery Path 366, Mt Chimney 406). Both Dig apertures pass three zooms/four aspect
profiles and real window resize. The fixture trainer IDs now resolve to the
Magma grunt and Maxie at Mt Chimney. These are level-3 presentation opponents
(Numel, Torkoal, Poochyena), not canonical full story teams or story progression.
No performance claim is made from image-capture runs. Full habitat quality and
encounter coverage remain open.

### Shoal Cave tide, exposed salt and ice cards — 2026-10-02

EmeraldShoalTerrariums replaces the three remaining cavern atlas layouts:
29 cards at high tide, 28 at low tide and 30 in the ice room. Tide and salt
keep the same principal cave flanks and ridge positions. High tide adds five
separate moving water cards, swaying kelp and textured falling droplets; low
tide exposes salt/shell deposits and a small walking paper hermit crab. Six
individual salt stalactites hang from the lid in both tidal variants. Ice uses
thin tracing-paper fins, a separate frozen waterfall, crystal sheets, snow
drifts, six individual icicles and three separately suspended snowflakes.

Two unmodified built-in-generated 1536x1024 RGBA atlases are stored locally as
tidal-layered-v2.png and ice-layered-v2.png. TIDAL_V2_PROVENANCE.json and
ICE_V2_PROVENANCE.json preserve exact prompts, source files and SHA-256 hashes.
The previous generic cavern file is retained but no longer selected by these
registry entries. Shell, mirror, native sprites and responsive battle anchors
are unchanged.

Rare events are separate paper cards bound to the actual resolver keys:
watercave:tide, watercave:salt and ice:. Three drops/salt flakes/frost flakes
fall at staggered times; generic rare particles are suppressed for these
events. The low-tide crab walks 18 world units along the exposed front rim,
with slight paper rocking. Events share the existing quiet clock, pause during
combat, remain bounded and reset on exit. Unit tests resolve real map IDs and
verify the crab's authored trajectory clears both the shell edge and raised
battle platform across four aspect ratios. Quiet delays remain 9/13/12 seconds
for tide/salt/ice; continuous background motion is separate.

output/oasc-shoal-v2-20261002/Pruefung.html includes before/after, native and fold
captures, aspect comparisons, full prompts, and three 96-frame environment clips.
The GPU check isolates all five water cards for visible motion and each of the
ten rare paper-event cards for visibility, then checks pause and full unfolding.
Ambient and all 110 registered multi-trainer podium-layout checks pass.

All three native level-3 fixtures (Spheal, Zubat, Snorunt) win and restore field,
camera and map music 432. Native tests check both Dig openings at three zooms,
four aspect profiles and real window resizes. Zubat uses Ember for the actual
attack because it is immune to Dig. Snorunt now uses a wild encounter rather
than a synthetic Hiker portrait. These fixtures do not prove all random teams,
RTC/tide-change scripts or progression; no performance claim is made. Full
habitat quality and encounter coverage remain open.


### Rusturf Tunnel: distinct layered cave and rolling rubble (2026-10-02)

The source-map audit identified Rusturf as a real wild/trainer battle location
still sharing the generic cave stage with Altering and Artisan caves. It now
resolves exactly to `cave:rusturf`, backed by `EmeraldRusturfTerrarium` and the
unmodified RGBA `rusturf-layered-v1.png` atlas. The builtin Imagegen prompt,
source path and SHA-256 are in `RUSTURF_V1_PROVENANCE.json`.

Thirty individual cards form six staggered cave fins, six suspended rock teeth,
two hanging roots, low banks, boulders, construction timber, two native trainer
podiums, foreground rubble and four event props. The shared shell/mirror and
responsive raised arena remain. Three textured pebbles roll with a staggered
start after eleven quiet seconds; a paper dust puff follows. All event props
pause on actions and reset with the scene. No gameplay RNG is consumed.

`output/oasc-rusturf-20261002/Pruefung.html` contains native battle captures,
folds, four-aspect comparisons, a 96-frame 24-fps environment clip, the full
prompt and logs. GPU tests isolate each of the four event cards and prove
visible contribution, motion and pause. Unit checks cover event timing,
location guards, reset, and shell/arena clearance across four aspects.
All 111 registered layouts pass the multi-trainer podium check.

Private native fixtures cover Whismur and the original Rusturf Aqua Grunt
portrait (trainer 16) with level-3 Poochyena; both win and restore map music
366. Whismur also exercises both Dig holes at three zooms/four aspects and
actual window resizing. These fixtures verify presentation and battle return,
not the full Peeko/Devon Goods story or the original trainer roster.

Overall scope stays open: Altering and Artisan Cave still share generic cave
art; the map inventory alone does not establish quality or native script
coverage for every context. Contest-only maps remain explicitly unresolved
in the coverage inventory pending complete callback review.


### Artisan and Altering caves: separate layered stages (2026-10-02)

The map-specific cave pass now resolves `EM_ARTISAN_CAVE_1F` and `_B1F`
to `cave:artisan`, and `EM_ALTERING_CAVE` to `cave:altering`. Both previously
used the generic cave art. `EmeraldSecludedCaves` contains 28 Artisan and
27 Altering cards with different depth compositions and separate atlases.
Each has five individually suspended rock teeth and two hanging roots.
The existing round shell, mirror lid and responsive raised platform remain.

Artisan's quiet event starts after 22 seconds: a green brush tip rises behind
a low shelf, followed by three individually textured paint droplets. The
initial rise exposed the whole curled tail; it was reduced to ten world
units after visual inspection. GPU checks prove the tail is completely
concealed at both event endpoints and all four props contribute visible
pixels during the event. Altering's event starts after 18 seconds: two
whole paper bat frames alternate at eight frames/second during a 4.8-second
flight, with exactly one frame drawn at a time. Both poses pass isolated
visibility checks; actions pause the event, and view resets clear it.

Unmodified builtin Imagegen RGBA assets are `artisan-layered-v1.png` and
`altering-layered-v1.png`; their `*_V1_PROVENANCE.json` files retain complete
prompts, source paths and SHA-256. No generated alpha was repainted.

Review: `output/oasc-secluded-caves-20261002/Pruefung.html`, including complete
120/128-frame environment clips at 24 fps, folds, native captures and logs.
Private native fixtures for Artisan 1F/B1F (level-3 Smeargle) and Altering
(level-3 Zubat, Ember because Flying is immune to Dig) all win and restore
map music 366/366/543. Each verifies both Dig apertures at three zoom levels,
four aspect compositions, and actual window changes. These are presentation
fixtures, not a full encounter-roll or Altering Cave event-table run.

Habitat routing, ambient timing/frame exclusivity/pause/location/reset,
and the podium layout test for all 113 registered variants pass. Fresh
ROM-map inventory: 518 maps, 430 exact artwork keys, 74 base-family matches,
14 missing contest contexts. The latter still require conservative native
callback review; counts are not proof of complete fidelity or acceptance.

### Aspect confirmation and catalog visibility screening (2026-10-02)

The existing aspect-driven layout was reconfirmed with camera, battle-slot,
viewport and all-113-variant podium tests. A private Regice fixture verifies
both Dig apertures at three zoom levels and four aspect profiles, then actual
window changes, native victory and return to map music 438. The new 4K window
attempt is explicitly reported as constrained when macOS substitutes another
size (1710x958 on this host); it is not counted as a real 4K render. Resolution
independence at 1280x720 and 3840x2160 remains covered by the layout tests.
Review and native log: `output/oasc-aspect-confirm-20261002/Pruefung.html`.

`gen3_terrarium_catalog_gpu_test` screens map-derived candidates at 960x640.
Its first run covered 112 reachable registry keys (the unused `underwater`
alias is not a new habitat). Continuous motion was visible in all; Regice's
scheduled generic drips were completely occluded. They now use three small
falling paper frost shapes in front of the upper ice walls. A targeted rerun
in `output/oasc-regice-motion-20261002/` confirms visible contribution,
combat pause and reset. The original full-scan report is retained unchanged
in `output/oasc-catalog-screen-20261002/`. Surface candidates do not establish
tile-level encounter coverage, and nonzero pixel changes are not a visual
quality acceptance test for all scenery or rare events.

### Rustboro City / Roxanne layered rebuild (2026-10-02)

The two original nine-card compositions are replaced by independent layouts:
`EmeraldRustboroLayered` (29 cards) and `EmeraldRockGymLayered` (28 cards).
Rustboro has separate Devon/residential/gym facades, ridges, garden walls,
trees, flowers, lamps and six string-suspended sky/pennant pieces. The gym
uses separate sedimentary crags, a fossil display, timber supports, low rock
shelves, rubble and six suspended mineral/badge/lantern pieces. Both now use
the raised R61 arena with authored responsive anchors and a full Dig margin.

Rustboro emits three textured paper smoke wisps after 13 quiet seconds;
the gym rolls three textured pebbles and a dust card after ten. All seven
event cards contribute independently visible GPU pixels. Their motion pauses
over combat and resets on view changes. A clearance test caught a dust-edge
overlap in portrait; its path was moved farther out on the apron, then
verified inside the shell and outside the arena at all four aspect profiles.

New unmodified built-in Imagegen assets: `rustboro-layered-v3.png` and
`rock-gym-layered-v3.png`; complete prompts, source paths and SHA-256 are in
`RUSTBORO_V3_PROVENANCE.json` / `ROCK_GYM_V3_PROVENANCE.json` beside them.
Superseded assets remain available for comparison.

Review: `output/oasc-rustboro-v3-20261002/Pruefung.html`, including 120/96-frame
environment clips, folding frames and native battle captures. A private
Rustboro presentation fixture wins and restores music 399; this does not
claim a wild encounter exists on its synthetic city tile. The Roxanne fixture
uses her canonical Emerald ROM roster (all three sendouts/faints), wins and
restores music 364. Both test Dig at three zooms, four aspect compositions
and actual window changes. This does not test badge/story/rematch progression
or constitute a full catalog quality acceptance.

### Persistent paper movement in four gyms (2026-10-02)

Barely visible generic particles in Fighting, Normal and Flying gyms now
animate their actual paper props: Brawly's suspended target swings briefly,
one lower-left Norman door opens/closes, and three Winona feathers flutter
with independent phases. Norman's door is split into four frame strips,
a recessed backing and its hinged leaf. The leaf's rotation includes the
translation needed to hold its left edge fixed. The Psychic gym's three
orbiting stars are larger and its signal details pulse during the event.

`eventMotion` is distinct from `ambientCard`: a persistent door or target
remains visible when its event is inactive. Existing transient props retain
their old visibility semantics. The optional pose Z offset is used for the
door hinge, while existing poses default to zero. Quiet delays are 8/10/7/8
seconds for Fighting/Normal/Flying/Psychic; actions pause the event clock.

GPU comparisons separately prove idle visibility and event movement for
the target, leaf and all three feathers. Unit tests cover timer, pause,
location, reset, the fixed hinge, and return to quiet state. Preview clips
now use `AmbientMotion.update` rather than forcing active state beyond the
event duration; all four gym clips contain 132 frames at 24 fps.

Review: `output/oasc-gym-motion-20261002/Pruefung.html`. Four private native
fixtures use canonical Emerald leader teams: Brawly 3, Norman 4, Winona 5,
Tate/Liza 4. All sendouts/faints and victories pass, including the double
battle, and each restores map music 364. Native zoom/aspect/window tests
and the 113-variant podium test pass. This is not badge/rematch/story
progression verification, and overall catalog completion remains unproven.

### City machinery: Mossdeep and Slateport (2026-10-02)

- Existing town atlases are unchanged. Mossdeep's dish and Slateport's crane hook now use separate UV cards. The dish rotates about its stand, the hook about its upper attachment, and the two suspended harbor pennants respond to the same quiet breeze with distinct phases.
- Quiet delays/durations: Mossdeep 11/5 seconds; Slateport 9/4.5 seconds. Persistent pieces remain visible at rest; combat pauses their event clock.
- `foldBaseY` preserves the original facade floor hinge for every split piece; the opening cannot separate a roof machine from its facade. GPU checks compare shared UV corner positions during folding and isolate each event's visible contribution.
- Native private city trainer fixtures both win and restore map music 399/433; both-side Dig, three zooms and four aspect profiles pass. These are rendering fixtures, not proof of story encounter coverage. Actual 4K remains limited by macOS window sizing.
- Review: `output/oasc-city-machinery-20261002/Pruefung.html` (workspace parent). The repeated small foreground groups still need a separate composition pass; city visual quality is not considered complete by these motion checks.

### Coastal-town foreground composition (2026-10-02)

Mossdeep, Slateport, Dewford and Lilycove now use separate foreground props instead of ten repeated composite islands. `coastal-details-v1.png` supplies twelve original RGBA cutouts (unchanged built-in Imagegen output, exact prompt and SHA-256 in `COASTAL_DETAILS_V1_PROVENANCE.json`). Each town has 13–14 placed details and its own arrangement; podiums remain the authored town podiums.

Dewford/Lilycove replace barely visible generic particles with a paper crab that emerges and retreats after 14/16 quiet seconds (4.8-second event). Crab and static foreground bounds are checked against the inner rim and battle-platform radius at four aspect profiles. Each prop is independently isolated in the GPU test; four six-second clips cover events. The Lilycove left rock was moved inward after an ultrawide rim failure.

Four private city trainer fixtures win and restore map music 399/433/427/408. Native both-side Dig at three zooms and aspect/window changes pass. These fixtures do not establish story encounter coverage; actual 4K window rendering remains unverified due to the OS size limit. Review at workspace `output/oasc-coastal-foreground-20261002/Pruefung.html`. This supersedes the repeated-foreground limitation in the preceding city-machinery checkpoint for these four towns only.

### Four garden-town foregrounds and events (2026-10-02)

Littleroot, Oldale, Verdanturf and Petalburg now use individually placed trees, fences, ferns, flowers, planters and small village props in place of the repeated foreground islands. Verdanturf retains its characteristic bench/music motif once. `garden-details-v1.png` is unchanged original RGBA from built-in Imagegen; exact prompt, source and SHA-256 are recorded in `GARDEN_DETAILS_V1_PROVENANCE.json`.

- Littleroot: separate contour-cut pinwheel rotor makes two eased rotations after 10 quiet seconds; fixed stick and rotation center.
- Oldale: hinged sign arrow sways after 12 quiet seconds; the post remains fixed.
- Verdanturf: two individually rendered butterflies rise over the flower beds after 13 quiet seconds, with staggered timing.
- Petalburg: three leaf cutouts fall from the left tree after 11 quiet seconds, staggered and clear of battlers.

GPU checks isolate every foreground prop and every event piece; four 144-frame clips use the real event timer. Unit checks cover timing, combat pause, fixed attachment points, location reset, return to idle and rim/platform clearances at four aspect profiles. Four private native trainer fixtures win and restore map music 405/363/398/362; Dig on both sides, three zoom levels, viewport changes and the 113-variant podium check pass. Fixtures do not prove every story encounter. Actual 4K remains constrained by macOS. Review at workspace `output/oasc-garden-towns-20261002/Pruefung.html`.

### Volcanic town foregrounds (2026-10-02)

Lavaridge and Fallarbor now each use 15 individually placed foreground/side
props plus three animated paper cards from `volcanic-town-details-v1.png`.
The original RGBA output is unchanged; builtin Imagegen provenance and exact
prompt are in `VOLCANIC_TOWN_DETAILS_V1_PROVENANCE.json`. Existing town facades,
trainer podiums and ball geometry remain. The full terrarium goal is still open.

Lavaridge's separate bamboo spout lands in the small basin. Both water regions
use the cyan-selective flowing highlight material; three steam cards rise on
the idle clock after ten seconds. Fallarbor has an ash-dusted plant/volcanic
rock border and a three-card ash swirl after twelve seconds. Action pauses and
location/reset binding are covered. Foreground and animated extents clear the
ball rim and battle platform at four aspect ratios.

Evidence: `output/oasc-volcanic-towns-20261002/Pruefung.html` contains before/after,
144-frame 24-fps clips for both, individual prop/effect visibility checks,
opening renders and native battle captures/logs. Native trainer fixtures win,
return to town music (363/437), and pass both-side Dig, three zooms and aspect
checks. These are configured display fixtures, not canonical story encounters;
macOS constrained the requested 4K window, so actual 4K is unverified. The
registered 113-layout podium test passes; it does not prove full story coverage.

### Civic town foregrounds and hanging pennants (2026-10-02)

Mauville, Ever Grande and the Frontier exterior now replace their repeated
foreground decoration groups with distinct individually placed paper props.
The original RGBA `civic-details-v1.png` is copied unchanged from builtin
Imagegen; exact prompt/source/hash are in `CIVIC_DETAILS_V1_PROVENANCE.json`.
Mauville has 14 persistent pieces plus two lamp spark cards (quiet delay 11s),
Ever Grande 14 plus three falling petals (12s). Frontier has 13 foreground
pieces and two genuine rod-and-paper pennants suspended from lid threads;
the earlier cutout floor stands no longer hang in midair. Pennants swing
around their top hinge after 10 quiet seconds and remain visible at rest.

Individual prop/event visibility, pause/reset/location binding, opening folds,
four-aspect rim/platform clearance and 144-frame clips per scene are checked.
Native configured trainer battles win and return to music 399/422/457; both-side
Dig at three zooms and responsive window checks pass. Fixtures are display
checks, not canonical story encounters. macOS limits the requested 4K window;
actual 4K remains unverified. Review: `output/oasc-civic-towns-20261002/Pruefung.html`.
Remaining location quality and full battle-context coverage are still open.

### Museum and battle-tent foregrounds (2026-10-02)

Oceanic Museum and all three battle tents replace the repeated small decoration
islands with individual exhibit/competition props from `pavilion-details-v1.png`.
The original RGBA atlas is unchanged, generated using builtin Imagegen, with
exact prompt/source/hash in `PAVILION_DETAILS_V1_PROVENANCE.json`.
Museum: 15 props including separate fixed crossbar and hinged ship bell (14s
quiet delay). Slateport tent: 13 persistent props plus two falling paper ribbon
cards (13s). Verdanturf tent: 14 props including a paper fan moving at its base
on the judges desk (11s). Fallarbor tent: 13 props plus a trophy glint card from
`civic-details-v1.png` (12s). The original main flats and native trainer podiums
remain. No story/battle-rule state is changed by these ambient events.

`output/oasc-pavilion-details-20261002/Pruefung.html` offers before/after, four
144-frame clips at 24fps and native captures/logs. Individual props/effects are
GPU visibility checked; fixed hinges, location/reset binding, action pause and
four-aspect rim/platform clearance pass. Four configured native trainer fights
win and return to music 375 (museum) / 384 (tents); Dig on both sides, three
zooms and responsive window checks pass. These fixtures do not prove canonical
museum story scripting or full battle-tent rules. Requested actual 4K remains
OS-constrained. The 113 registered podium layouts pass separately.

Further audit: the original whole-catalog screen still records many tiny legacy
ambient contributions (e.g. base cave, league rooms, routes, facilities). It is
not current proof after individual scene fixes. Generic petals still map to a
small green leaf mesh and several dust/leaf events originate behind the large
paper flats; inspect and reauthor affected event placement and appearance,
then rerender. Full location quality and battle-context coverage remain open.

### Visible nature paper events (2026-10-02)

Forest, meadow, long grass, Route 113 ash, Faraway Island and Southern Island
now use separate nature-event paper cards instead of the tiny legacy triangle
particles. `EmeraldNatureEventCards` composes fresh per-art layouts without
mutating shared scene data. The original `nature-events-v1.png` RGBA is copied
unchanged from builtin Imagegen; prompt, source and hash are recorded in
`NATURE_EVENTS_V1_PROVENANCE.json`.

Individual leaves/petals/fronds/ash/butterflies are visible in the GPU isolation
check; 120-frame clips per scene exercise timed motion and disappear at event
end. Pause/reset/exact-habitat binding and four-aspect platform/rim clearance
pass. The 113 registered multi-trainer layouts retain the same event cards.
Six configured native battles pass both-side Dig at three zooms, responsive
windows, victory and map-music return (366/359/361/418/381/381). Fixtures for
Faraway/Southern Island are display tests, not canonical event-script proof.
Actual 4K remains OS-constrained. Review with 720 frames and native captures:
`output/oasc-nature-events-20261002/Pruefung.html`.

The full catalog quality audit and exhaustive battle-context coverage remain
open; these six improvements do not establish whole-game completion.

### Paper-shadow pose and seabed receiver (2026-10-02)

`EmeraldScene.panelPose` now computes one shared transform for a card and its
three projected-shadow samples. The former separate shadow path omitted sway,
floating/drifting props, event motion and elevated fold hinges. Persistent
foreground geometry now carries its actual pose into the shadow pass. Existing
transient cards remain excluded from the projected-shadow pass.

The sea receiver previously used a flat y=-43 plane, below the curved foreground
seabed. It now intersects the light ray with the bowl's cubic radial profile;
a 0.45-unit bias covers the 12-ring mesh interpolation error. The GPU test
checks actual draw uniforms, hidden cards, raised hinges, persistent event
poses, folds and the shadow toggle in forest/sea/treecity. Visible shadow
contributions at 1200x800: 2438/2541/2736 pixels (threshold 2/255). These counts
prove a visible contribution, not subjective quality or full-game performance.

Native forest and sea test battles win and return to music 366/361. Both-side
Dig at three zooms and four aspect ratios pass. The responsive probe now samples
illustrated rock caps in their vertical paper plane, matching the existing
sea-specific probe; its prior horizontal samples were invalid for these caps.
Water/wave movement, dry rock anchors and the paused Kyogre shadow pass as well.
Popup lifecycle/hinge checks pass. Actual 4K remains OS-constrained.
Review: `output/oasc-paper-shadow-pose-20261002/Pruefung.html`.

The refreshed whole-catalog screen is in
`output/oasc-catalog-refresh-20261002/Pruefung.html`: 112 map-derived variants
render with nonzero continuous and/or scheduled motion. 49 scheduled events
still change fewer than 15 sampled pixels at stride 2 and are explicitly queued
for visual review in `review-queue.json`; a green render does not clear them.
The unreachable `underwater` registry alias and tile/script-level battle
coverage remain separate audit items. This refresh is not release approval.

### Frontier paper events and tower proportions (2026-10-02)

Four weak generic effects are replaced by object-specific paper events. Battle
Arena: two lid banners swing at their fixed upper pivots after 13 quiet seconds.
Dome: six staggered paper ribbons fall before the stands after 10 seconds.
Pike: four lanterns receive a sequential gold paper glint after 16 seconds.
Tower: two independent paper door leaves fold around fixed outer hinges after
12 seconds, with a dark paper recess behind them. The tower facade is split
into three surrounding pieces plus recess and doors; source UV scale, shared
base hinge and common fold timing are preserved. Narrow foreground topiaries
and lamps now use their source aspect ratio instead of stretched widths.

All source atlases remain unchanged. Ribbons reuse `pavilion-details-v1.png`,
glints reuse `civic-details-v1.png`, and the tower recess samples the existing
Pike doorway. No new raster image was generated for these changes.

`output/oasc-frontier-events-20261002/Pruefung.html` offers four 132-frame clips
at 24fps (528 frames), before/after and native captures. Every event card passes
individual GPU visibility checks. Timing, action pause, reset, exact location,
fixed door/banner hinges and foreground clearance pass; split-facade fold/UV
checks and all 113 registered multi-trainer podium layouts pass. Four configured
native trainer fights win and return to music 458/467/468/465; both-side Dig at
three zooms and four aspect ratios pass. These are presentation fixtures, not
a proof of each facility's challenge/rental/progression rules. Actual 4K is
still OS-constrained.

The 49 weak-event entries in the earlier catalog refresh are a historical
screening list; these four now have separate review evidence. Other weak
events, detailed composition quality, performance and exhaustive battle-context
coverage remain open.

### Factory, Pyramid, Trainer Hill and Link event review (2026-10-02)

Four more weak ambient events now have visible, location-specific presentation:

- Battle Factory: three staggered paper steam cutouts emerge from the two upper
  grilles in the central facade after 12 idle seconds. Existing unmodified
  `volcanic-town-details-v1.png` provides the paper shapes.
- Battle Pyramid: three individually rotating stones cross the outer front
  sand strip after 11 idle seconds. Their rotated rectangular extents stay above
  the floor, and all four aspect-ratio layouts keep them clear of the ring/rim.
  Existing unmodified `rock-gym-layered-v3.png` provides the stones. Four static
  foreground rocks now trace a whole fallen stone in `frontier-pyramid-kit.png`;
  their mirrored clipping polygons reflect with the UVs, removing sliced pillars.
- Trainer Hill: the two hanging mountain banners swing briefly after 19 idle
  seconds, each about its own upper pivot. This replaces tiny generic confetti.
- Link: five paper signal points cross a higher, visible path between terminals
  after 12 idle seconds. The old path was too low and too small. This uses the
  existing paper-star mesh, with no new raster generation.

`output/oasc-facility-details-20261002/Pruefung.html` contains 528 rendered frames
(4 x 132 at 24fps), before/after views and native battle captures. GPU checks
isolate all six steam/stone cutouts, both banners and all five link points;
link points each affect 202–207 pixels at the tested event pose. Whole-scene
pixel totals alone were replaced with per-point visibility checks, since a
single arbitrary total does not prove that all five points are unoccluded.
All four effects pause during actions; timing, stagger, reset and finish checks
pass. All 113 multi-trainer podium layouts pass.

Configured Factory, Pyramid and Hill trainer battles win and pass both-side Dig
at three zooms, four projected aspects and actual supported window sizes. They
restore map music 469, 0 (silent Pyramid top fixture), and 384 respectively.
The native loopback Link test waits for the real 12-second quiet trigger,
captures the event at age 1.4, verifies unchanged native state/turn/RNG/HP,
then exercises view switching, peer replacement and a win with the field party
preserved. Link returns to music 359. These are presentation fixtures, not a
claim of complete native facility rules or physical-device performance. Actual
4K remains constrained by the host OS. All-map composition, other weak events,
performance and exhaustive encounter-context coverage remain open.

### League mobiles, authored battle spacing and canonical teams (2026-10-02)

All five League scenes now have visible events tied to their paper objects.
The dark medallion swings about its upper attachment (9s quiet delay); the ghost
room has three separately swinging wisp cutouts (18s) plus its existing eye
reveal; the large ice snowflake completes one eased turn (9s); Drake's bell
moves independently of its rope and banners (13s); the Champion's three drop
pendants move separately above the existing flowing paper falls (11s).

`EmeraldLeagueTerrariums` splits the ghost/dragon/champion mobiles into four
source-aligned pieces each. The printed cord stays fixed. Off-centre attachment
points are compensated during rotation, so the visible stem remains attached.
All pieces keep the original UV scale and common folding hinge. Original
`league-*-kit.png` pixels are unchanged; no raster generation/editing was used.
GPU checks account for every opaque source pixel in the split mobiles and
verify their alignment at four folding poses. Nine event objects are tested
individually for visible movement; timing, action pause, reset and the end pose
are verified separately.

League floors previously used the narrow default positions (49.8 world units
apart with almost no depth separation). They now author player/enemy positions
at x=-35/+35, z=27/4. A copied per-scene `battleFootprint` lets a flat floor use
the same aspect-driven actor spread and complete-Dig-hole margin as a raised
platform. The footprint is also respected in doubles. Actual actor separation
is 58.8 portrait, 70 classic, 78.4 wide and 82.6 ultrawide, independent of pixel
resolution. The ring and trainer podiums retain their artwork and positions.

`PAPER_BATTLE_QA_CANONICAL_LEAGUE=1` now exercises the five actual ROM teams,
trainer pictures and native move/item logic, using a private overlevelled Mew
party. The existing native leader probe verifies every sendout, full party,
visible trainer portrait and individual paper faint. All 26 opponents pass,
and all five wins return to field music 429. Both-side Dig at three zooms,
four aspect ratios and supported actual window sizes pass with the new anchors.
The full-team tests receive a 20,000-frame timeout; the old 5,000-frame short
fixture limit expired during Sidney's fifth Pokemon despite ongoing progress.
This does not claim full League doorway/progression/Hall-of-Fame script coverage.

Review: `output/oasc-league-motion-20261002/Pruefung.html`, with 660 rendered
frames (five 132-frame clips at 24fps), the old/new native battle spacing, logs
and native captures. Asymmetric attachment refinements have separate final
GPU logs for ghost, dragon and champion. The normal and double floor footprints
are verified on the real GPU; all 113 registered multi-trainer podium layouts
still pass. Actual physical 4K rendering remains host-OS-constrained, and the
larger all-scene quality, performance and encounter-coverage work remains open.


### Space Center / Weather Institute paper mechanisms (2026-10-02)

- `space-test-model-v1.png` is a new, unedited original RGBA generated with the built-in image tool. The exact prompt, source and SHA-256 are in `emerald-terrarium/SPACE_TEST_MODEL_V1.txt`. The old combined rocket/plinth image is replaced by independent rocket, empty plinth and three exhaust paper cards. The rocket rises 16 world units and returns to its stand; rocket and stand share the initial floor fold.
- Weather's anemometer performs two additional eased turns during its gust, preserving its idle phase at both endpoints. Three independent paper leaves pass across the rear rain window. Eight separately rendered frame strips sit in front of those leaves, preserving original source scale and a common fold hinge. Existing rain/window and console animation remains.
- Exact habitat binding prevents either event appearing in unrelated laboratories. Both events use the existing quiet-menu schedule (18/13 seconds), pause over battle actions, reset with the scene, and replace the former tiny generic effects. No battle mechanics or RNG calls were added.
- `gen3_ambient_motion_test`, `gen3_multi_trainer_layout_test`, and separate space/weather GPU passes succeeded. GPU checks individually remove each of eight moving objects, check persistent mechanism movement, common frame hinges, continuous movement, pause and folding. 264 environment frames at 24 fps plus actual battle captures are in `output/oasc-research-motion-20261002/Pruefung.html`.
- The native driver accepts `PAPER_BATTLE_QA_AMBIENT=1` to wait for a real quiet event and verify unchanged battle state, HP, PP and actor pose before continuing. Space and Weather each won a native presentation fixture, checked full Dig on both sides at three zooms/four aspects, and returned to map music 399/406. These fixtures do not assert canonical story teams or complete story progression. Actual 4K remains constrained by the local window manager to 1710×956.
- The final rocket floor-hinge refinement was GPU-verified after the native runs; it changes unfolding only, not combat or the fully open event poses. Other scenes and full encounter/performance coverage remain open.


### Native surface audit and inland/ash selection (2026-10-02)

- Added `tools/emerald_battle_surfaces.lua` and `tests/gen3_battle_surfaces_test.lua`. The audit reads original map-tree grid words, skips statically blocked cells, uses the runtime's extracted metatile behaviors/tile flags, and calls Emerald's own `env_rse.resolveFromBehavior`. It reports both bridge/Surf contexts and exact habitat/art selection, rather than substituting terrain 0 for every map. Inputs are the private extracted cache and the earlier 518-map script inventory; no saves or game files are written.
- Current results: 518 maps, 152,418 raw-collision-free cells, 3,004 map/behavior/surf-context combinations, no missing behaviors. These are conservative candidates, not proof that all tiles are reachable or that every native/scripted battle path is covered. Fishing, rock-smash context, procedural rooms, dynamic floor changes, native special call chains and contest exclusions remain separate audit work.
- Found and fixed Route 113 ASHGRASS/bare ash resolving natively to SAND (2) and then incorrectly to `coast`. The named ash biome now precedes generic sand selection. Safari land sand likewise keeps `safari`. The native step callback clears ASHGRASS mid 522 to TALL_GRASS mid 530 after four updates; the live test covers this transformed grass plus bare ash. The original failed fixture expected untouched ash at the player's feet; `ash-diagnostic.log` preserves that finding.
- Emerald also uses native OCEAN_WATER behavior 21 inside freshwater areas. Routes 103, 114, 119, 120 and Safari water now resolve to `pond` for native water/pond terrain, preventing coral-reef/Kyogre selection there. Controls retain the ocean on Routes 104/105/118 and desert on Route 111. No battle terrain values, native Nature Power rules or encounter tables were changed.
- Ten regressions use actual extracted map cells and encounter tables. Habitat tests additionally assert that these inland areas cannot select the Kyogre ambient event.
- `PAPER_BATTLE_QA_SURFACES=1` starts six private native presentation fixtures (Route 113 cleared grass and bare ash, Route 103 river, Route 114 lake, Route 119 river, Safari southeast water). Each reads Collision.behavior at a verified cell and passes mapBehavior/mapType, leaving terrain unset so the native battle computes it. All six art selections, quiet events, wins and map-music returns passed; each also tested Dig on both sides, three zooms, four aspects. Safari fixture does not prove Safari-specific encounter/catching rules.
- Evidence: `output/oasc-surface-coverage-20261002/Pruefung.html`, `surfaces.tsv`, `before-surfaces.tsv`, `changes.json`, `verification.json`, and logs. Physical 4K remains window-manager-limited. No new artwork generated for this correction. Full visual and encounter completion is still unproven.


### Emerald fishing context, Shoal tides and shipped artwork (2026-10-02)

- `battle-encounter-context.patch` carries optional, copied presentation metadata
  from the actual fishing roll through BattleBridge to battle state. It samples
  the hooked water while leaving native `terrain` and battle rules untouched.
  Habitat resolution accepts it only for a wild fishing encounter on the current
  map and water terrain 4/5. River/ocean classification remains location-aware.
- Shoal's entrance and inner room retain their LOW_TIDE map IDs during high tide.
  The renderer now reads `FLAG_SYS_SHOAL_TIDE` for those two rooms. Other Shoal
  floors (including the ice room) retain their own artwork.
- Native `setmaplayoutindex` previously searched only `alt_<id>.mid`; this local
  cache contains the same original layouts under map names. The separate
  `named-map-layout.patch` preserves imported header layout IDs and locates those
  files as a fallback, with existing dimension checks and matching tileset pair.
  It never writes imported caches or borrows another live map's overrides.
- Five actual fishing-roll/bridge battles passed (Route 103, Route 104 pond and
  ocean separately, Petalburg pond, Shoal high tide), with five victories and
  native map-music returns. Native terrain remained plain 9 / cave 7 while the
  hooked-water context resolved 4/5. Twenty aspect-ratio Dig checks covered both
  sides at three zoom levels. High/low/high native layout operations matched all
  1,225 imported cells per layout; invalid layout requests preserved the grid;
  map identity and native RNG were unchanged.
- `build_release.py` now includes authored PNG/JPG images and provenance in the
  dedicated paper-asset directory, and checks direct texture references. The
  old suffix filter omitted the new PNG art. A staged ZIP contains 194 images;
  `gen3_terrarium_package_test.lua` resolves 113 registry entries / 39 layout
  modules and decodes all 178 referenced images from the extracted package.
- Evidence: `output/oasc-fishing-context-20261002/Pruefung.html`, `native.log`,
  `habitats.log`, `package-decode.log`, `verification.json`. This validates
  presentation/dispatch after a bite, not rod-input timing, full clock
  progression, every encounter, full install compatibility or final art quality.
  Upstream tide script reference:
  https://github.com/pret/pokeemerald/blob/master/data/maps/ShoalCave_LowTideEntranceRoom/scripts.inc


### Devon, laboratory and Hall of Fame paper mechanisms (2026-10-02)

- Devon's larger hanging fan has a static housing and an independently cut,
  textured rotor. The rotor completes three gently accelerated revolutions per
  quiet event and returns to its initial printed position. Its paired hanging
  threads remain; `rigidHanging` keeps housing and axle together.
- The laboratory globe has a separate rotating paper disc on its stationary
  stand; its display shelf is slightly larger. Hall of Fame registration uses
  six independently timed paper stars fitted inside the six authored windows.
  All parts reuse existing original atlases; no bitmap derivatives were added.
- `assemblyX` lets attached components follow the same aspect-dependent shift
  as their parent prop while retaining local offsets. Rotor/globe and all six
  registration markers are checked across portrait, classic, wide, ultrawide.
- Timers, fixed positions, seamless rotor endpoints, sequence order, action
  pauses, reset and scene-key isolation pass in `gen3_ambient_motion_test.lua`.
  GPU ablation verifies both mechanisms and every individual record star remain
  visible. Three 132-frame environment clips (24 fps) include their full cycles;
  event contributions increased from the previous small particles.
- Three native presentation fixtures won, waited for real quiet events, checked
  unchanged HP/PP/UI/battle pose during the wait and restored map music
  (399 / 383 / 447). Twelve responsive Dig checks
  cover both sides at three zooms. These are display fixtures, not proof that
  the lab/Hall of Fame normally host battles or that their story scripts pass.
- Review: `output/oasc-research-details-20261002/Pruefung.html`; source logs,
  before/after captures, 396 frames and `verification.json` are beside it.
  The earlier fishing-review ZIP predates these source edits; rebuild the final
  distribution after the remaining visual and encounter coverage work.


## Rock Smash native dispatch – 2026-10-02

The live RockSmashWildEncounter special incorrectly set wildScripted on both
the foe and adapter options. BattleBridge therefore skipped its standard-wild
Safari detection. A real Safari North dispatch reproduced safari=false and
wildScripted=true before the fix. The new rock-smash-wild-battle.patch removes
those two markers, matching the ordinary wild entry point in both pret Emerald
and FireRed. Encounter tables, rates, repel and ability checks are unchanged.

Native QA selects a walkable tile beside an actual graphics-86 rock from the
imported ROM events, rolls until the existing special dispatches, and uses the
live adapter/fade/battle/end callback. No foe, outcome or roll is substituted.
Four normal wins cover Granite B2F, Routes 111/114 and Victory Road B1F; Safari
North and Northeast cover two escapes with no player-mon layer or flame light.
An extra Safari North run invokes the numeric special dispatch and catches the
rolled Geodude, consumes exactly one Safari Ball and resumes its callback with
catch outcome 7. All seven runs restore map music; Safari leaves party HP/PP
unchanged. Four normal cases pass 16 aspect/Dig probes, both sides and three
zooms per probe, plus quiet-event battle-state preservation.

Evidence: ../output/oasc-rock-smash-20261002/Pruefung.html, verification.json and
per-run native.log files. Forward patch application reproduces the current
engine file byte-for-byte; reverse application also checks cleanly.
Limitations: no earned HM/dialogue/rock-destruction route, not every rock object
or RNG outcome; requested native 4K window constrained to 1710x956. The existing
local review ZIP predates this patch and research mechanisms and must be rebuilt.

The latest full catalog screen covers 112 reachable variants with no render
failures. Its 35 low event-pixel cases are retained in
../output/oasc-catalog-finalpass-20261002/remaining-event-review.json for visual
triage; neither that threshold nor passing renders is aesthetic acceptance.


## Psychic / Water gym paper motion – 2026-10-02

The full-catalog review identified the former tiny orbit/glint events as weak.
Mossdeep now moves five individually suspended stars/moon and the persistent
medallion in a phased pendulum sequence (12 s quiet delay, 4.8 s event, 29 s
repeat interval). Sootopolis moves five icicles and four separate falling paper
drops at the rear basin (13 s delay, 4.6 s event, 31 s repeat). Drops reuse a
polygon from the original badge atlas; no bitmap was modified or regenerated.
All cards remain behind the battle plane. The pendants helper now returns its
definitions so drops use the corresponding icicle's authored position.

Movement envelopes return persistent cards without a snap; transient cards
remain absent outside their event. A late fold on the last drop was caught by
the existing 1.70-second intro assertion and its start timing corrected. The
old tiny particles are suppressed for these two layouts.

Evidence: ../output/oasc-gym-motion-20261002/Pruefung.html and verification.json.
15 individual cards pass GPU visibility ablation; persistent cards also pass
moving-vs-rest comparisons. Same-view changed pixels: Psychic 198 to 39350;
Water 56 to 39483 at 1920x1280. This measures visibility, not quality. 264 frames
provide two full previews. Timing/pause/reset/location isolation, basin bounds,
seven-gym layer structure, fold completion and native battle QA pass. Original
ROM teams: Tate/Liza four opponents, Juan five; all sends/faints observed, both
wins and map music 364 restored. Eight responsive Dig probes cover both sides
at three zooms each. Native quiet events preserve HP/PP, turn/UI/animation state.

Limits: private overlevelled QA party, no badge-award/story progression; native
4K request constrained to 1710x956. Existing review ZIP needs a final rebuild.

## Underwater individual paper motion – 2026-10-02

Reef, Sealed Chamber and underwater Sootopolis now use 5 / 3 / 27 individually
outlined fish cards from their unchanged original atlases. Each has a single
central lid thread, its own gentle float phase and a staggered swim/turn/return
sequence. A printed reverse face preserves the fish motif on its return trip;
this is opt-in and leaves other cutouts' plain backs unchanged. Hanging mesh
allocation now follows the number of attachment points (two remains default).
The original shared school card is removed. Fold timing uses an authored-card
ordinal so the 27-fish school does not delay subsequent scenery unfolding.

Seafloor Cavern and submerged Abandoned Ship each add six rising round paper
bubbles sampled from the unchanged cavern atlas. They rise behind the battle
platform, stagger by 0.42 s, and shrink away at the end. The former tiny generic
floor bubbles are suppressed in these five scenes. Marine Cave's Kyogre shadow
is retained. Fish quiet delays remain 16/21/16 s; cavern/wreck remain 18/17 s.
All events pause over combat and reset with the scene.

Evidence: ../output/oasc-undersea-motion-20261002/Pruefung.html and
verification.json. All 47 cards pass individual GPU visibility ablation;
each fish also passes motion-vs-rest and independent hanging checks. Five
complete 144-frame environment previews (24 fps), fold completion by 1.70 s,
ambient unit tests, seven gym layer tests and shared shadow-pose GPU regression
pass. Five native presentation-fixture battles win and return to map music 411;
quiet events preserve HP/PP/turn/UI/animation state. Twenty aspect Dig probes
cover both sides at three zooms. All five native HUD screenshots were inspected.

Limits: fixtures do not prove native Dive encounter dispatch or full story
continuations. Native 4K requests remain constrained to 1710x956. Pixel counts
measure visibility rather than aesthetic quality. The raised circular platforms
still need a separate visual composition review; this pass improves their
surrounding paper movement. Final package rebuild/device performance remain open.

## Underwater platform paper cliffs – 2026-10-02

The five undersea layouts and submerged wreck now have stepped paper strata
beneath their unchanged radius-61, height-7.5 combat tops. Seven separate cliff
cutouts per scene frame the front edge. These sample the existing low-rock
pieces from each habitat's original atlas; wreck uses the cavern rocks. No
bitmap was regenerated or edited. Heights/widths and mirrored arrangement give
the foreground a layered shoreline while keeping its base below the water.
The opaque core closes gaps between cutout silhouettes.

`PaperPlatform` builds the supporting strata and cliff definitions. Static
`fixedYaw` in the shared panel pose aligns each paper face to the platform edge;
rotation about its own horizontal base follows that yaw, so unfolding cannot
slide either hinge endpoint. Decorative cliff coordinates remain fixed to the
platform under responsive scenery spacing. The upper support lip sits 0.06
below the top to avoid depth flicker from coplanar surfaces. Discarded prototypes
used repetitive vertical-column caps/UV tiling; these are not in the final code.

Evidence: ../output/oasc-undersea-platform-20261002/Pruefung.html and
verification.json. All 42 cliff cutouts pass separate visibility ablation and
fixed-local-hinge tests; all six scenes finish folding by 1.70 s. Geometry bounds,
non-overlapping top lips, shared shadows (including fixed yaw) and ambient
regressions pass. Six single fixtures and a four-slot reef fixture win and return
to map music 411. Twenty-eight aspect probes cover three zooms; double probes
check all four Dig apertures. The double battle additionally observes four
send-outs, two controllable battlers, two actual Dig moves and both enemy faints.
Native HUD frames for all six scenes and the double fixture were inspected.

QA corrections: underwater Marine Cave no longer incorrectly enters the dry
Marine Cave fluid-card assertion. The native single-platform helper is only
called for singles; the existing dedicated double probe plus expanded responsive
helper validate all four slots. Native fixtures remain presentation tests, not
Dive encounter/story coverage. Native 4K remains display-constrained; final
package and device performance checks are still pending.

### Secret-base hanging paper motion (2026-10-02)

Cave, tree and shrub secret bases now use actual articulated hanging decoration
instead of barely visible generic particle events. Two cave pennants, six tree
curtain strips and fourteen garden leaf/flower strips reuse the original atlas
pixels. Their fixed crossbars hang from the mirrored lid on threads. Original
art rectangles are partitioned exactly once; a shared opening hinge and assembly
anchor preserve the composition while unfolding and changing aspect ratio.

The first spin prototype opened narrow slits below the fixed upper paper.
The final motion pitches each strip about its entire upper edge, with different
phases and a smooth 5.4-second envelope. The event begins after 19/21/16 seconds
of quiet menu time respectively, pauses on battle actions and returns without a
snap. `preservePaperPiece` prevents the alpha-component splitter from destroying
these authored joints. The shared panel pose applies optional ambient `pitch`,
so paper and projected shadows use the same transform.

Evidence: ../output/oasc-secret-base-motion-20261002/Pruefung.html and
verification.json. All 22 pieces pass separate GPU motion/visibility checks and
fixed-upper-edge checks. Three complete 144-frame clips include the return to
rest. Unit checks cover delay, action pause, reset, exact non-overlapping UV
coverage, shared folding timing and four aspect ratios. Shadow pose and raised
platform regressions pass. Three private native presentation encounters win,
restore map music 382, and preserve battle HP/PP/state during the actual quiet
event. Twelve aspect probes cover both Dig positions at three zoom levels.
Native HUD scenes and mid-event/folding frames were inspected.

This is not proof of secret-base record mixing, imported teams, full story
coverage or all-device performance. Native 4K remains display-constrained.
Other scenery refinements and the final rebuilt release remain open.

### Coast, pond and Pacifidlog quiet events (2026-10-02)

Coast has a paper crab that walks out, pauses and retreats, plus two separately
suspended birds. Pond has two printed butterfly cutouts following staggered
inward arcs. Pacifidlog's land and water variants now share two suspended
clouds and two separately moving birds. Six staggered thin paper ripple rings
spread around the foreground water in pond and both Pacifidlog variants,
remaining outside the raised combat platform. All animals reuse existing atlas
pixels; no raster assets were changed. Butterfly wings are not separate pieces.

Evidence: ../output/oasc-shore-motion-20261002/Pruefung.html and verification.json.
Four 144-frame GPU clips, nine individual paper-animal visibility checks and
eighteen individual water-ring checks pass. The native four encounter fixtures
win and restore map music (401/359/408/408). Sixteen aspect probes check both Dig
positions at three zoom levels; pond also checks upright caps at two water
poses. Actual quiet events preserve battle state, HP and PP. Unit tests cover
water/platform bounds, pause/reset, habitat isolation and return to rest; shared
shadow and raised-platform regressions pass. Final native HUD frames inspected.

These are private presentation fixtures, not complete Surf, fishing or story
coverage. Native 4K remains display-constrained; device performance and the final
rebuilt package remain pending.

### Navel Rock paper events and fading-water depth fix (2026-10-02)

The summit now has two independently moving suspended cloud cards and two
golden feather silhouettes traced from its existing atlas. The feathers drift
low over the foreground rocks; a higher prototype appeared too close to
Charmander's feet and was lowered after native HUD inspection. The bottom
chamber has four staggered paper drops at the foreground ledges, followed by
four water-surface ripples only after landing. The high rear ceiling was not
used as a source because the intervening rock panels hide the falling water.
The event durations are 5.6 seconds after 17/18 seconds of quiet menu time.

The new overlapping-ring check reproduced a renderer bug: a fully transparent
ring still wrote depth and could hide another ring. Water rings now depth-test
against the scene without writing depth, like the existing underwater shadow.
The failing reproduction log and passing zero-alpha insertion checks are saved;
pond and both Pacifidlog variants also pass the added regression. This is a
shared water-ring correction, not a change to battle depth or actor placement.

Evidence: ../output/oasc-navel-motion-20261002/Pruefung.html and verification.json.
Two 144-frame GPU clips cover the event and return to rest. Eight individual
paper elements and four landing rings pass separate visibility checks; clouds
retain their hanging threads. Bounds, timing, pause/reset, habitat isolation,
shadow and raised-platform regressions pass. Two private native encounters
against Ho-Oh and Lugia win and return to map music 543. Eight aspect probes
cover both Dig apertures at three zooms. Final native HUD scenes inspected,
including the lowered feather paths.

These presentation fixtures use test encounter levels and do not prove the
full Navel Rock event scripts or capture flow. This pass improves ambient
motion; it does not certify every background's final aesthetic quality. Native
4K remains display-constrained. Other scenery, device performance and the final
rebuilt release remain open.

### Articulated ship cloth, harbor hook and gulls (2026-10-02)

M.S. Tide now has ten individually articulated lower curtain strips; the wreck
has eight torn sail strips. They partition the original artwork exactly,
including the wreck atlas's existing notched gutter. The fixed upper bars
remain on lid threads. Every lower strip pitches around its complete upper
edge; shared opening times, assembly anchors and fold bases preserve the
construction while unfolding and changing aspect ratio. Logical card ordinals
keep later scenery from being delayed by the extra paper pieces.

The harbor crane is partitioned into its upper beam, suspended hook/ropes and
right frame. Only the hook swings, around the rope attachment under the pulley.
Three separately suspended gulls glide with different phases. The first GPU
inspection exposed a loose duplicate beak from overlapping alpha-component
bounding boxes. Explicit source polygons replace those rectangles. The GPU
source check finds all 26,253 significant painted gull pixels exactly once,
with no missing or duplicated pixels; each gull has its own centre thread.
No bitmap was regenerated or edited.

Evidence: ../output/oasc-ship-motion-20261002/Pruefung.html and verification.json.
All 22 moving pieces pass individual visibility, movement and attachment
checks. Three 144-frame clips cover motion and return to rest. Source coverage,
fold timing, quiet delay, pause/reset and habitat binding tests pass, alongside
shared shadow and platform regressions. Three private native presentation
encounters win and restore the corresponding map music; twelve aspect probes
cover both Dig positions at three zooms. Native HUD scenes were inspected.
The older service test expecting generic harbor bubbles was replaced by the
authored hook/gull checks.

This does not prove full M.S. Tide travel, wreck exploration or harbor story
scripts. The pass improves articulated details; broader aesthetic review,
device performance and the rebuilt release remain open. In particular, the
small native ship frames reveal fine plank-pattern aliasing and the harbor's
plain cylindrical platform support; these need a separate visual review.
Native 4K remains display-constrained.

### Final local review pass (2026-10-03)

The three ship decks use separate thin fascia planks and folded posts. Harbor
posts and braces reach the basin floor; combat anchors retain their prior
coordinates. Timber floor imagery alone uses mipmaps and anisotropic filtering.
Evidence: ../output/oasc-ship-platform-20261002 (three GPU clips and three native
wins with music restoration, Dig/aspect checks and visible frame components).

EmeraldFinishingEvents composes copies of sixteen existing layouts. Puzzle
gears and the New Mauville rotor complete full turns; Pyre banners bend along
their upper edge; mountain clouds and fossil/Pyre mist travel separately.
Crater birds move on individual threads. Cave and ruin pebbles roll along the
clear foreground strip; Sealed Chamber droplets fall below the outer ledges.
Terra Cave embers originate from visible foreground lava, and Pike light
cutouts sit in front of their housings. Birth Island uses three separate paper
stars: the trial moving stone exposed artwork duplicated in the island flat
and was replaced before packaging. No raster artwork was changed.

The consolidated Emerald engine patch targets upstream 503a712 and replaces
the separate battle-patch sequence for fresh Emerald installations. The
package checklist, GPU/native evidence and exact source hashes are in
../output/oasc-final-review-20261003. These checks are bounded presentation and
installation tests, not a complete game playthrough or all-device certification.
