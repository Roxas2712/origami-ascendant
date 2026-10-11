# Paper UI — unavailable on the current engine

C15 explicitly requires `install={installed=false}` when native window drawing
has no public mod hook. This is the current outcome, not an implemented visual
effect. `PaperUiCard` reports the reason and refuses activation before making
any change. It owns no resources, hooks, config, presets or save data.

The audited public Gen3 host draws frames through `src.ui.game3.window` helpers
(`stdFrame`, `fixedStdFrame`, `userFrame`, `dialogueFrame`, `signFrame`) directly
into `Chrome`. Message and start-menu drawing call these helpers directly.
`ui.start_menu.items` changes menu contents, not window drawing. `render.hud`
is after the composite; it cannot separate frame opacity from native text or
place a nine-slice behind every dialogue/start/shop window.

No engine functions are replaced and no fictitious `ui.window.draw` hook is
registered. The diagnostic menu entry defaults off, explicitly labelled
unavailable. Enabling it still fails closed; it never advertises a live public
capability. A future engine with a documented window draw hook needs a tested
adapter and the actual paper artwork before this Card can be enabled by default.

Removal: delete the one index entry and both `impact.files`. Native window
functions, options, renderer and game state remain unchanged by this Card.
