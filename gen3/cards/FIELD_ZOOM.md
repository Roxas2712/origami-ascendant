# Field Zoom

Card: `oasc.gen3.field-zoom`, option `gen3Card_fieldZoom`.
Registration lives only in `lib/cards/index.lua`.

- Saved levels: 0.75x, 1x, 1.25x, 1.5x, 2x. Default 1x.
- **C** cycles, wrapping after 2x. Z remains native A/confirm.
- **+ / = / -**, keypad equivalents and wheel step without wrapping.
- Controller: **L + D-pad up/down**, without SELECT. The triggers retain
  the engine's speed controls. SELECT+L Photo and SELECT+R graphics remain.
- Smartphone: **pinch with two fingers on free world space**. Spread to zoom
  in, bring fingers together to zoom out. 20% distance change steps once;
  150 ms debounce. One-finger drags and virtual controls never become a pinch.
- Touch menu: **O → Camera / quality → Field zoom**. Full menu: **CAMERA**.
- Menus, battle transitions, battles, loading/fold handoffs and Photo Mode
  retain input ownership. Native keyboard rebindings take precedence over C.

`gen3FieldZoom` persists in mod options, never in the player save. Rooms and
caves constrain the displayed level to 1–1.25x, without overwriting the saved
outdoor level. An optional 0.8-second notification displays the effective
rounded level and `(ROOM)`. Disable it with `gen3FieldZoomHud`.

The ease lasts 0.25 seconds (exponential tau 0.08, exact endpoint). At its
endpoint, the camera rounds the 16-pixel ground tile's projected horizontal
width at the focus foot to the nearest world-target pixel, both orthographic
and perspective. Health reports nominal/actual level, tile width and target
width. If an unusually small target makes integer rounding differ by more
than 2%, nominal magnification is retained and `roundingLimited` reports it.
This does not disable existing postprocessing or promise that every texel on
sloping/background geometry maps to an integer number of screen pixels.

Outdoor fitting clamps camera position but preserves magnification. Existing
Horizon and WorldBorder coverage supply the background. No geometry key,
render-target resolution, prefetch or native player/collision state changes.
`health().draws` records visible geometry entries and whole-frame draw calls
by level. The FPS HUD adds `visible=` while this Card owns the field camera.
Fewer visible entries are not a claim that the whole map costs less to load.

Disable the Card to remove its hooks, menu section, pinch handlers, HUD and
camera wrappers. Camera zoom resets to default and the original continuous
wheel handler is restored. Photo Mode keeps its independent override.

Native regression: `tests/gen3_field_zoom_play_test.lua`, with private ROM
fixtures through the existing battle QA host. Desktop Metal/OpenGL, iOS render
simulation and synthetic input events do not replace a physical iPhone test.
