# Geometry FXAA — oasc.gen3.geometry-fxaa

Own F3 toggle `gen3Card_geometryFxaa`, default on. Own config
`cards.geometryFxaa={enabled=true,subpix=.75,edgeThreshold=.125,textureEdges=true}`.
Medium/high presets enable the pass; low/off/ultra disable it. Render scale
>= 1.5 always bypasses it.

A separate color attachment carries scene luminance and eligibility.
The scene alpha remains native transparency; using it as eligibility would
make alpha-blended sprites disappear. A protected linear footprint rejects
sprite, actor, fence, sign and ground pixels and their filter taps. Native
floor motifs and their grout/corner pixels remain exact; elevated geometry
continues to receive edge smoothing. The console FXAA
path preserves HDR values and original alpha. It owns one filter shader and
two resizeable scene-format canvases, with no per-frame uniform tables.

The `shaderSource` seam renames only the scene entry and appends a multiple
output wrapper. Generic derivative preparation recognizes the stable scene
parameter signature, so both world and rim derivatives remain before discard.
No consumers means the same raw shader bytes and derivative expansion.

The `afterGeometry` canvas chain runs after static world/instances/doors and
before native effects, actors, battle cards or particle draws. Filtering here
keeps those later sprites sharp and leaves weather/fog/Finish composition in
its established order. It also avoids filtering a second time at Finish.

Unsupported multiple render targets bypass this Card. Allocation failures
release its resources and report unhealthy without taking down the renderer.
Disabling removes the owner, config/presets, geometry-cache exclusions and all
resources. Remove one index entry plus `impact.files` for physical rollback.
Native verification includes 14 frozen medium/high scene pairs, a pixel-identical
Ultra bypass, four complete battles with the filter active, real F3 input and
walking. GPU render probes preserve protected sprite bytes, alpha and HDR.
Physical removal and disable produce identical raw pixels in fresh processes;
without shader consumers, buildShaderSource remains byte-identical to RC4.

The motion fixture records 120 paired frames at a 60 Hz camera-path cadence.
Time, weather and NPC poses are fixed; zero subpixel strength is first proven
pixel-identical to disabled. This is a reproducible camera sweep, not a real-time
performance recording. The filter reduces edge stepping; it is spatial FXAA,
not temporal antialiasing and cannot guarantee elimination of every shimmer.

GPU timing remains unverified. CPU submission timing is not a substitute for
the 0.25 ms GPU target; initial scene/driver stalls remain separate open work.

Low-contrast edge detection uses the specified dot-product luminance directly
in both the MRT mask and filter fallback. The earlier sqrt(l/(1+l)) compression
suppressed contrast before the .125 threshold; the .35/.50 diagonal regression
now changes 130 geometry pixels while preserving protected sprites and alpha.
Default subpixel strength (.75) and edge threshold (.125) are unchanged.

A 120-position frozen Pallet roof sweep was compared to a 4x spatial reference,
box-downsampled in two 2x passes. Old/new runs have byte-identical unfiltered
inputs and reference images for all 120 positions. In that roof region, mean
temporal residual falls from 3.069 to 2.775 RGB code values (9.6% vs the old
filter; 12.7% vs off). This is one controlled geometry-only camera path, not
proof of universally shimmer-free walking, a real-time recording or a device
performance approval. See output/oasc-fxaa-temporal-20261008 for captures,
ROI rules, raw measurements and matched reference evidence.

The filter shader is prepared on Card activation when the selected preset, render scale and multiple-target capability permit it. Size-dependent mask/output canvases stay lazy. Low/off/Ultra bypass avoids startup allocation. Release and re-enable recreate the shader through the same guarded path; compilation failure remains local to this Card.


The native walking fixture `tests/gen3_geometry_fxaa_native_walk_test.lua`
now holds real right/left input for 120 engine updates, leaving native player
movement and camera focus intact. It captures paired geometry at 768x528 and
normal 50-degree elevation, with a 4x spatial reference. Clocks/randomness are
frozen only inside each pair; the engine advances between pairs. Other Cards
are disabled to isolate geometry. This is a 60 Hz playback sequence, not a
real-time capture or GPU timing result. Zero strength is byte-identical to a
fully deactivated filter on frame zero; repeated captures at 0/59/119 match.

RC77 evidence in `output/oasc-fxaa-native-walk-20261009/guarded`: 115 moving
updates, 64-world-pixel span, native camera matches the moving player. The
reference-derived left-roof region has spatial MAE 7.513 -> 6.922 (-7.9%),
but temporal residual only 3.473 -> 3.457 (-0.5%). In its left 26-pixel folded
lip region, residual is 7.410 -> 7.413 (effectively unchanged). The earlier
synthetic sweep's 12.7% improvement does not generalize to this native path.
**C13's shimmer-free-walking gate remains unmet.** Preserve this counterexample
when evaluating fixes; do not trade away sprite sharpness or normal resolution.

Run the fixture through a private native QA driver using `(V,game,Map,out)`;
`QA_REPO` supplies the shared frozen-capture harness and optional
`QA_EXPECTED_VERSION` pins the package. Analyze the saved sequence with
`python tools/analyze_geometry_fxaa_native_walk.py <capture-directory>`
(Pillow/numpy). The analyzer retains per-frame ROI/error data and a two-second
side-by-side animation. Its metrics describe this region only, and its PASS
capture marker is deliberately not an acceptance claim for C13.

A separate native MRT readback at the first three walking positions confirms
that the sampled roof and folded lip are eligible geometry (100% of the first
frame's two ROIs), not mistakenly protected sprite pixels. FXAA changes 46.9%
of roof pixels and 47.9% of lip pixels in that frame. The temporal limitation
therefore persists despite the filter being active; weakening the sprite mask
is not supported by this evidence. Probe setup failures (MRT descriptor, active
readback and HDR encoding) remain retained alongside the successful capture.


RC78 adds footprint coverage at roof texel borders before lighting. It keeps
nearest-sampled texel interiors and uses four nearest atlas reads only on
opaque roof material (shade 6). Taps clamp to the current 16-pixel metatile;
any alpha-cutout neighbor bypasses coverage. Atlases retain their filters.
Native sprites, other materials, low/Ultra bypass, zero strength, allocation
failure, disable and removal retain their previous sampling. The optional
`textureEdges=false` retains the original post-filter alone. This setting is
presentation-only and excluded from geometry-cache fingerprints.

The owned pre/albedo/bindTexture/vertex seams are removed with the Card.
Derivatives run before all fragment discards. The roof uniform resets on bind
and is enabled only during a successful geometry MRT pass, never for later
actors or effects. The legacy building vertex snap remains unchanged: removing
it improved this counterexample too little to justify the visual change.

Native 120-update evidence: paired off/reference images remain byte-identical
to RC77. With roof coverage, spatial MAE is 6.573 and temporal residual 2.975
(14.3% less temporal residual than off, versus 0.5% for RC77); the left folded
lip residual is 6.198 (16.4% less than off). This is a measurable improvement,
not a claim that C13's full shimmer-free or target-device GPU gates are done.
Source/captures: `output/oasc-fxaa-console-response-20261009`.

The GPU coverage fixture compares a translated striped roof to its 4x spatial
reference and verifies protected non-roof bytes, alpha and metatile isolation.
The native medium/high suite covers 14 scene pairs and exact re-enable; Ultra
remains byte-identical to disabled. The standalone GPU probe additionally
measures the real coverage function over an entire target against nearest
sampling. This synthetic worst-coverage probe is not the native world shader.
Mac GPU timing has large tails and one invalid zero counter sample in the
combined mask/filter case; no Steam Deck or 0.25-ms approval is inferred.
