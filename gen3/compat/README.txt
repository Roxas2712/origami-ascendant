Public engine rendering compatibility

Based on the Pokemon Gen 1 Recompilation Project by BOIS CLUB GAMES, LLC (https://github.com/bryanthaboi/gen1recomp)

BattleRender0361.lua derives rendering helpers from public gen1recomp 0.3.61.
Its license is ENGINE-LICENSE.MD (GPLv3 with the upstream additional terms).
The source notice records the exact input SHA256. Reproduce it with
  python3 tools/build_public_battle_bridge.py PATH/TO/src/core/game3/battle/ui.lua
using the luaparser Python package. No launcher files or ROM assets are included.

OASC adds presentation callbacks for map battles. Battle rules, command input,
state initialization, update timing, and saves remain owned by the native Ui.
Outside an OASC presentation the original draw function is called. Unloading
restores the original functions; unsupported engine versions fail closed to
native battles. Engines exposing the existing API v2 need no compatibility seam.
