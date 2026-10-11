-- Counter footprints, in native source pixels. Open rings/returns must not
-- become one solid shadow box including their signs and demo terminals.
local V=...;local M={}
function M.capture(list,o,x,z)
 local k=o.kind
 if not(x and z)or not(k=='deptRing'or k=='deptSalesCounter'or k=='storeReception'or k=='storeIsland')then return false end
 local c=V.require('DioramaConfig');local em=k=='storeReception'or k=='storeIsland'
 local cfg=em and c.emeraldInteriors or c.interiors
 local h=(em and cfg.department.counterHeight or cfg.departmentSurfaces.counterHeight)*cfg.heightScale
 local depth=c.roomLightRig.departmentDeviceDepth
 local function box(a,b,d,e,low,high)
  list[#list+1]={lo={x+a,low or 0,z+d},hi={x+b,high or h,z+e},wall=false}
 end
 local function device(a,b,d,height)box(a,b,d-depth/2,d+depth/2,h,h+height*cfg.heightScale)end
 if k=='deptRing'then
  box(0,112,11,24);box(0,16,24,59);box(96,112,24,59);box(0,112,59,72)
  device(96,112,69,18)
 elseif k=='deptSalesCounter'then
  local w,last=o.w*16,o.last
  if o.shape=='bar'then box(0,w,12,24)
  elseif o.shape=='leftL'then box(32,w,12,last-8);box(0,32,last-20,last-8)
  elseif o.shape=='rightL'then box(0,w,12,24);box(w-16,w,24,last-8)
  else box(0,w,12,24);box(0,16,24,last-20);box(w-16,w,24,last-20);box(0,w,last-20,last-8)end
  if o.devices then for _,dx in ipairs({16,64})do device(dx,dx+32,24.1,cfg.departmentSurfaces.deviceHeight)end
  elseif o.shape=='leftL'then device(32,48,45,28)end
 elseif k=='storeReception'then
  box(0,16,o.front-30,o.front-10);box(o.w-16,o.w,o.front-30,o.front-10);box(0,o.w,o.front-10,o.front)
  device(2,16,o.front-12,cfg.department.terminalHeight)
  device(o.w-16,o.w,o.front-23,cfg.department.infoHeight)
 else
  local back=o.front-42;local stop=o.noRight and o.w or o.w-16
  box(16,stop,back,back+10);box(0,16,back,o.front)
  if not o.noRight then box(o.w-16,o.w,back,o.front)end
  if o.device then device(2,16,o.front-12,cfg.department.terminalHeight)end
 end
 return true
end
return M
