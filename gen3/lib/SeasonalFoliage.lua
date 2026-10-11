-- Colour only: follows the existing saved weather clock; no gameplay season.
local V=...
local F={}
-- CUT trees use the native actor renderer. Keep its lighting/orientation while
-- identifying foliage separately from trainers, Pokemon and other objects.
-- Pattern Bush's two native leafy gates use the folded facade mesh. Their
-- leaves are stationary foliage, not house paint; keep the original geometry.
function F.canopyBuilding(b,L)
 if b.mapId~='FR_SIX_ISLAND_GREEN_PATH' or (b.renderPair or b.pair)~='general__rom_082d507c'
  or b.x1-b.x0~=3 or b.y1-b.y0~=2 then return false end
 local west=L:midAt(b.x0,b.y1)==0x310
 local rows={{0x300,0x301,0x302,0x303},{0x308,0x309,0x30a,0x30b},
  {west and 0x310 or 0x304,0x311,0x312,west and 0x305 or 0x313}}
 for y,row in ipairs(rows)do for x,mid in ipairs(row)do
  if L:midAt(b.x0+x-1,b.y0+y-1)~=mid then return false end
 end end
 return true
end
function F.actorShade(gid,emerald)
 return not emerald and gid==95 and 1.76 or 1.75
end
local legacy={SEVII_ONE_ISLAND=true,SEVII_ONE_ISLAND_KINDLE_ROAD=true,SEVII_ONE_ISLAND_TREASURE_BEACH=true}
F.setting=V.require('ModSetting').new('gen3FoliageSeason','JAHRESZEITEN',
 {'auto','spring','summer','autumn','original'},
 {'AUTO','FRUEHLING','SOMMER','HERBST','ORIGINAL'},'auto')
local function smooth(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function F.weights(mode,clock,seasonSeconds)
 if mode=='original'or mode=='summer'then return 0,0 end
 if mode=='spring'then return 1,0 end
 if mode=='autumn'then return 0,1 end
 local phase=(clock or 0)/(seasonSeconds or 960)
 local slot=math.floor(phase)%4;local t=smooth((phase%1)/.1)
 -- Each season begins with a gentle transition from the preceding one.
 local currentSpring=slot==0 and 1 or 0;local previousSpring=slot==1 and 1 or 0
 local currentFall=slot==2 and 1 or 0;local previousFall=slot==3 and 1 or 0
 return previousSpring+(currentSpring-previousSpring)*t,previousFall+(currentFall-previousFall)*t
end
function F.bind(shader,def,outdoors,snow)
 local mode=F.setting:get();local spring,fall=0,0;local cover=0
 if outdoors and def and(tostring(def.id or def.name):match('^FR_')or tostring(def.id or def.name):match('^EM_')or legacy[def.id or def.name])and mode~='original'then
  local W=V.require('Weather');spring,fall=F.weights(mode,W.clock,W.SEASON_SECONDS);cover=snow or 0
 end
 shader:send('foliageSeason',{spring,fall,cover})
 shader:send('foliageMapOrigin',{0,0})
 shader:send('foliageWarm',0)
end
function F.origin(shader,cached)
 shader:send('foliageMapOrigin',cached and cached.foliageOrigin or {0,0})
 shader:send('foliageWarm',cached and cached.atlas and V.require('TilesetSemantics').atlasPair(cached.atlas)=='general__rom_082d5004'and 1 or 0)
end
F.uniforms=[[
uniform vec3 foliageSeason;
uniform vec2 foliageMapOrigin;
uniform float foliageWarm;
varying vec2 foliageRoot;
varying float stationaryFoliage;
varying float cutTreeFoliage;
]]
F.fragment=[[
  if(max(max(plantFace,stationaryFoliage),cutTreeFoliage)>.5 && (actorFace<.5 || cutTreeFoliage>.5) && dot(foliageSeason,vec3(1.0))>0.0){
    float leaf=smoothstep(.015,.09,pixel.g-max(pixel.r,pixel.b));
    // Berry Forest has olive/yellow native leaves. Use its actual canopy
    // palette boundary; ordinary green-only selection missed the whole crown.
    float warmLeaf=smoothstep(.0,.035,pixel.g-pixel.r*.82)
      *smoothstep(.0,.04,pixel.g*.72-pixel.b)*smoothstep(.0,.035,pixel.r-pixel.g*.70);
    leaf=max(leaf,warmLeaf*foliageWarm*plantFace);
    if(leaf>0.0){
      float detail=dot(pixel.rgb,vec3(.2126,.7152,.0722));
      if(plantFace>.5 && grassFace<.5 && foliageSeason.x+foliageSeason.y>0.0){
        vec2 root=floor(foliageRoot/8.0+.5);
        float seed=fract(sin(dot(root,vec2(127.1,311.7)))*43758.5453);
        float spring=foliageSeason.x*(1.0-step(.22,seed));
        float fall=foliageSeason.y*step(.30,seed)*(1.0-step(.78,seed));
        vec3 blossom=mix(vec3(.92,.49,.63),vec3(1.0,.74,.81),seed/.22)*(.40+detail*.95);
        vec3 autumn=mix(vec3(.64,.34,.15),vec3(.91,.56,.23),fract(seed*17.0))*(.42+detail*.94);
        pixel.rgb=mix(pixel.rgb,blossom,leaf*spring*.88);
        pixel.rgb=mix(pixel.rgb,autumn,leaf*fall*.94);
      }
      // Snow collects on the bright upper edges of the native leaves. Their
      // darker recesses remain legible, rather than painting a flat white card.
      float deposit=(.38+.62*smoothstep(.16,.65,detail))*clamp(foliageSeason.z*1.3,0.0,1.0);
      vec3 snowLeaf=vec3(.86,.91,.97)*(.55+.45*detail);
      pixel.rgb=mix(pixel.rgb,snowLeaf,leaf*deposit);
    }
  }
]]
return F
