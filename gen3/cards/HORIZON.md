# Distant paper scenery

`oasc.gen3.horizon`, option `gen3Card_horizon` (FERNE KULISSEN).
High/medium enabled; low/off disabled. No engine patch or saved game writes.

`cards.horizon = {enabled=true, parallax=true, sets={default='kanto-hills', coast='sea'}}`.
Individual native map IDs can override the set. Four packaged 1024×256 RGBA
paper silhouettes supply clouds, two mountain ridges and sea. Their tint follows
ambient light and weather; the existing aerial perspective values are applied.

Three world-space vertical layers sit beyond the union of the actual connected
map footprints. Camera-relative horizontal rates are 0.15, 0.3 and 0.5. A lower
world plane continues the distant land/sea around side and south edges, using
the same depth buffer. It follows the existing projection, including the
below-ground depth correction for architectural verticals. No camera angle,
resolution, map collision or connected-map geometry changes.

The generic `focusMetadata` seam supplies visible backdrop pixels with their
actual world-space distance along the view direction. A depth-tested replay
into one RGBA16F canvas prevents the architectural depth correction from
mistaking below-ground scenery for foreground. Native geometry keeps the
existing depth reconstruction. This canvas is allocated only while DOF runs.

The optional `borderBounds` seam limits only the synthetic repeating ROM border
to a camera-padded continuation instead of a fixed four-tile tabletop. Water
and land retain their native ROM border material; only the local camera
footprint is generated and the existing three-cell mesh cache stays bounded.
The field camera also respects this generated coverage with the horizon Card
disabled. A 32-pixel fade applies only beyond the play view; real
maps are untouched. Indoors, caves, battles and authored rooftop vistas retain
their original border and background. Failed resource allocation keeps the
original border intact.

On activation, an enabled preset prepares the shader, four textures and four
meshes before the first visible border draw. This moves allocation cost to
activation; it does not remove the work. `health().resourceMs` reports that CPU
wall time separately from draw submission. Low/off or disabled config do not
preload. After renderer release or a later preset change, the existing lazy
path recreates resources. Partial failures release temporary FileData as well
as every completed GPU resource and retain the original border. Retry requires
deactivation/reactivation, avoiding an allocation failure on every frame.

Remove the single registration in `lib/cards/index.lua` and all `impact.files`
to remove the Card. Deactivation releases four images, four meshes and one
shader and the optional distance canvas, unregisters hooks, removes its config/preset entries and drops the
synthetic-border cache. The generic border seam returns the unmodified path
without consumers. Geometry cache payloads do not depend on this presentation.

Validation: `tests/gen3_horizon_test.lua`, `tests/gen3_horizon_resource_lifecycle_test.lua`, `tests/gen3_horizon_play_test.lua`
and the shared `tests/card_rollback_test.lua`. Submission timing in `health()`
is CPU timing; GPU timing and physical iPhone acceptance remain separate gates.
