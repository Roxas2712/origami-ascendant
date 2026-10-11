# Frame reuse (rc.8 checkpoint)

This change reduces repeated CPU work without changing shader source or the
lighting design. It follows the native map build checkpoint in rc.7.

## Ownership

- Renderer routes its owned scalar/vector/matrix uniforms through UniformState.
  That cache copies vector contents; in-place camera/weather changes remain
  visible. Scratch vectors replace per-pass payload literals.
- Shared battleSpritePass, battleDepthTest, billboardRight and roomDepthScale
  writes remain unconditional: battle/effect layers also write these uniforms.
  Future Cards that replace an existing uniform must use UniformState or
  invalidate its cached shader state when handing ownership back.
- LocalLights optionally accepts a caller-owned reusable state. Omission retains
  independent snapshots. Candidate rows and 24 light payloads are reused;
  disappeared light references and inactive slots are cleared. Group bounds are
  recomputed after preparation, including changes to the same light objects.
- Each actor has a reusable stream mesh per render slot and geometry variant.
  Shadow silhouettes retain full sprites; clipped interior colour geometry stays
  separate. Within one Renderer tick, repeated passes reuse uploaded vertices.
  Each new frame refreshes pose/position/texture; release frees every pooled mesh.
- HeatHaze compares all 16 view-matrix components before reusing its inverse.

## Animated atlases

Public engine 0.3.61 already owns double-buffered partial atlas uploads. OASC
leaves the native animation/deferred-flush functions and texture ownership intact.
A removable flush wrapper advances a revision. AtlasComposite caches the composed
underlay/overlay/flower image until revision, image identity, world generation,
size or relevant display state changes. Hosts without a revision contract retain
the safe per-frame fallback; their existing upload path is unchanged.

Reinstallation advances an ownership generation so native changes made while the
wrapper was disabled cannot be hidden by a returning buffer handle. Release only
removes a wrapper it still owns. A later wrapper can continue delegating to the
retired closure safely, without incrementing revisions twice after reinstallation.

## Validation

- Native GPU test: 12 partial under/over flips, exactly two native buffers per
  layer, deferred and immediate animation frames, unchanged-frame cache hits,
  invalidation, disable/reinstall, and chained wrapper ownership.
- Six maps × three dayparts × four facings: uniform caching on/off gives exact
  pixels. Includes outdoor, forest, indoor, lit/dark cave and Rocket room cases.
- Heat refraction: exact fresh/cached results after in-place camera mutation;
  raised-object mask and animated ground refraction remain functional.
- Frozen captures versus rc.7 and Card 0 rollback: tolerance zero. Raw main and
  finish shader builders remain byte-identical to frozen rc.4 sources.
- Release gate also runs native field/battle/F3 and resize-during-build checks.

Measured send counts describe only CPU uniform submission work. These checks do
not prove stable 60 FPS, GPU budgets or Steam Deck performance. Cold map uploads,
first effect initialization and remaining culling/cache work are still open.
