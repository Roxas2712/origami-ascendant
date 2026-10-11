# Cooperative native map construction

`Renderer.cooperative` enables `NativeBuildQueue`. Production enables it in
`main.lua`; offline capture/bake tools can leave it false for synchronous builds.
The queue resumes one job at most once per renderer tick with a 2 ms cooperative
budget. `BuildBudget.check()` and `tick()` only yield from that owned coroutine.
Calls made by the engine or a QA coroutine remain synchronous.

An entry is published only after its geometry, water bounds, heightfield, cave
caps and instance uploads are complete. An invalidation cancels the job and
releases its unpublished GPU objects. Previously published entries are released
when a replacement is complete. While an entry is pending, the renderer retains
the last finished picture and the field update holds input/simulation while
continuing audio. On initial startup a neutral loading canvas is used.

The budget is cooperative, not a hard frame deadline. GPU allocations/uploads,
Lua garbage collection and operations between checks can exceed 2 ms. Building
all visible neighbors can still take several seconds. This implementation does
not certify stable 60 FPS or eliminate first-action audio/graphics stalls.

`PerformanceLog.wrap` uses `BuildBudget.workTime()` inside a job. This excludes
frames spent suspended, so a two-second load is not reported as two seconds of
continuous CPU work. Timings remain CPU-side elapsed/submission measurements,
not GPU timers or process utilization. `native geometry slice …` records each
resume; the phase is the phase at the end of the slice.

Verification on public gen1recomp 0.3.61 / LÖVE 11.5, private macOS QA identity:

- `gen3_build_budget_profile_test.lua`: suspension excluded; normal timing and
  return values retained; foreign coroutines cannot consume the job budget.
- `gen3_native_build_queue_test.lua`: single resume per frame, atomic publication,
  cancellation and failed-build GPU cleanup.
- `gen3_native_build_parity_play_test.lua`: exact binary equality of vertices,
  instance placements, statistics, heightfields, water bounds and cave caps for
  Route 1, Oak's Lab, Diglett's Cave B1F and Viridian Forest.
- Frozen rc.6/rc.7 captures: zero differing bytes in Pallet, Viridian Forest and
  Diglett's Cave. Raw empty shader builders remain byte-identical to rc.4.
- Four complete MAP battles plus F3/V field/battle menu and return-to-field tests.

Checkpoint artifacts and measured limitations are recorded outside the repository
in `output/oasc-native-slicing-20261007/` and the immutable rc.7 release directory.
