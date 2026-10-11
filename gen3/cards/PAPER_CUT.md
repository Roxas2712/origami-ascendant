# Paper cut edges and stack contacts (Card 2)

`oasc.gen3.paper-cut` owns the `PAPIERKANTEN` toggle and configuration
`cards.paperCut={enabled=true,strength=.55,width=1,warmth=1,stackShadow=.55}`.
High/medium/ultra enable it; low/off omit its effects. Registration is one line
in `lib/cards/index.lua`. No engine or save changes.

The per-texture RenderSeams hook supplies the current mesh's atlas or actor
sheet. The shader adds a narrow paper edge to upright sprites, plants, fences
and signs. Ground faces are excluded. Actor sheets use cached exterior masks
reused from the existing sprite-rim cache when compatible, otherwise computed
from existing CPU pixels independently for each animation frame;
enclosed transparent eyes/holes remain unoutlined. No GPU readback is added.
Native tilesets are recognized by `midToSlot` before checking `quads`: both
tilesets and actor sheets expose quads, but only actors need a CPU exterior
mask. World atlases sample their alpha directly without constructing masks.
Transient textures without a source descriptor reset the effect instead of
inheriting a previous actor's mask. Paper brightness follows local illumination
so a cut edge does not become an emissive light at night.

The optional ContactShadows stack layer adds a smaller hard ellipse to each
existing contact mesh and actor upload, in the same draw/pass. Its 1.5-world-pixel
offset follows the projected light direction. Layer installation/removal
refreshes retained contacts without rebuilding the map. The layer's shader and
Card-owned masks are released on removal. Config is presentation-only because
cached contact records remain unchanged; unknown Card fields remain guarded.
Changes to ContactShadows itself still require a fresh source-validated bake.

Native GPU fixtures cover solid hard edges, direction, actor/static contacts,
exact legacy rollback, sprite interior holes, ground exclusion and resource
release. The native world test freezes clocks/randomness and requires exact
rollback in eight scenes. Shader construction without consumers remains
byte-identical to rc.4. GPU duration/Steam Deck budgets remain unverified;
health exposes CPU hook submission times and mask count, not invented GPU time.
