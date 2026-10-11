-- Opaque section through foreground rock. Original surfaces never deform;
-- CaveSectionMesh closes the cut with a low cap and native rock side faces.
local V=...
local C={}
C.uniforms=[[
uniform vec4 caveCutaway; // player x/z, enabled, rim height
uniform vec4 caveCutawayBounds; // x0,z0,x1,z1
varying float caveRockFace;
]]
C.vertex=[[
 caveRockFace=abs(BillboardAnchor.z+2.0)<.01?1.0:0.0;
]]
C.fragment=[[
 if(caveRockFace>.5 && caveCutaway.z>.5 && worldPosition.y>caveCutaway.w+.001
  && worldPosition.x>=caveCutawayBounds.x && worldPosition.x<=caveCutawayBounds.z
  && worldPosition.z>=caveCutawayBounds.y && worldPosition.z<=caveCutawayBounds.w)discard;
]]
function C.bounds(d,px,pz)
 local cfg=V.require('DioramaConfig').terrain.caveCutaway
 -- The open summit slopes away below the walking surface; no occluding roof.
 if V.require('EmeraldNavelSanctums').profile(d)=='top'then return end
 if not(cfg.enabled and (V.require('EmeraldNavelSanctums').profile(d)or V.require('EmeraldNavelPassages').profile(d)or V.require('EmeraldMagmaHideout').profile(d)or V.require('EmeraldRusturf').profile(d)or V.require('CaveTerrain').applies(d)or V.require('EmeraldSeafloorCurrents').profile(d)or V.require('EmeraldFieryPath').profile(d)or V.require('TanobyChambers').profile(d)or V.require('FireRedTerracedCaves').profile(d)or V.require('TanobyKey').profile(d)or V.require('FireRedDiglettCave').profile(d)or V.require('FireRedLostCave').profile(d)or V.require('FireRedRuinCaves').profile(d))and V.require('Camera').projection()=='perspective')then return end
 local step=cfg.pixelStep;px=math.floor(px/step+.5)*step;pz=math.floor(pz/step+.5)*step
 local floor=V.require("FireRedRuinCaves").profile(d)and V.require("FireRedRuinCaves").floorHeight(d,pz-cfg.behindMargin)or 0
 -- Raised cave landings need a cut above the player's supporting floor.
 -- Cutting every terrace down to world zero exposes black slots beside stairs.
 if V.require('FireRedTerracedCaves').profile(d)then floor=V.require('FireRedTerracedCaves').floorHeight(d,px,pz-.01)end
 if V.require('EmeraldMagmaHideout').active(d)then floor=V.require('EmeraldMagmaHideout').floorHeight(d,px,pz-.01)end
 if V.require('EmeraldCaveTerraces').active(d)then floor=V.require('EmeraldCaveTerraces').floorHeight(d,px,pz-.01)end
 -- Bath rims are deliberately short. Keep them intact while standing in
 -- the pool; the generic foreground slice otherwise bites into the basin.
 local spa=V.require('FireRedEmberSpa')
 if spa.profile(d)and spa.pool(math.floor(px/16),math.floor((pz-.01)/16))then
  local terrain=V.require('DioramaConfig').terrain
  floor=math.max(floor,terrain.frEmberSpa.upperLevel*terrain.frTerracedCaves.platformHeight)
 end
 if V.require('EmeraldNavelPassages').profile(d)then floor=V.require('EmeraldNavelPassages').floorHeight(d,pz-cfg.behindMargin)end
 if V.require('EmeraldNavelSanctums').profile(d)then floor=V.require('EmeraldNavelSanctums').floorHeight(d,pz-cfg.behindMargin,px)end
 local halfWidth,frontDistance=cfg.halfWidth,cfg.frontDistance
 if V.require('EmeraldNavelSanctums').profile(d)=='bottom'then local c=V.require('DioramaConfig').terrain.emNavelSanctums.bottom;halfWidth,frontDistance=c.cutHalfWidth,c.cutFrontDistance end
 if V.require('EmeraldNavelPassages').profile(d)then
  local c=V.require('DioramaConfig').terrain.emNavelPassages;halfWidth,frontDistance=c.cutHalfWidth,c.cutFrontDistance
  if d.midLayout.width==c.smallRoomWidth then return{c.smallCutSideMargin*16,c.smallCutStartRow*16,(d.midLayout.width-c.smallCutSideMargin)*16,(d.midLayout.height+c.smallCutFrontRows)*16,cfg.height}end
 end
 if V.require('EmeraldSeafloorCurrents').profile(d)then local c=V.require('DioramaConfig').terrain.emSeafloorCurrents;halfWidth,frontDistance=c.cutHalfWidth,c.cutFrontDistance end
 return{px-halfWidth,pz-cfg.behindMargin,px+halfWidth,pz+frontDistance,cfg.height+floor}
end
function C.bind(shader,d,px,pz)
 local bounds=C.bounds(d,px,pz)
 shader:send('caveCutaway',{px,pz,bounds and 1 or 0,bounds and bounds[5]or 0})
 shader:send('caveCutawayBounds',bounds and {bounds[1],bounds[2],bounds[3],bounds[4]}or{0,0,0,0})
 return bounds~=nil
end
return C
