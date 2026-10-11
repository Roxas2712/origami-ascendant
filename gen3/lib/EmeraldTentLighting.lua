-- Fixed area sources for the three native battle-tent room families.
local V=...;local T={}
function T.profile(d)
 if not(d and d.mapType==8)then return end
 local c=V.require('DioramaConfig').emeraldInteriors.tentLighting
 if not c.enabled then return end
 local p=V.require('EmeraldBattleTents').profile(d);if not p then return end
 return c[p.lobby and 'lobby'or p.corridor and 'corridor'or p.garden and 'garden'or 'battle']
end
function T.capture(list,o,x,z)
 if not o.kind:match('^tent')then return false end
 local all=V.require('DioramaConfig').emeraldInteriors;local c=all.battleTents
 local function box(a,b,u,v,low,high)
  list[#list+1]={lo={x+a,low*all.heightScale,z+u},hi={x+b,high*all.heightScale,z+v},wall=false}
 end
 if o.kind=='tentCounter'then
  -- Inner opaque cores follow the curved U. Keep its central floor and the
  -- attendant passage completely open, rather than bounding the whole sprite.
  for _,b in ipairs({{1,31,15,26},{113,143,15,26},{1,15,26,60},{129,143,26,60},
   {16,62,61,75},{82,128,61,75},{8,16,61,72},{128,136,61,72}})do
   box(b[1],b[2],b[3],b[4],0,c.counterHeight)
  end
 elseif o.kind=='tentPC'then
  box(2,14,40-c.terminalDepth,40,0,c.terminalHeight)
 elseif o.kind=='tentSign'then
  local half=all.tentLighting.blockerThickness/2
  box(10,38,24-half,24+half,c.signHeight*6/24,c.signHeight*21/24)
 end
 -- Fabric and plants keep the existing alpha-masked contours/contacts.
 return true
end
return T
