# Floor atlas mipmaps — oasc.gen3.atlas-mipmaps

Own toggle `gen3Card_atlasMipmaps`; own config
`cards.atlasMipmaps={enabled=true,bias=-.5}`. Low/off presets bypass it.
It samples only horizontal floor materials at camera elevation below 45 degrees.
Near magnified texels keep native nearest sampling, transitioning into the
trilinear sample only under minification. Sprites and other material classes
continue to use nearest samples of the untouched level-zero pixels.

The native combined atlas contains foliage too; changing its global filter is
unsafe. The Card owns a separate same-size canvas with manual mipmaps and borrows
the primary texture slot for one draw. `textureSource` restores the original mesh
texture afterward. No additional sampler is consumed: the full existing actor
lighting/rim program already uses the device's 16-sampler budget.

Primary-texture reads are redirected to exact texel-center level-zero samples;
other samplers (shadow, light grid, alpha masks, paper fiber) are unaffected.
The albedo seam selects trilinear sampling only for minified horizontal floor
materials. Its footprint is clamped inside each 16-pixel metatile at BOTH mip
levels, capped at level four. This avoids blending neighboring atlas cells.
All derivatives and filtered reads precede discard. Shader language pragmas
are hoisted ahead of compiler defines; sources without pragmas retain their bytes.

Explicit LOD and manual mipmaps are probed before registering shader slots.
Unsupported systems retain native sampling and report unavailable. Recomposition
uses a per-row AtlasComposite version, including legacy unversioned animation
updates. Static atlas frames never regenerate mips. A four-atlas, 32 MiB LRU
bounds resources. Release rebuilds lazily; disable removes hooks, shader bytes,
config, cache exclusions and owned GPU objects. Native texture filters and
geometry payloads are untouched.

GPU probes verify exact near/sprite bytes, isolated tile edges, revision reuse,
and release/rebuild. Native scene, battle, physical-removal and timing coverage
is recorded with the RC evidence. GPU timing remains unavailable; measured
CPU generation occasionally exceeds 0.1 ms, so that acceptance target remains
open. CPU submission timing is not evidence of the GPU execution budget.
