# Water contact Card

`oasc.gen3.water-touch`, F3 **WASSERKONTAKT**, default on. Own configuration:
`cards.waterTouch={enabled=true,ripples=true,rainRings=true,foam=.5}`.
The off preset suppresses activity. No collision, save or battle logic changes.

Four reusable surf slots react to native player cell crossings while surfing;
eight rain slots share the 12-element uniform array. Surf waves fade in 1.6 s,
rain rings have a maximum lifetime of 0.6 s. Each advancing frame emits two
seeded rain impacts, or four during a storm, into the rotating rain pool.
At normal frame rates new impacts replace the oldest before their maximum
lifetime; surf wakes retain their separate slots. Repeated draws at frozen
time emit nothing further. No engine random state is consumed.
Rain strength follows the visible precipitation front (including fade-out),
not the next requested weather mode, so rings do not start before the drops.

Bank distance is encoded in a Card-owned R8 map (one byte per tile: cardinal
and diagonal bank adjacency). A vertex texture lookup passes the bank bits to
the water fragment, which computes the exact local distance to those edges.
This leaves the already-full fragment texture budget unchanged and preserves
the middle of narrow channels. The native atlas is never modified or filtered.
Only rendered water faces receive the effect. Banks at map boundaries are not
invented; the neighbouring map may continue the sea.

Coverage combines native surfable cells with horizontal water-material triangles
from the existing current-map mesh. This includes decorative basins and blocked
coastal water without changing collision. Each partial cell gets an interior
rain origin from its clipped triangle, including one-pixel basin strips.
Vertical water and solid surfaces are excluded. Bank adjacency stays at tile
resolution; the water material clips effects at curved or partial surfaces,
so this is not a per-pixel shoreline distance field.

Mesh scanning yields every 64 triangles, tile scanning every 128 tiles. The
Card pumps work toward a 0.35 ms CPU slice; this is not a hard frame guarantee;
the final tiny texture upload is indivisible and measured separately within
the build sample. Layout identity/revision or mesh replacement rebuilds the mask. Only one
map texture and one empty fallback image are retained. Indoor pools are recognized as water, but do not receive outdoor rainfall.
Surf wakes still require native surfable cells and actual surfing.

The bank foam follows rain or nearby ripple motion. Stationary dry water has
no contribution. Both foam and waves modulate existing light rather than
adding unlit white pixels at night. Normal display resolution is unchanged.

Remove the registration line in `cards/index.lua` and these owned files:
`lib/cards/WaterTouchCard.lua`, `lib/cards/WaterTouchMap.lua`, this document.
Deactivation removes all seams/config/preset fields and releases textures.
Seam telemetry reports CPU submission; GPU timers are unavailable in this
host and are explicitly not claimed as GPU measurements.

Native acceptance: 24 Medium/High scene pairs cover Pallet dawn/noon/night,
Viridian Forest, Mt. Moon, Route 12 storm, Lavender, Viridian's pond, Celadon's fountain (rain/dry), Six Island coastal
water and the Cerulean Gym pool.
Dry stationary views are byte-identical; wet views change water receivers.
Real native surf movement (23 and 47 pixels), F3, ring lifetime, weather-front
gating and unchanged engine RNG are tested. A GPU oracle checks 65,536 bank
distances, including narrow channels. Removing the registration and all three
owned files in a fresh process matches disabled output with zero changed pixels.
Four complete fire/snow/indoor/cave battles retain the 960×640 composite.

Original evidence is in `output/oasc-water-touch-20261008`; additional coverage
evidence is in `output/oasc-water-coverage-20261008`. Samples of prepare CPU time
and final map-build slices are recorded, not represented as GPU execution
measurements. Target-hardware GPU budgets remain open. No existing engine or player save files were changed.
