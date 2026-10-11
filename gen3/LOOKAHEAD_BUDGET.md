# Incremental geometry lookahead catalog

GeometryCacheLookahead groups validated scene records by destination map before
selecting nearby warp/connection targets. This initial grouping previously ran
entirely inside the first rendered map frame.

The catalog now builds in a coroutine across updates. Each update processes at
most 128 checkpoints, with a 0.5 ms soft wall-time deadline checked every 16
operations. Per-map sorting remains atomic. The bound also works when a QA
clock is frozen. The ordinary 0.25 s target-selection throttle starts only
after grouping finishes; it never delays an unfinished catalog.

Until completion, prefetch targets are empty. Native rendering retains its
verified synchronous cache/native geometry fallback. Once complete, selection
uses the current map and player position, with unchanged primary-scene order,
configuration/projection filtering, deduplication and four-target limit.
Replacing an index, disabling the cache or releasing the renderer abandons
the pending catalog and clears stale CPU/GPU targets.

## Evidence

- `tests/gen3_geometry_lookahead_test.lua`: canonical/neighbor ordering,
  malformed records, 4096-scene sliced construction, movement while pending,
  replacement, disable/re-enable, release, and version-1 filenames.
- `output/oasc-lookahead-budget-20261009/`: native RC60 comparison across
  426 hydrated maps at five positions each (2130 cases). Ordered digests and
  filenames match exactly.
- An instrumented cold High run reduced the first Pallet lookahead update
  from 17.323 ms to 0.183 ms. Later lookahead calls still reached 2.654 ms,
  mostly configuration validation (2.611 ms), outside catalog construction.
  These are individual Mac runs, not a physical-device or frame-budget gate.

This change also ships with cooperative live cache activation
(`CACHE_ACTIVATION_BUDGET.md`). First-frame rendering remains a separate open
performance issue; this does not establish smooth gameplay on all hardware.
