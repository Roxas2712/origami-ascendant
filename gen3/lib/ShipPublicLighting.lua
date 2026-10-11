-- Measured S.S. Anne public rooms: native portholes and fixed task lighting.
local V=...;local S={cache=setmetatable({},{__mode='k'})}
local function stamp(t)
 local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys)
 local out={};for _,k in ipairs(keys)do local v=t[k];out[#out+1]=k..'='..(type(v)=='table'and stamp(v)or tostring(v))end
 return table.concat(out,';')
end
function S.profile(d)
 if not(d and d.mapType==8 and d.midLayout)then return end
 local c=V.require('DioramaConfig').interiors.shipLighting
 local room=c.rooms[d.id or d.name];if not(c.enabled and room)then return end
 if not(V.require('InteriorShipPublic').profile(d)or V.require('InteriorShipCorridors').profile(d))then return end
 local L=d.midLayout
 for _,at in ipairs(room.windows)do if L:midAt(at[1],at[2])~=0x282 then return end end
 local signature=(d.id or d.name)..stamp(c);local hit=S.cache[L]
 if hit and hit.signature==signature then return hit.profile end
 local sources,regions={},{}
 for _,kind in ipairs({'desk','work','ceiling'})do for _,at in ipairs(room[kind]or{})do
  local r=c[kind]
  sources[#sources+1]={at={at[1]*16,r.height,at[2]*16},radius=r.radius,power=r.power,nightPower=r.nightPower,color=kind=='work'and c.workColor or c.ceilingColor,spread=r.spread}
 end end
 for _,at in ipairs(room.windows)do
  local r=c.window
  sources[#sources+1]={at={at[1]*16+8,r.height,at[2]*16+r.forward},radius=r.radius,power=r.power,nightPower=r.nightPower,color=c.windowColor,spread=r.spread,direction={0,-.25,1},cone=r.cone}
  regions[#regions+1]={at=at,rect={6,6,4,4},palette=c.glassPalette}
 end
 local p={ambient=c.ambient,night=c.nightAmbient,sources=sources,localSelection=true}
 if #regions>0 then p.emission={enabled=true,day=c.emissionDay,night=c.emissionNight,bloom=c.emissionBloom,regions=regions}end
 S.cache[L]={signature=signature,profile=p};return p
end
function S.capture(list,o,x,z)
 if not(o.kind:match('^shipPublic')or o.kind:match('^shipCorridor'))then return false end
 if o.kind:find('Wall',1,true)or o.kind=='shipPublicCabinet'then return false end
 if o.kind=='shipPublicTable'or o.kind=='shipPublicBench'then
  local c=V.require('DioramaConfig').interiors
  -- The top casts a shadow; open legs/undersides never become solid boxes.
  list[#list+1]={lo={x+1,(o.height-c.shipLighting.slabThickness)*c.heightScale,z+o.front-o.depth},hi={x+o.w*16-1,o.height*c.heightScale,z+o.front},wall=false}
 end
 -- Floors, stair apertures, thin rails, chairs and small round bins retain
 -- their native silhouettes/contact shading, not an enclosing shadow cube.
 return true
end
return S
