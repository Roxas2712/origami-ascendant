# Folding map transitions

`oasc.gen3.fold-transitions`, `gen3Card_foldTransitions` (FALT-UEBERGAENGE).
Medium/high/ultra enabled; low/off disabled.
`cards.foldTransitions={enabled=true,duration=.55,doors=true,maps=true}`.

Native fade-out captures the last finished field image. A connected paper-facet
mesh folds it into one of seven colored models: Charmander, Squirtle, Bulbasaur,
Pikachu, Eevee, a heart or a red-and-white Pokéball. Each direction takes 0.55 seconds by default. The
fully folded pose is drawn and held for at least 0.40 seconds before the ready
destination unfolds. A slow load retains this pose, with the small VASC loading
badge above it. The loading cover must never conceal the model.

These are stylized animated paper facets, not a physical origami solver. Pixel
positions and UVs share crease endpoints; the open sheet covers the full surface.
The geometric details and colors require no extra textures or render targets.
FireRed, LeafGreen and Emerald ordinary map/door fades use the Card. Instant
warps and battle transitions retain their native behavior. Player input waits
while the sheet is visible; native warp tasks and audio keep running.

Only the active transition owns one canvas, one mesh and one shader. Disable,
abort or renderer release frees all three. Idle frames only reference the
existing finished field canvas. No native session, save, fade timer, map target
or collision rule is rewritten.

Tests cover seam equality, full-sheet reconstruction, seven distinct models,
completed-pose hold, actual pixel visibility above the loading cover, real door
entry/exit, map warp, instant warp, removal, input release and native targets.
CPU submission timing in health is not GPU frame timing.
