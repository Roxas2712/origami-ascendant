# Camera drama

`oasc.gen3.camera-drama`, `ascendant.card/v1`, requires RenderSeams.
Registration: one entry in `lib/cards/index.lua`. F3 option: **KAMERA-BEWEGUNG**.
Enabled in medium/high/ultra, disabled in low/off. No engine changes or save writes.

The `camera` chain runs before connection selection, border coverage and the
camera matrix. The Card returns one reused `Camera.override` table. With no
consumer the renderer clears that field to nil; the existing camera is exact.
Optional zoom and offsets also expand camera coverage, so leading the player
does not expose missing border geometry.

- Native field text (`Message.isOpen`) zooms to 1.12 over 0.4 seconds with cubic
  ease-out; closing it returns to the previous framing. Retargets start at the
  current value. Gen3 text is not a Stack layer; menus alone do not zoom.
- Movement leads by six world pixels. An analytic critically damped spring
  (omega 8) handles stopping and direction changes. Teleports reset the lead.
- Entering town/city map types 1/2 starts at 0.92 and returns to 1 over 0.8 seconds.
- With `billboards.preservePixelAspect`, the final zoom factor uses 1/8 steps.
  This intentionally limits the number of visible zoom positions.
- Native scripted camera targets, battle presentations and active battles take
  precedence. There is no field camera motion in a battle.
- `shake=false`: no verified native field earthquake event is available.

Configuration lives only in `cards.cameraDrama`:
`enabled=true, dialogZoom=1.12, lead=6, cityPullout=true, shake=false`.
Those five fields have an owner-scoped presentation-only geometry contract;
unknown fields remain guarded. A changed Camera source still requires refreshed
cache provenance; geometry payload comparisons must accompany the package.

The Card uses `V.clock()` for deterministic captures. Repeated draws at the same
time do not advance its spring. Health exposes zoom, offsets, state and seam CPU
measurements. It allocates no GPU resources and claims no GPU-time measurement.

Rollback: disable the menu toggle, or remove the index entry and the two files
listed in `impact.files`. Deactivation removes both hooks, config and geometry
contract, restores preset fields and clears the owned override. Shared optional
camera fields remain inert when the Card is absent.

Tests: `tests/gen3_camera_drama_test.lua`,
`tests/gen3_camera_drama_play_test.lua`, `tests/card_rollback_test.lua`.
Native QA must use a private `oasc-firered-rc-qa-*` identity.
