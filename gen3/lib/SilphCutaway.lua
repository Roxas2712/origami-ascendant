-- Local, opaque wall cutaway. Native geometry and collision stay authoritative.
local V=...;local S={rooms=setmetatable({},{__mode='k'})}
local function cfg()return V.require('DioramaConfig').interiors.silphCutaway end
local function smooth(a,b,x)local t=math.max(0,math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)end
function S.register(L,objects,ox,oz)
 local rows={}
 for _,o in ipairs(objects)do if o.kind=='silphWallCourse'then
  local z=(o.y+oz+2)*16;rows[z]=rows[z]or{};rows[z][(o.x+ox)*16]=true
 end end
 local groups={}
 for z,row in pairs(rows)do
  local xs={};for x in pairs(row)do xs[#xs+1]=x end;table.sort(xs)
  local i=1;while xs[i]do local x0,x1=xs[i],xs[i]+16;i=i+1
   while xs[i]==x1 do x1=x1+16;i=i+1 end
   groups[#groups+1]={x0,x1,z}
  end
 end
 table.sort(groups,function(a,b)return a[3]==b[3]and a[1]<b[1]or a[3]<b[3]end)
 S.rooms[L]=groups
end
function S.sections(def,px,pz)
 local c=cfg();local result=V.require("GateDivider").sections(def,px,pz)
 for _,section in ipairs(V.require("InteriorCasino").sections(def,px,pz))do result[#result+1]=section end
 if not def or not c.enabled or not V.require('SilphWallPlants').profile(def)or V.require('Camera').projection()~='perspective'then return result end
 local height=V.require('DioramaConfig').interiors.silphWallPlants.wallHeight*V.require('Billboard').heightScale()
 for _,g in ipairs(S.rooms[def.midLayout]or{})do
  local d=g[3]-pz
  local across=1-smooth(0,c.sideMargin,math.max(g[1]-px,px-g[2],0))
  local amount=across*smooth(-c.behindMargin,0,d)*(1-smooth(c.nearDistance,c.farDistance,d))
  if amount>0 then result[#result+1]={g[1],g[2],g[3],height+(c.height-height)*amount}end
 end
 table.sort(result,function(a,b)return math.abs(a[3]-pz)<math.abs(b[3]-pz)end)
 while #result>8 do table.remove(result)end
 return result
end
S.uniforms=[[uniform int silphCutCount;
uniform vec4 silphCuts[8];
]]
S.vertex=[[
  if(abs(VertexShade-10.0)<.01 || abs(VertexShade-11.0)<.01 || abs(VertexShade-12.0)<.01 || abs(VertexShade-13.0)<.01 || abs(VertexShade-14.0)<.01){
    bool gate=VertexShade>12.5;
    bool cap=abs(VertexShade-11.0)<.01 || abs(VertexShade-12.0)<.01 || abs(VertexShade-14.0)<.01;
    bool floorFace=abs(VertexShade-12.0)<.01;
    bool found=false;
    for(int i=0;i<8;i++){
      if(i>=silphCutCount)break;
      vec4 cut=silphCuts[i];
      if(abs(anchor.y-cut.z)<.1 && anchor.x>=cut.x && anchor.x<=cut.y){
        found=true;
        float h=vertex_position.y;
        float clipped=min(h,cut.w);
        vertex_position.y=floorFace?h:(cap?cut.w:clipped);
        if(!cap && !gate && h>.0001)vertex_position.z=anchor.y+(vertex_position.z-anchor.y)*clipped/h;
      }
    }
    if(cap && !gate && !found)vertex_position.z=anchor.y;
  }
]]
function S.bind(shader,def,px,pz)
 local sections=S.sections(def,px,pz)
 shader:send('silphCutCount',#sections)
 if #sections>0 then shader:send('silphCuts',unpack(sections))end
 return #sections
end
return S
