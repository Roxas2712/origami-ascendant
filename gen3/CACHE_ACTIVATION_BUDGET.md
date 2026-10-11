# Cooperative cache activation

GeometryCache already restores cached geometry through NativeBuildQueue.
Activation also resolves live flower templates and registers furniture. On a
cold Alabastia load, room planning and building each took about 11 ms and ran
consecutively without a budget checkpoint.

Activation now checks the existing build deadline after template creation,
mesh upload/attachment, furniture planning and furniture registration. The
flower placement loop uses the existing sampled budget tick. Synchronous
callers retain their behavior; the queue only publishes a fully activated
scene. Newly uploaded meshes enter the existing ownership list before any
checkpoint, so cancellation releases them.

The cache payload, shader, camera and appearance do not change. A release must
refresh the GeometryCache source digest in its cache index; this does not
permit bypassing source validation or changing geometry payloads.

## Validation

- `tests/gen3_cache_activation_budget_test.lua`: deterministic expired budgets,
  phase separation, synchronous/queued result and heightfield equivalence.
- `tests/gen3_cache_restore_slices_play_test.lua`: real GPU vertices and metadata
  match the RC60 synchronous restore on Pallet, Diglett's Cave, Rock Tunnel,
  Viridian and Oak's Lab. Cancellation after live template creation, room
  planning and room building releases every allocated mesh; a fresh restore
  succeeds after each cancellation.
- Native High profile in `output/oasc-cache-activation-budget-20261009/`:
  Pallet's maximum queue call fell from 23.588 to 12.946 ms. Total queue work
  was 63.799 versus 63.332 ms, over 17 versus 19 calls. This is one matched
  pair of instrumented cold runs, not a percentile or target-device claim.

First-frame rendering still exceeded 180 ms in this fixture. Border generation,
shadow/rain setup and lookahead remain separate measured contributors. Atomic
operations can exceed the 2 ms cooperative budget. Full frame/GPU acceptance
and physical iPhone/Steam Deck validation remain open.
