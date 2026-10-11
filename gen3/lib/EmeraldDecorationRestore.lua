-- Some engine revisions rebuild Secret Base / bedroom furniture on CONTINUE but skip
-- the warp-only decoration sprite script. Restore only missing saved sprites,
-- using the native initializer and its native support-tile/flag rules.
local V=...;local R={}
function R.restore()
 local session=require('src.core.game3.runtime').getSession()
 if not session or session.version~='emerald'then return 0 end
 local SB=require('src.core.game3.rse.secret_base')
 local inBase=SB.curMapIsSecretBase(session)
 if not inBase then
  local gender=session.gender
  local female=gender==1 or gender=='female'or gender=='F'or gender=='girl'
  local ownerRoom='EM_LITTLEROOT_TOWN_'..(female and 'MAYS'or 'BRENDANS')..'_HOUSE_2F'
  if session.map~=ownerRoom then return 0 end
 end
 local Rse=require('src.core.game3.rse.init');local Decor=require('src.core.game3.rse.decoration')
 local Objects=require('src.core.game3.objects')
 local items,positions
 if inBase then
  local base=SB.base(session,Rse.var('VAR_CURRENT_SECRET_BASE',session))
  items,positions=base.decorations,base.decorationPositions
 else
  local room=Decor.context(session,true);items,positions=room.items,room.pos
 end
 local grid=SB.fieldGrid();local missing=false
 for i,id in ipairs(items)do if id>0 and Decor.isSprite(id)then
  local x,y=Decor.decodePos(positions[i]);local behavior=grid.behavior(x,y)
  if Decor.isBeh(behavior,'HOLDS_SMALL_DECORATION')or Decor.isBeh(behavior,'HOLDS_LARGE_DECORATION')then
   local object=Objects.at(x,y);local info=Decor.info(id)
   if not object or object.graphicsId~=info.tiles[1]then missing=true end
  end
 end end
 if not missing then return 0 end -- Newer engines/already-restored rooms are untouched.
 local _,spawned=SB.initDecorationSprites(0,session,grid)
 return spawned and #spawned or 0
end
function R.install()
 V.mod.events:on('save.loaded',function()return R.restore()end)
end
return R
