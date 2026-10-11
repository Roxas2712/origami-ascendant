# Scene visibility (rc.9 checkpoint)

Native map builds record conservative world bounds in `stats.frustumBounds`.
The scan includes static vertices, instance templates and placements, negative
facade heights, billboard extent, cutaway anchors and maximum wind displacement.
It participates in the existing cooperative BuildBudget. No GPU readback is used.

Renderer selects two reusable lists from the complete scene: one for visible
world meshes/instances and one for their reflected Y coordinates. Shadows,
lighting catalogues, contact shadows, terrain queries, weather receivers and
connection state continue to receive the complete scene. Selection never unloads
a map or alters gameplay. It does not yet reduce native build time or cull
individual objects/chunks within an intersecting map.

The clip test uses homogeneous X/Y planes and a two-pixel raster guard. It
deliberately excludes depth planes because hanging facades, recessed rooms and
water reflection shaders adjust clip Z. Unknown/legacy bounds remain visible.
Dynamic restored cache templates also remain visible until their changed geometry
has an explicit bounds contract. Border geometry currently uses that fallback.
Vertex-seam Cards disable this optimization while registered, rather than trusting
bounds their deformation may exceed. `SceneVisibility.enabled=false` is the
developer rollback switch; release drops both reusable selection lists.

## Deterministic surface normals

The expanded GPU test exposed unstable reflected cliff-edge pixels even with
culling disabled, all render clocks fixed, no simulation updates and a fixed RNG.
Freezing the engine timer as well did not remove the issue. Ground-shadow pixels
were identical while the reflection target changed. The main shader computed
`dFdx/dFdy(worldPosition)` after mirror/alpha discard, where helper lanes may be
undefined. `SurfaceDerivatives.prepare` moves that calculation before discard in
both main and instance programs, retaining its use at the original shading point.
It is idempotent and only transforms compilation input. RenderSeams' exported
empty main/finish builders remain byte-identical to rc.4.

## Evidence

`gen3_scene_visibility_test.lua` checks 72,576 sampled points across perspective,
orthographic, corrected and mirrored projections, plus wind, pixel guards,
missing bounds and list reuse. `gen3_scene_visibility_play_test.lua` compares
96 frozen on/off captures: eight locations, two projections, three zooms and two
dayparts. It also requires repeat captures with culling disabled to be identical.
Tolerance is zero. No weather or lighting effects are disabled for these tests.

In that set 20 main-pass entries and 18 mirror-pass entries are omitted in total;
2,394,108 expanded main-pass vertices are skipped across the 96 cases. These are
work counts, not a frame-rate claim. Four native battles, F3, Card 0 removal and
failure recovery remain separate release gates. Cold loads/first effects and
weak-GPU/Steam-Deck timing remain open performance work.
