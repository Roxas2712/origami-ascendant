# Grass displacement (Card 1)

`oasc.gen3.grass-displacement` bends existing upright grass near moving player
and NPC feet. It adds vertex displacement through RenderSeams, without changing
meshes, saves or engine code. A stopped actor's displacement reaches exactly
zero within 0.4 seconds. Teleports and map changes clear motion history.

The card uses the existing grass material threshold (`BillboardAnchor.z >= 1.5`),
not the broader foliage threshold that also includes tree crowns. Wind remains
in the original vertex path. Up to eight nearest NPCs share pooled uniform
payloads; the low preset omits NPC influence. All uniform writes use UniformState.

Its vertex seam declares X/Z expansion of 12 world pixels: the summed actor
vector clamps to length 1 and lift clamps to 2, so the offset is at most 2*6.
Y contracts toward zero by a factor in [.5,1]. This bound preserves viewport
culling with the Card enabled, also in water reflections, at elevated terrain
and with wind. Shader text and cached geometry remain unchanged. Unknown vertex
Cards still disable culling; this Card does not weaken their fallback.

Own configuration: `cards.grassDisplacement` with `enabled`, `radius` (14 px),
`strength` (1), and `actors` (true). Toggle: `gen3Card_grassDisplacement`.
Deactivation unregisters every owned seam and removes its config and preset
fields. Release clears transient motion. Health reports CPU submission timings;
GPU timings are unavailable on the current instrumentation.

GeometryConfig owns a generic field-level presentation contract. This Card
registers only `enabled`, `radius`, `strength` and `actors`. Changing those
settings preserves the cached geometry key. Unknown fields remain guarded;
deactivation removes the contract. No cache source hashes may be relabelled:
changes to the generic projection implementation require a fresh native bake.

Unit coverage: `tests/gen3_grass_displacement_card_test.lua` checks walking,
recovery, teleport reset, nearest-NPC tracking, the eight-actor cap, low-preset
policy, map reset (including maps sharing one layout) and repeated lifecycle
cleanup. The GPU fixture checks actual shader compilation, grass displacement,
unmodified trees, exact standing recovery and disabled-versus-absent pixels.

`tests/gen3_grass_displacement_play_test.lua` captures Pallet at 06/12/20,
Viridian Forest, Mt. Moon, Route 12 in a storm, Lavender and Route 1. All eight
full-image rollback comparisons use frozen time and zero pixel tolerance.
The moving player changes pixels in both grass fixtures; standing recovery
also restores every pixel. Cache fingerprints match before/after activation.
`tests/gen3_grass_displacement_menu_play_test.lua` verifies default activation,
actual Card-menu deactivation/reactivation, unchanged geometry fingerprints,
real player walking and complete recovery. The high-preset native run recorded
0.0461 ms maximum CPU time for one Card hook call. This is not GPU duration;
GPU duration and Steam Deck budgets remain unverified.

Registration is only in `lib/cards/index.lua`. Removal is
that registration plus this card's listed impact files; no engine changes.
