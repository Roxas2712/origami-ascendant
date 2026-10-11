# Paper surface (Card 3)

`oasc.gen3.paper-surface` owns the `PAPIEROBERFLAECHE` option and
`cards.paperSurface={enabled=true,scale=.02,strength=.6,crease=.8}`.
Low/off suppress the effect. Registration is one line in `cards/index.lua`.
The Card uses only mod/public LÖVE APIs and writes no game state or saves.

Fine fiber normals are sampled in world space with a 512² linear RGB normal
map, ten mip levels, repeat wrapping and trilinear filtering. The source is
a CC0 construction-paper scan; `data/paper/FIBER_PROVENANCE.json` records the
scan author, source, generation prompt and derivation. The normal map is an
artistic derivative, not measured physical normals. Dawn/golden/dusk phase
weights modulate direct sunlight; noon and night have exactly zero effect.
Actors, sprite/plant billboards, grass, signs/fences, water and emissive void/
lava/beam surfaces are excluded. Light/shadow direction remains the existing
scene's, with no added lamps or changes to its exposure.

Creases come from matching world-space triangle edges with non-coplanar
faces, not from second derivatives of the renderer's flat normal. Physical
facades (including window-bearing materials) participate in adjacency.
Horizontal building eaves are matched as collinear intervals, so different
native pixel-run lengths on roof and wall still meet. An edge is marked only
if its entire span is covered by a two-face fold, or by a continuous roof and
its one-pixel apron meeting one facade. The coplanar roof/apron pair must lie
on opposite sides of the eave. Coplanar diagonals, exposed perimeters,
same-side duplicates and ambiguous multi-face joints remain excluded.
Sparse 0/1 barycentric coordinates are stored in a separate four-byte vertex
attribute and provide an antialiased one-pixel line toward/away from the sun.
Folds do not alter original vertices, material IDs or packaged geometry data.

On threaded hosts, adjacency scanning runs in one worker with at most one queued
vertex blob and one active job. Only flat vertex/attribute strings cross the
channel; cancellation tokens reject abandoned results. Its graph and full GC
stay in that worker. Without threads, the original cooperative scan remains.
Vertex capture and sparse attribute writes are cooperative: a 0.35 ms deadline
checked every 16 iterations, plus a 2048-iteration safeguard for a frozen
clock. Short joins can use the time budget instead of stopping after 128
iterations and delaying visible coverage for many frames.
Allocations/upload/GC are atomic and may exceed that target; health reports
the observed maximum rather than claiming a hard GPU-time guarantee. The
32 MiB total attribute budget bounds retained allocations. Combined city
meshes are no longer rejected at 256 KiB: their sparse attributes use the
same worker/scan and cooperative upload path. If the total budget is exhausted,
remaining meshes retain fiber shading without crease attributes. Mesh release cancels
pending work, while Card/renderer release frees Card-owned handles and textures.
On LÖVE 12 Metal, detached or replaced vertex attributes leave stale native
buffer bindings, including when a later shadow shader omits that attribute.
Retirement disables the input and retains one immutable attribute per live
parent mesh. Reactivation reuses that exact buffer; it never replaces it.
The weak-key registry has no reference back to its parent; a collected parent
allows the attribute handle to be collected too. Explicitly released parents
are pruned before new allocations and in health checks. Retired buffers count
against the same 32 MiB budget and are reported as `retainedAttributeBytes`;
`attributeBytes` counts active buffers. OpenGL continues to detach/rebuild.
Both paths preserve exact disabled pixels. The GPU test includes 16 complete
reactivations followed first by a shader without the attribute, matching the
Metal use-after-free reproduced in RC131.

Native captures pack 64 vertices at once into byte-identical float blobs, reducing
short-lived strings without changing cooperative deadlines. Worker failure retires
the worker and selects the cooperative scan; it does not disable the Card. A chained,
cancellation-aware `love.quit` hook releases a worker waiting on its channel.

`main.fragment.pre` computes first-order derivatives and texture LOD before
any discard. No nested `fwidth(dFdx(...))`, screen readback or extra world pass
is introduced. All uniforms use `UniformState`. Health reports CPU submission
and build slice times, pending/completed meshes, memory, budget-skipped meshes and detected crease
edges; GPU timings require an external profiler and remain unverified.

Tests cover identical GPU fold output in small and >256 KiB attribute meshes,
real combined-city coverage, dihedral edges, sprite/plant and
daypart exclusions, mipmaps, low preset, cancellation/release and repeated
exact rollback. The native world test freezes every render clock/random seed
and does not advance native animation between its compared captures. Empty
shader slots restore the shader captured before enabling the Card.

Its vertex seam only forwards `oasc_surface_edge` to a varying and declares
zero positional expansion, so it preserves scene/reflection culling.

RC55 stores rounded coordinates as compact numeric point IDs and distributes
edge adjacency across 61 dictionaries. This avoids retaining long coordinate
strings for every edge and reduces individual dictionary growth stalls. The
rounding, adjacency rules and uploaded edge attributes remain identical to
RC54. The differential fixture is copied from the RC54 release archive, with
its byte hash recorded under `tests/fixtures/rc54/provenance.json`.

A capture-free native Mac profile measured the Route 12 build-slice peak at
5.324 ms before and 2.089 ms after, with total cooperative build work falling
from 204.964 to 181.256 ms. Celadon's total rose from 188.365 to 195.436 ms;
this is not a universal load-time improvement or a hard frame-time bound.
Thirteen real map meshes (640,320 vertices) matched every classified edge
and every uploaded attribute byte. GPU timing and device acceptance are
separate from these instrumented CPU/wall measurements.
