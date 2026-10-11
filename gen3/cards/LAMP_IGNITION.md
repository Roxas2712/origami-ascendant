# Lamp ignition Card

`oasc.gen3.lamp-ignition` / `ascendant.lamp-ignition.gen3/v1`.
F3: **LAMPENSTART**, enabled by default. Requires RenderSeams only.

`DioramaConfig.cards.lampIgnition={enabled=true,spread=90,flicker=12}`.
The existing 1200-unit day dial is the sole time source. Dusk begins at 600
(18:00); 90 cycle seconds spread the final lamps through 19:30. Each pane
uses its existing stable WindowVariation building/pane tag. After its delay,
twelve 0.25-cycle-second pulses alternate 30% and 100%, then retain full power.
Clock speed accelerates this sequence together with the sky. `flicker=0`
disables the pulses. Dawn retains the established fade. No arrival timestamp,
player distance, camera coordinate, RNG, source discovery time, or save write
participates. Entering at night immediately shows already settled lamps.

Applies to tagged outdoor household windows and their ground spill, actor
illumination, planar reflections and water specular reflections. Existing
window colours and household dimming remain. Untagged fixtures, pond lights,
flames, lightning, cave crystals and indoor lights retain their established
behaviour. This is not a global blink applied to every kind of illumination.

The Card uses the generic `main.light.static` / `main.light.window` seams.
StaticLightGrid's optional `dataFilter(data,lights,grid)` receives the original
CPU source table read-only and returns an owned upload copy. No extra shader
sampler: the existing 0/1 point flag holds the stable 14-bit pane seed in its
signed range; its native >0.5 predicate stays valid even on shader fallback.
All three source consumers restore the flag before use. This fits
existing 16-sampler hardware with the other Cards active. Catalogue uploads
keep their existing cadence; ignition is evaluated on GPU every draw. At most
four CPU copies are retained. No new render pass or per-frame GPU upload.

Activate/deactivate invalidate only runtime light uploads, never geometry.
Deactivate restores the previous filter, removes seams, config and preset
entries and frees owned ImageData. `health()` reports CPU seam submission,
owned catalogue count, tagged sources and filtered uploads. GPU timing is not
available. Remove its single index entry and the two `impact.files` entries
to remove the Card. Generic seams emit no shader bytes without consumers.

Tests cover all 16,384 pane identities, phase/wrap determinism, native GPU
factor parity, native town/cave rollback, fully settled daytime/nighttime,
F3, and separate-process physical file removal. Shared rollback captures
freeze time, weather, RNG and actor updates; tolerance is zero pixels.
