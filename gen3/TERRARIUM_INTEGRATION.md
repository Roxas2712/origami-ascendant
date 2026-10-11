# Terrarium release integration · RC111

FireRed and LeafGreen use the current 86 Kanto compositions, including the
latest paper cutouts and effects. Emerald uses its own registry of 113 Hoenn
compositions. The existing ORIGINAL / KARTE / TERRARIUM preference remains
persistent; integration does not overwrite a player's saved choice.

The release includes all dynamic artwork names, shared paper modules, Kanto
reference parts, trainer supports, quiet events and vendor provenance metadata.
The public 0.3.61 mod-owned presentation bridge provides the required rendering
API; installed engine files and native combat rules remain unchanged. The source
patches describe older development hosts and are not an instruction to apply
every patch over a public installation.

RC110 startup ordering, loading companion and screen-space ghost eyes are
retained. The unrelated field anti-aliasing/daylight working changes are not
part of this frozen RC. Normal supported battles use terrariums when selected;
unsupported special modes retain their explicit native fallback.

Validation and images: ../output/oasc-rc111-20261010/. The package dependency
closure and all 178 dynamically referenced Hoenn/shared paper textures decode
from the staged package. Catalog GPU checks cover every 86 Kanto composition in
both edition contexts and 112 map-derived Hoenn compositions; the currently unused legacy
underwater baseline is separately tested as a presentation-only fixture.
Native imported-ROM battle fixtures cover all three editions, attack/faint
presentation, Dig placement, responsive layouts and return to map music.
These checks do not claim a full story playthrough or a performance guarantee.
