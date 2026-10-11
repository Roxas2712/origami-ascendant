# RC camera policy

First- and third-person field cameras are disabled for this release candidate.
F3/V, F7 and the mod manager offer only the normal diorama camera with field
angles 24, 36 and 50 degrees. Map battles keep their independent angle setting.
Old gen3FieldCamera preferences migrate to NORMAL on settings application;
no free-camera mouse/touch/gamepad hooks or free-walk controller are installed.
Experimental geometry/sky helpers are dormant and do not run in this candidate.

Cold map/angle preparation retains an OASC paper frame under a visible folding
handoff instead of flashing the native view. Simulation continues; a cold
build still takes time. Three geometry views are retained for the three angles.
Regional snowfall and melting are caught up lazily on map entry, including
unvisited maps, time spent indoors and save/reload history. No per-frame loop
or native simulation of all maps is introduced.
