# Origami Ascendant

**Version 1.0.0** — paper diorama worlds for Pokémon **FireRed, LeafGreen and Emerald**, running in gen1recomp.

[Download the installable ZIP](https://github.com/Roxas2712/origami-ascendant/releases/download/v1.0.0/Origami-Ascendant-1.0.0.zip) · [Release notes](https://github.com/Roxas2712/origami-ascendant/releases/tag/v1.0.0)

## Install

1. Install gen1recomp and import your own supported game ROM.
2. Download **Origami-Ascendant-1.0.0.zip** from Releases. GitHub's automatic “Source code” archives are for developers; use the named mod ZIP for installation.
3. Import the ZIP through gen1recomp's mod manager, enable **Origami Ascendant**, and restart the application completely.

No ROMs, saved games or engine binaries are included. Tested with gen1recomp **0.3.75 / LÖVE 12**. Historical engine patches bundled under `engine-support/` and `gen3/engine-patches/` are reference material for their stated versions; do not apply them indiscriminately to current engines.

## Features

- Paper diorama overworlds, dynamic lighting, shadows, weather and regional atmosphere.
- Original, MAP and unfolding Terrarium battle presentations on supported maps.
- Adaptive CRISP presentation, with a softer daytime background and stronger night/cave atmosphere.
- English settings menus and saved field zoom levels: **0.75×, 1×, 1.25×, 1.5×, 2×**.
- FireRed, LeafGreen and Emerald support. Ruby and Sapphire are not part of this release.

## Controls

| Action | Control |
| --- | --- |
| Open Origami settings | **O / F3** |
| Change overworld camera angle | **V** |
| Cycle field zoom | **C** |
| Step field zoom | Mouse wheel or **+ / −** |
| Controller field zoom | Hold **L**, then D-pad **up / down** |
| Smartphone field zoom | Pinch or spread two fingers on free overworld space |
| Change supported battle view | **F6 / 5**, or Battle View in settings |

**Z remains the native confirm button.** Touch controls do not start a zoom gesture. Interior and cave zoom is constrained while retaining the selected outdoor value. Photo mode and battle camera controls remain independent.

## Release scope and validation

1.0.0 is the frozen **RC133** runtime, with public-release metadata and documentation. It includes the Surf renderer fallback fix, supported Emerald MAP battle detection, matching actor render targets and the Field Zoom Card.

Native Mac checks cover all three editions, Surf entry/movement, Emerald MAP battles, fourth-move execution, settings during battle, zoom input and persistence. Metal and OpenGL render-target checks were performed. Mobile rendering and touch paths were simulated on Mac; **this exact release has not been verified on a physical iPhone**.

Known issues and limits:

- Cold map or battle-view builds can still cause frame-time spikes. Further performance work is not included in this release.
- Wet footsteps have been reported as too loud compared with music.
- A persistent rapid sound was reported at Nugget Bridge without rain. It has not yet been reproduced or fixed; this is tracked separately from footstep volume.
- A fourth-move selection issue reported by a player has not been reproduced locally; local execution passed in Original, MAP and Terrarium views.

## Support

Use **O → Support → Errors / Send logs** to submit a diagnostic report, or open a GitHub issue with the game, engine/mod versions, device, map, battle view and reproduction steps. Log submission is user-initiated; review the report before sharing it. Do not attach ROMs or private save files to public issues.

## Source and licensing

`manifest.json` is the mod descriptor; `gen3/entry.lua` loads the runtime. Source and runtime assets are included here. `SOURCE-SHA256.json` records the packaged files. Internal QA identities, player data, private logs and development history are excluded.

Existing license and attribution files are preserved. See [LICENSE](LICENSE) and bundled third-party notices. Pokémon and related names belong to their respective owners; this is an unofficial fan project.
