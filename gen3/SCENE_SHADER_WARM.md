# Scene shader preparation

Mod loading prepares directional and contact shadow programs, optional shadow
blur, precipitation and cave/forest shaft and depth-fog programs before interactive field frames. Sky Life and Geometry FXAA prepare their owned resources on Card activation, respecting presets and device capabilities. Each renderer retains
its lazy compile path for full release/recreation. This moves compilation cost
into loading; it does not change shader source, quality, resolution or geometry.
Contact preparation also warms a registered paper-stack layer's variant before
the Card computes its intensity; it does not change the layer or geometry.
Removing that Card still releases its own variant. Rain chooses the actual instancing
capability, including its non-instanced fallback.

CloudShafts also prepares its program during protected mod loading when forest
lighting is enabled. Its first visible draw still selects sites and updates the
same mesh; it reuses the prepared program. Release retains the original lazy
recreation path. This removes a measured late compilation, not driver first-draw
stalls or all map-loading spikes.

`WorldRain.invalidate(true)` drops scene columns/meshes but retains the shader
on geometry configuration changes. Parameterless invalidation still releases
all resources. An instancing-mode change also performs a full invalidation.
Startup compilation uses the existing protected preparation block and shader
error diagnostics; an error triggers the existing renderer cleanup/fallback.

`tests/gen3_scene_shader_warm_test.lua` checks allocation lifetimes, variant
changes and first-draw reuse, with optional previous-version loaders for byte
comparison of compiled sources. Native fixed-time pixels and actual battle/rain
captures cover appearance separately. CPU submission timings are not GPU times,
and this change does not establish a full-frame performance budget.
