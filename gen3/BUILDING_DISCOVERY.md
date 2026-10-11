# Building discovery allocation cost

The native building flood fill uses two numeric coordinate arrays instead of
a separate table for every queued point and four fresh direction tables per
visited cell. Neighbor order, door traversal, the 1024-entry guard, decorative
building thresholds, bounds and detached-prop exclusions are unchanged. There
is no retained map cache; every call observes the current layout.

The exact RC59 discovery function is retained in
`tests/fixtures/rc59/building_discovery.lua`, with its source hashes alongside it.
`tests/gen3_building_discovery_test.lua` compares every field and mask entry,
including which returned building owns each masked cell. A native run checked
426 hydrated map layouts with 194 discovered buildings. A second check rebuilt
Pallet, Viridian, Celadon and Fuchsia from both implementations: all 369,090
vertices (nine fields each), statistics, contacts, lights and instance records
were equal. Cache geometry payloads can therefore be retained for this change;
the packaged index must still update the exact WorldGeometry source digest,
and normal source validation must pass. Never disable the cache guard.

Measured on the local native Mac host, 60 alternating calls per implementation:

| City | RC59 median / candidate (ms) | Temporary Lua heap before / after (KiB) |
| --- | --- | --- |
| Pallet | 0.5095 / 0.4616 | 78.97 / 30.70 |
| Viridian | 1.0689 / 1.0280 | 94.41 / 39.91 |
| Celadon | 2.4117 / 2.2533 | 258.72 / 78.70 |
| Fuchsia | 1.7522 / 1.6164 | 244.82 / 53.91 |

These are building-discovery wall times and a separate GC-stopped heap sample,
not full map-load, frame, render-thread CPU or GPU times. The candidate Celadon
run contained a 17.04-ms outlier; p95 was 2.53 ms versus RC59's 3.12 ms. No hard
frame-time bound or device performance acceptance is claimed. Particle setup
also invokes this shared discovery, but its other setup costs remain.
