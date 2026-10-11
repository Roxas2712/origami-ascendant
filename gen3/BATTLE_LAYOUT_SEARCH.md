# Reuse the battle placement search order

`PaperBattleScene` prepares the ranked configuration offsets once at mod load.
The default 3 scales × 5 angles × 19² offsets produce 5,415 candidates. A changed
search radius or changed scale values rebuilds the one retained list, including
in-place edits. Footprint sample offsets are also reused.

Only the search order is retained. Every battle still reads current collision
and geometry, checks feet and body sightlines and fits the original HUD frame.
Neither the selected scene nor map-dependent height/walkability results survive
a call to `create`. Score arithmetic and ordinal tie-breaking are unchanged.

Native private-identity verification against the RC40 source:

- 70 exact scene/reason comparisons across Route 1, Diglett's Cave and Oak's Lab,
  wild/trainer layouts, nearby positions, radius/scale edits and blocked/restored
  collision. Every resulting coordinate, fit distance and frame is identical.
- Five complete native battles, unchanged High 960×640 canvas and 50° field
  camera. The measured cave introduction update maximum fell from 62.19 to
  22.52 ms across the two local runs. This is not a universal frame-time bound.
- Measurements wrap the actual game update/draw, excluding the QA driver's
  setup and TSV export. Earlier return-to-map spikes from that export were not
  game update costs. Process CPU and wall time are stored separately; no GPU or
  physical iPhone timing is claimed.

Rollback: restore the RC40 `PaperBattleScene.lua`. No cache, engine or save data
changes are required.
