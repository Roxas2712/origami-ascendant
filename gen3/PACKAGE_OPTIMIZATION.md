# Optimized release payloads

Source artwork stays unchanged in Git. `tools/terrarium_asset_inventory.lua`
resolves Kanto/Hoenn registries, layouts, finishing cards and default artwork.
`tools/optimize_terrarium_assets.py` adds literal references from retained fallback
modules, then writes release colors and alpha masks to an external output folder.
`tools/build_release.py --runtime-art <folder>` packages these files instead of
all original atlases. Author/provenance metadata remains included.

Colors use JPEG quality 90 without chroma subsampling. Dimensions stay unchanged.
Visible edge RGB is extended four pixels into alpha-zero pixels before compression;
the original alpha bytes are retained exactly. This reduces dark filtered edges.
Alpha is lossless PNG; `PaperArtAssets` reconstructs each RGBA image once during
stage construction, with a fast LuaJIT byte-copy path and a portable fallback.
Source checkouts read original images. Color compression is lossy and must pass
comparison against the same catalog frames. GPU textures and effects are retained.

`tools/optimize_geometry_cache.py` converts a frozen OGC3/OGC4 cache into OGC5.
Its byte-plane transform preserves every vertex float bit. Common pieces of at
most 64 KiB are stored once in `chunks.bank`, with a data-only index and SHA-256
checks for every decoded piece. All geometry keys, offsets, metadata and scene
mappings stay intact. Geometry sources in `index.data` must then be hashed against
the staged release code. Format conversion does not authorize rebinding a stale
cache after geometry changes.

Both worker and main-thread fallback seek within the bank. Their authenticated
chunk LRU retains at most 4 MiB on desktop and 512 KiB on mobile; overflow evicts
the least recently used chunks instead of clearing the entire cache.
Expanded records count toward the existing 32 MiB prefetch budget. Main-thread
fallback opens the mod-owned bank path and closes each ranged read. Length/address checks and
source/native fingerprint checks remain active. Live caches use self-contained
OGC4; OGC2/OGC3 stay readable. Missing/corrupt banks fall back to normal meshing.

Verification covers exact float/metadata round trips, malformed/truncated payloads
and banks, cooperative yields, portable/LuaJIT paths, native worker cache hits,
catalog render comparisons, native battles and live view switching.


The frozen cache has 4046 keys: 4000 `FR_` and 46 `SEVII_`. It does not contain
Emerald scenes. FireRed/LeafGreen lookup includes the edition in each key, so a
record baked for one edition is not assumed to cover the other. Unsupported or
missing keys use live meshing and the loading companion. `GeometryCache.health()`
exposes hit/miss counts and the coverage description. Do not describe this as a
complete three-edition field cache. Terrarium artwork is a separate catalog and
is included for all three editions.

RC114 ships 205 logical authored images, including the three retained Kanto
fallback atlases. Release gates check all library/data image literals against
packaged paths or runtime aliases. The sole virtual filename `hoenn-badges.png`
labels ROM-extracted FileData and is not bundled artwork. Backup/reject files
are excluded. GPU stage resources use a three-stage LRU. Performance-log disk
writes require the explicit option; in-memory timing remains available.
