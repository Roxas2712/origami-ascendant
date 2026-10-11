# OASC error reports

The Errors / Send logs entry is available in the F3 quick menu and the full
ASCENDANT menu, in the field and in battle. Touch controls and controller input
use the same native Gen3 modal stack. Rendering failures retain the native view
and diagnostics instead of aborting startup.

Adapted from VASC's ErrorInbox, ErrorsMenu, SupportLogs and SupportSend. Reports
include bounded error details, graphics backend, device information exposed by
LÖVE, selected graphics settings, map/position and frame-time summaries. They do
not attach ROMs or saved games. OASC uses its own ORIGAMI_ASCENDANT receiver ID.

The latest nonempty incident log is stored as OASC-ERRORS.txt in the mod cache
when an error is recorded and on normal exit. The previous session is included
in a manual support submission. An empty session does not erase the prior log.

Opening the menu does not send anything. The confirmation page requires a
second action. Transport is ticket-authorized, bounded to 500 KiB, asynchronous,
redacts personal paths / tokens, and has cancellation, timeout and cooldown.
Only confirmed successful responses are shown as sent. The iOS request bridge
is retained from VASC; physical-device acceptance must be tested separately.

All auxiliary OASC shader construction uses ShaderCompiler.newShader, which
normalizes both shader stages through SurfaceDerivatives.language. It does not
replace the engine's global compiler or change exported rc.4 shader source.

Validation: gen3_support_logs_test.lua; gen3_aux_shader_play_test.lua;
gen3_mobile_shader_test.lua; tools/qa_shader_gles_link.cjs. Live backend support
adds ORIGAMI_ASCENDANT to routing, deduplication and retention matching; previous
VASC/KASC transport tests remain applicable.
