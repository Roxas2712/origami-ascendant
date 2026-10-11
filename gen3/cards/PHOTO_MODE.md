# Photo mode

F8 or SELECT+L enters from an idle field. The public `core.update` hook pauses
native simulation; input belongs to the preview until exit. Battles, warps,
menus and incomplete map builds cannot enter photo mode.

Arrows / left stick pan, Q/E zoom (0.5–3), R/F tilt (20–65 degrees).
Right stick changes zoom/tilt. Brackets select a row, minus/plus change its
value. Controller D-pad selects rows/values. Enter/X exports PNG; Tab/A hides
the inspector; Escape/B or F8 / SELECT+L returns to play.

Preview rows control time, weather, focal distance, depth blur, tilt shift,
vignette, LUT and 1–4× export size. Only mod presentation state is temporarily
overridden. No saved option setters, session writes or engine replacements
are used. Exit/disable/abort restores the original time/clock functions,
weather getter and visual state, camera override and postprocessing values.

Exports render the world again at the requested physical dimensions. They are
not enlarged screenshots. PNGs live in the mod's private `screenshots/`
directory through the host filesystem API. Touch controls and native windows
are not in the exported texture. Unsupported texture dimensions decline with
a message. Export timing is reported in health and remains a device-specific
acceptance gate, not a guaranteed frame rate.

Removing the index entry plus `impact.files` removes controls and hooks. Shared
optional `Camera.override.elevationDegrees` and `focusPoint` seam are inert
without a consumer. They do not change the native camera geometry cache key.
