-- Ever Grande's two independently anchored blooms keep the native animated
-- atlas. A shared fragment cutout removes lawn/stone in every frame, including
-- the directional-shadow pass; a static silhouette would clip moving petals.
local V=...
local F={}
F.shader=[[
varying float nativeFlowerFace;
bool nativeFlowerBackground(vec3 c){
 vec3 p=floor(c*255.0+0.5);
 return distance(p,vec3(115,197,165))<1.0 || distance(p,vec3(165,214,197))<1.0
  || distance(p,vec3(66,181,132))<1.0 || distance(p,vec3(66,74,107))<1.0
  || distance(p,vec3(165,173,123))<1.0 || distance(p,vec3(197,197,165))<1.0
  || distance(p,vec3(222,222,197))<1.0;
}
]]
F.vertex='nativeFlowerFace=step(5.39,VertexShade)*(1.0-step(5.41,VertexShade));\n'
F.fragment='if(nativeFlowerFace>.5 && nativeFlowerBackground(pixel.rgb))discard;\n'
function F.applies(d,mid)
 return d.id=='EM_EVER_GRANDE_CITY'and d.pair=='general__ever_grande'and mid>=0x288 and mid<=0x2a7
end
function F.back(x,y)return y<7 or y==7 and x>=9 or y==8 and x>=11 end
function F.build(out,d,ts,x,y,ox,oz,contacts)
 local mid=d.midLayout:midAt(x,y);local C=V.require('DioramaConfig')
 if not C.everGrandeFlowers.enabled or not F.applies(d,mid)or not C.billboards.enabled
  or V.require('Camera').projection()~='perspective'then return false end
 local G=V.require('WorldGeometry');local S=V.require('PaperSprite');local xx,zz=(x+ox)*16,(y+oz)*16
 local edge=mid>=0x298
 -- Preserve the native stone border below clipped flower beds. Infill only
 -- the plant footprint using the same tile's clean right edge / native lawn.
 local floor=S.build(ts,16,16,function(sx,sy)
  if not edge or sy<7 then return 1,sx,sy end
  if sy<=8 and sx<11 then return mid,15,sy end
  return mid,sx,sy
 end,function()return true end,0,0,1,nil,function(sx,sy)return{xx+sx,0,zz+sy}end,.5)
 for _,v in ipairs(floor)do out[#out+1]=v end
 local cfg=C.everGrandeFlowers
 for _,back in ipairs({true,false})do
  local base=back and 9 or 16
  local sprite=S.build(ts,16,edge and 9 or 16,function(sx,sy)return mid,sx,sy end,
   function(sx,sy)return F.back(sx,sy)==back end,0,base,cfg.heightScale,function()return 5.4 end,nil,.5)
  -- Border flowers are cropped by the native stone lip; their small visible
  -- front tips remain at that lip instead of inventing a complete new bloom.
  if edge and not back then
   local shift=(16-9)*cfg.heightScale*V.require('Billboard').heightScale()
   local uy,uz=V.require('Billboard').up()
   for _,v in ipairs(sprite)do v[2]=v[2]-shift*uy;v[3]=v[3]-shift*uz end
   base=9
  end
  for _,v in ipairs(sprite)do v[3]=v[3]+base;v[8]=v[8]+base;out[#out+1]=G.place(v,xx,zz)end
 end
 contacts[#contacts+1]={xx+8,zz+(edge and 8 or 14),6,cfg.contactRadius,cfg.contactStrength}
 return true
end
return F
