# Sky Life — oasc.gen3.sky-life

F3: **VOGELZUEGE & HIMMEL** (`gen3Card_skyLife`), default on; low/off presets disable drawing.
Own configuration: `cards.skyLife={enabled=true,birds=true,meteors=true,beacons={}}`.

Three to five four-frame pixel birds fly 60 world pixels above outdoor maps, along the cloud drift direction with a sinusoidal deviation. A map-seeded four-event schedule has intervals of 60–180 saved-game seconds. Entering a map or moving the camera never restarts it. A separate small multiply-blended ground shadow tests existing scene depth. Birds receive ambient light and the same cloud-noise transmission as the world. Storms and deep night suppress bird flights.

Meteors last 0.4 seconds, separated by map-seeded 90–240 second intervals. They require night > 0.8, clear weather, low actual rooftop cloud cover, an active rooftop panorama and readable depth. Only the upper 30% of that panorama is eligible; foreground scene depth blocks the streak. Ordinary overhead maps never get meteors. One small additive triangle pair supplies HDR emission before Finish and a fine core afterward, preserving scene alpha. No full-screen copy or new main-shader sampler is used.

Optional beacons: `beacons[mapId]={{x=worldX,z=worldZ,radius=80,speed=.2,phase=0}}`. At most 16 small rotating ground triangles, night only, depth tested. Default empty: FireRed has no invented lighthouse. All world effects are excluded indoors and in caves.

Enabled presets prepare resources on Card activation, before the first visible frame. Low/off activation allocates nothing. Full renderer release retains lazy recreation; deactivation and partial allocation failures free the complete owned set.

Resources: two shaders, four bounded meshes, one original hand-authored 64×16 pixel atlas. No global RNG, engine hooks, save writes or gameplay state changes. Failed resource creation disables this Card alone. Unsupported readable depth skips meteors. `health()` reports CPU update/draw time; GPU timing is explicitly unavailable.

Removal: delete the one `cards/index.lua` entry and the four files in `impact.files`. Generic Renderer context fields `hasSky` and `cloudLight` remain useful without this Card and do not alter the main shader source. Deactivation removes hooks, own config/presets/cache exclusions and releases every GPU resource.

Validation and native rollback evidence are recorded in the private `output/oasc-sky-life-20261008` review, not claimed by this document alone.
