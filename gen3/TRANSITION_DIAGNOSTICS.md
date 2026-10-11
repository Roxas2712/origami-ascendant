# Map-transition diagnostics

`TransitionTrace` records at most 48 distinct steps per transition through the
public mod cache API in `OASC-TRANSITION.txt`. It also flushes the support report
`OASC-ERRORS.txt` at those steps. There is no per-frame file write.

The trace identifies source/destination map, stairs/door kind, player cell, actual
engine/LÖVE/renderer/GPU, physical surface size, quality, render-target size and
format, build key/phase, cache rejection, worker failures, shader source hash and
Lua/texture memory. Those memory values are **not total process RAM**. Native
pointer addresses are unavailable through the public API; source hashes and build
keys identify the relevant operation instead.

The preceding map trace is read before the first new transition and included in
the next support report. A Lua draw error is protected and logged. A native crash
or OS termination cannot run Lua handlers, but may leave the last flushed step.
The iOS `.ips`/Jetsam report is still needed to distinguish a GPU crash from an
OS memory kill. These files contain no ROM bytes, saves or network upload.

RC116 adds the verified render-only bridge for engine 0.3.74 and uses its native
animated atlas revision buffers. It does not reinterpret a 0.3.61 geometry cache
as 0.3.74: a rejected fingerprint selects a live build under the loading cover.

Regression evidence is stored outside the mod in the RC116 QA output. Actual
macOS LÖVE 12/Metal room warps and simulated mobile allocation limits are desktop
tests, not physical iPhone acceptance.
