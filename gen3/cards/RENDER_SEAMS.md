# Render Seams

Card `oasc.gen3.render-seams`, capability `ascendant.render-seams.gen3/v1`.
The single registration line is in `lib/cards/index.lua`. F3 → Alle
Einstellungen → Render-Cards toggles the provider; disabling a provider first
deactivates dependent Cards. Its config lives only in `cards.renderSeams`.

Owners register shader strings or Lua functions, ordered by priority and then
registration order. Unregister removes every entry owned by that Card. Hook
errors unregister the failing owner and appear in health diagnostics. Empty
slots contribute zero bytes. Shader compilation occurs only when the seam
version changes and that pass's actual source changes; Lua-only or other-pass
changes retain its compiled program. A bad extension fails back to the
unextended renderer.

Shader slots: `main.defines`, `main.uniforms`, `main.functions`,
`main.vertex.pre`, `main.vertex.post`, `main.fragment.pre`, `main.fragment.albedo`, `main.fragment.lit`,
`main.fragment.final`, `finish.uniforms`, `finish.functions`, `finish.pre`,
`finish.post`. Vertex post runs before world position is captured. Fragment lit
runs after the initial lighting sum; final runs before output clamping.
Fragment pre runs at the function entry, before clipping/discard. Compute
implicit texture LOD and first-order derivatives there, with helper lanes live.

Hooks: `textureSource`, `shaderSource`, `prepare`, `bind`, `bindTexture`, `bindMesh`, `releaseMesh`, `beforeWorld`, `afterGeometry`, `afterWorld`, `afterActors`,
`beforeFinish`, `afterFinish`, `release`. Finish hooks form a Canvas chain.
`shaderSource` chains the complete main shader source at construction time;
its owners participate in shader compilation failure cleanup. With no owner,
it returns the exact input bytes. `afterGeometry` chains the scene canvas after
static meshes, instances and doors, before native effects and actors. A returned
replacement must retain the scene dimensions/format; the renderer reattaches
the existing depth buffer and updates `ctx.canvas` for subsequent consumers.
The reused frame context supplies native game/map references, projection,
atmosphere, player/actor positions, weather, delta/time, scene/depth targets,
and pixel dimensions. `hasSky` reports an active roof backdrop; `cloudLight`
references the frame's shared cloud-light state (read-only to consumers). A sky
consumer must still mask foreground geometry and the distant horizon.
Bind receives the prepared light list. Prepare precedes
light selection. Hook implementations must restore any graphics state they
change and must not retain the mutable context as a historical snapshot.

`textureSource(texture, context)` chains the primary texture for a single scene
draw. Its reused context exposes `shader`, `source` and `frame`. Replacements
must preserve atlas layout and dimensions. The renderer restores the mesh's
original texture after drawing. Consumers own and release replacement textures;
subsequent bindTexture/bindMesh hooks see the replacement. No consumers means
no texture mutation. `main.fragment.albedo` follows the original texture read,
before alpha tests and material lighting.

`bindTexture(shader, texture, ctx, source)` runs immediately before each
textured scene draw, including instanced scenery, reflections, actors and doors.
`texture` is the mesh's actual bound texture, not the current map's assumed
atlas. `source` is the native tileset or sprite descriptor when available; it
is nil for transient door textures. Consumers must reset any source-specific
uniforms on nil sources. Shadow/mask-only shaders do not dispatch this hook.
With no consumers, the shader source and all draws remain unchanged.

`bindMesh(shader, mesh, ctx, source, instanceCount)` follows bindTexture for
the same draw. Optional presentation attributes can be attached without
changing native vertices or geometry cache bytes. `releaseMesh(mesh)` runs
before cached world/instance meshes are released or invalidated. Consumers
must cancel their queued work and detach/release owned attributes there,
and release all remaining resources on the normal `release` hook. These
hooks do not authorize unbounded work on a draw call.

Vertex snippets may provide an optional fifth registration argument:
`register(owner, slot, source, priority, {x=12,y=0,z=12,ground=true})`.
These are conservative nonnegative world-space extents, after instancing and
all remaining vertex transforms, valid for every configuration of the snippet.
Omitted axes mean zero. `ground=true` includes Y=0 before expansion, permitting
contraction toward ground for positive or negative heights. Extents are summed
across active vertex snippets; the caller must account for composition with
other transforms. A snippet without declared bounds disables scene/reflection
culling. Removing its owner also removes its declaration. `vertexBounds()`
returns a cached read-only aggregate or nil for unknown/overflowing bounds;
disabling the provider returns zero extents. Cached mesh and bounds payloads
are unchanged.

Existing effects remain unchanged. Renderer and PaperFinish tolerate the
provider module being absent. Remove its registration line and impact files
only after its consumers have been removed. No engine file, gameplay rule or
save is modified by this Card.

WorldBorder and DepthOfField also resolve the optional provider once at module
load. Physical removal retains the unmodified border, player focus and native
depth reconstruction; it does not disable built-in DOF. The native
`gen3_render_seams_absence_play_test.lua` runs in two fresh private hosts, with
all render Cards disabled versus every listed impact file removed. It compares
seven frozen scenes with zero byte tolerance, verifies DOF actually executes,
and checks the 65,138-byte empty-consumer main shader against the rc.4 hash.
This catches missing-provider failures that menu-toggle tests cannot expose.

`submissionMs` measures elapsed CPU call/submission time; `gpuTimeAvailable`
is false. LÖVE's texture-memory statistics are not GPU timings. Hardware GPU
budgets require an external GPU profiler and are not certified by these tests.

Tests: `gen3_render_seams_test.lua` covers ordering, owner cleanup, disabling
and failure isolation. `card_rollback_test.lua` compares raw pixels for active,
disabled and file-absent runs and repeats the lifecycle to catch leaked state.

`frameCtx.depthScale` is available to draw hooks after binding the world
projection. Multiply clip-space Z by it when drawing into scene depth: some
interiors compress clip Z to 0.5. Using the unscaled VP alone would hide those
particles behind even the floor. This metadata does not change shader source.

`main.light.static` is inserted after the packed source parameters are read
in all three static-light consumers (world, actor vertex and water reflection).
Its local contract is mutable `vec4 color`, `vec4 params`, `float row` and
`vec4 position`. `main.light.window` follows `windowLamp` and exposes mutable
`vec4 lamp` plus `windowVariationCode`. Empty slots insert zero bytes.
StaticLightGrid optionally accepts `dataFilter(data,lights,grid)` at its
existing upload point; filters must preserve the original ImageData and own
any returned copy. Consumers that change packing must restore it consistently
in every shader path and invalidate runtime upload buckets when removed.

## Lighting and volumetric density

`lighting` is an identity-preserving chain over atmosphere, after cloud/sky
sampling and before environment preparation and shadow rendering. Consumers
return their own copies; shared day/night state must not be changed.
`frameCtx.skyEvents` and `weatherMood` are read-only inputs.

`fog.uniforms` and `fog.density` extend a consumer-owned fog integration (density slot has
`p`, `d`, `noise`, `tau` in scope); `bindFog(shader,context,time)` supplies owned
uniforms. Empty snippets reproduce the original fog source bytes. Shader
programs are rebuilt only when the seam version changes. A consumer must
release its private fog resources on deactivation. The legacy VolumeFog
module and its source fingerprint remain unchanged.

## Finish LUT and fog parameters

`beforeFinish` may provide `ctx.lutOverride={a,b,mix,amount}` using owned LUT
textures; it must clear its reference on release/deactivation. Optional
`identity=true` bypasses grading exactly, and `preserveLegacy=true` retains
the existing warmth/saturation controls. Without an override the old grading
path is unchanged. Both paths send LUT uniforms through UniformState so that
switching consumers cannot leave stale cached values.

`fogParams(params,def)` chains the existing SceneFog parameter table before
haunted-fog adjustments. Consumers return an owned copy when changing values,
never mutate shared color arrays, and receive no call if no fog is present.
Without consumers it returns the exact original table.
