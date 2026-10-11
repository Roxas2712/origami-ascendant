-- GLSL derivatives need live helper lanes. Clipping the water mirror before
-- computing a surface normal leaves edge pixels undefined even at fixed time.
-- Normalize at compilation so exported rc.4 shader builders stay byte-identical.
local D={}
local numericTypes={float=true,number=true,int=true,vec2=true,vec3=true,vec4=true,
 ivec2=true,ivec3=true,ivec4=true,mat2=true,mat3=true,mat4=true}
-- LÖVE defaults to highp in the vertex stage and mediump in the pixel
-- stage on GLES. Shared interfaces must have identical precision. Keep
-- local fragment arithmetic and explicitly qualified declarations intact.
local function interfaces(source)
 for _,storage in ipairs{'uniform','extern','varying'}do
  source=source:gsub('(%f[%w_]'..storage..'%s+)([%w_]+)(%s+)',function(head,kind,space)
   if numericTypes[kind]then return head..'LOVE_HIGHP_OR_MEDIUMP '..kind..space end
   return head..kind..space
  end)
 end
 return source
end
-- LÖVE recognizes its language pragma only before compiler feature defines.
-- GLSL ES reserves "patch" even without tessellation support. Rename the
-- legacy snow local only in compiler input, preserving exported rc.4 bytes.
-- OASC matrices use the legacy canvas convention: CPU projection/project()
-- maps NDC y=-1 to the texture top. LOVE 12 standardizes custom positions to
-- y-up, then applies its backend transform. Adapt only our independent clip
-- positions; built-in transform_projection positions and 2D UI stay untouched.
-- Keep the CPU matrices stable for fog, depth UVs, sprite planes and geometry.
function D.canvasCoordinates(source)
 local major=love and love.getVersion and love.getVersion()or 11
 if major<12 then return source end
 return source:gsub('(vec4%s+)position(%s*%(%s*mat4%s+([%w_]+)%s*,%s*vec4%s+([%w_]+)%s*%)%s*)(%b{})',function(head,args,matrix,vertex,body)
  -- A position using LOVE's supplied matrix is already in its convention.
  -- This also makes the adapter idempotent: our wrapper uses both arguments.
  if body:find('%f[%w_]'..matrix..'%f[^%w_]')then return head..'position'..args..body end
  return head..'oascCanvasPosition'..args..body..'\nvec4 position'..args..
   '{vec4 clip=oascCanvasPosition('..matrix..','..vertex..');clip.y=-clip.y;return clip;}'
 end)
end
function D.language(source)
 source=D.canvasCoordinates(source)
 source=interfaces(source)
 if source:find('float%s+patch[%s=;]')then
  source=source:gsub('%f[%w_]patch%f[^%w_]','oascSnowPatch')
 end
 local language=source:match('#pragma[ \t]+language[ \t]+([%w_]+)')
 if not language then return source end
 source=source:gsub('[ \t]*#pragma[ \t]+language[ \t]+([%w_]+)[ \t]*\n',function(other)
  assert(other==language,'conflicting shader languages');return ''
 end)
 return '#pragma language '..language..'\n'..source
end
-- Match the stable fragment parameters, independent of a consumer's entry name.
-- Wrapper functions keep derivatives inside the scene function, before discard.
function D.prefixEntry(source,prefix)
 return source:gsub('(vec4%s+[%w_]+%s*%(%s*vec4%s+color%s*,%s*Image%s+tex%s*,%s*vec2%s+uv%s*,%s*vec2%s+screen%s*%)%s*{)',function(entry)return entry..prefix end)
end
function D.prepare(source)
 local count
 source,count=source:gsub('vec3 normal=normalize%(cross%(dFdx%(worldPosition%),dFdy%(worldPosition%)%)%);',
  'vec3 normal=oascBaseWorldNormal;')
 if count==0 then return D.language(source) end
 local prefix='\n vec3 oascBaseWorldNormal=normalize(cross(dFdx(worldPosition),dFdy(worldPosition)));\n'
 source=D.prefixEntry(source,prefix)
 return D.language(source)
end
return D
