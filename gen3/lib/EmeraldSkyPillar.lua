-- Native Himmelsnadel geometry and high-altitude atmosphere. No gameplay writes.
local V=...
local S={}
local C=V.require('DioramaConfig').skyPillar
local ids={EM_SKY_PILLAR_OUTSIDE=true,EM_SKY_PILLAR_ENTRANCE=true,EM_SKY_PILLAR_1F=true,EM_SKY_PILLAR_2F=true,EM_SKY_PILLAR_3F=true,EM_SKY_PILLAR_4F=true,EM_SKY_PILLAR_5F=true,EM_SKY_PILLAR_TOP=true}
function S.kind(d)return d and ids[d.id or d.name]==true end
function S.summit(d)return d and(d.id or d.name)=='EM_SKY_PILLAR_TOP'end
function S.profile(d)
 if not S.kind(d)or not d.midLayout or not V.require('DioramaConfig').billboards.enabled then return end
 if S.summit(d)and(d.midLayout.width~=28 or d.midLayout.height~=24 or d.midLayout:midAt(16,14)~=0x24c)then return end
 return true
end
function S.ground(d,x,z)
 if S.summit(d)then
  if z>=240 then return -C.terraceDrop end
  if x>=160 and x<224 and z>=208 then return -C.terraceDrop*math.min(1,(z-208)/32)end
 end
 return 0
end
-- The tower is a continuous native facade, lifted from its five-column ROM footprint.
function S.exteriorMask(d,mask)
 if not S.profile(d)or d.id~='EM_SKY_PILLAR_OUTSIDE'then return end
 for y=0,5 do for x=12,16 do mask[y*d.midLayout.width+x+1]={mid=0x124}end end
end
function S.doorPose(d,anim)
 if not S.profile(d)or not anim then return end
 if d.id=='EM_SKY_PILLAR_OUTSIDE'and anim.x==14 and anim.y==5 then return{height=32,base=0,top=0}end
 if S.summit(d)and anim.x==16 and anim.y==14 then return{height=C.wallHeight,base=-C.terraceDrop,top=0}end
 if (d.id or''):match('^EM_SKY_PILLAR_%dF$')and anim.y==1 then return{height=C.wallHeight,base=0,top=0}end
end
function S.exteriorBuild(out,d,ts,ox,oz)
 if not S.profile(d)or d.id~='EM_SKY_PILLAR_OUTSIDE'then return end
 local G=V.require('WorldGeometry');local xx,zz=(ox or 0)*16,(oz or 0)*16
 local vv=V.require('PaperSprite').build(ts,80,96,function(s,t)return d.midLayout:midAt(12+math.floor(s/16),math.floor(t/16)),s%16,t%16 end,function()return true end,0,96,1,nil,
  function(s,t)return{xx+192+s,(96-t)*C.exteriorHeight/96,zz+96}end,.5)
 for _,v in ipairs(vv)do out[#out+1]=v end
 -- Stone returns join the upright face to the back of the original footprint.
 for _,x in ipairs({192,272})do
  G.quad(out,{xx+x,C.exteriorHeight,zz},{xx+x,C.exteriorHeight,zz+96},{xx+x,0,zz+96},{xx+x,0,zz},G.uv(ts,0x2a2),.78)
 end
 G.quad(out,{xx+192,C.exteriorHeight,zz},{xx+272,C.exteriorHeight,zz},{xx+272,C.exteriorHeight,zz+96},{xx+192,C.exteriorHeight,zz+96},G.uv(ts,0x2a2))
end
function S.actorHeight(d,x,z)if S.profile(d)then return S.ground(d,x+8,z+16)end end
-- ROM sky and the enormous painted front masonry are background, not floor.
function S.floorCell(d,x,y)
 local L=d.midLayout
 return x>=0 and x<L.width and y>=0 and y<L.height and(not S.summit(d)or y>=3 and y<18)
end
function S.build(d,ts,ox,oz)
 if not S.profile(d)or d.id=='EM_SKY_PILLAR_OUTSIDE'or d.id=='EM_SKY_PILLAR_ENTRANCE'then return end
 local G=V.require('WorldGeometry');local L=d.midLayout;local out,contacts={},{}
 local xx,zz=(ox or 0)*16,(oz or 0)*16;local summit=S.summit(d)
 local pixel=V.require('BuildingMesh').pixel
 local floorColors={}
 local function color(r,g,b)return math.floor(r*255+.5)*65536+math.floor(g*255+.5)*256+math.floor(b*255+.5)end
 for py=0,15 do for px=0,15 do floorColors[color(pixel(ts,0x234,px,py))]=true end end
 local function tile(mid,x,y,h,shade)
  G.quad(out,{xx+x,h,zz+y},{xx+x+16,h,zz+y},{xx+x+16,h,zz+y+16},{xx+x,h,zz+y+16},G.uv(ts,mid),shade)
 end
 local function art(x,y,w,h,inside,transform)
  local vv=V.require('PaperSprite').build(ts,w,h,function(s,t)return L:midAt(x+math.floor(s/16),y+math.floor(t/16)),s%16,t%16 end,inside or function()return true end,0,h,1,nil,
   function(s,t)local p=transform(s,t);return{p[1]+xx,p[2],p[3]+zz}end,.5)
  for _,v in ipairs(vv)do out[#out+1]=v end
 end
 for y=0,L.height-1 do for x=0,L.width-1 do
  local m=L:midAt(x,y);local h=S.ground(d,x*16+8,y*16+8)
  if S.floorCell(d,x,y)then
   if m==0x227 and L:midAt(x,y+1)==0x22f or m==0x26d and L:midAt(x,y+1)==0x26a or m==0x26e and L:midAt(x,y+1)==0x26b or m==0x23b and L:midAt(x,y+1)==0x243 or m==0x23c and L:midAt(x,y+1)==0x24c or m==0x23d and L:midAt(x,y+1)==0x245 then
    local base=summit and -C.terraceDrop or 0
    -- A thin stone cap, then the original wall/door pixels standing vertically.
    art(x,y,16,32,nil,function(s,t)
     if t<5 then return{x*16+s,base+C.wallHeight,y*16+t*32/5}end
     return{x*16+s,base+C.wallHeight*(32-t)/27,y*16+32}
    end)
   elseif y>0 and (L:midAt(x,y-1)==0x227 or L:midAt(x,y-1)==0x23b or L:midAt(x,y-1)==0x23c or L:midAt(x,y-1)==0x23d or L:midAt(x,y-1)==0x26d or L:midAt(x,y-1)==0x26e)and(m==0x22f or m==0x243 or m==0x24c or m==0x245 or m==0x26a or m==0x26b)then
    -- Owned by the upright wall above.
   elseif summit and(m==0x29d or m==0x29e)then
    -- Native stair texture is divided into real horizontal treads and risers.
    for j=0,3 do local sy=j*4;local height=S.ground(d,x*16+8,y*16+sy+2)
     G.quad(out,{x*16+xx,height,y*16+zz+sy},{x*16+xx+16,height,y*16+zz+sy},{x*16+xx+16,height,y*16+zz+sy+4},{x*16+xx,height,y*16+zz+sy+4},G.uv(ts,m,0,sy,16,sy+4))
     G.quad(out,{x*16+xx,height,y*16+zz+sy+4},{x*16+xx+16,height,y*16+zz+sy+4},{x*16+xx+16,height-C.terraceDrop/8,y*16+zz+sy+4},{x*16+xx,height-C.terraceDrop/8,y*16+zz+sy+4},G.uv(ts,m,0,sy+3,16,sy+4),.85)
    end
   elseif m==0x20f or m==0x207 then
    tile(0x234,x*16,y*16,h)
    local two=m==0x207 and L:midAt(x,y+1)==0x20f
    if not(y>0 and L:midAt(x,y-1)==0x207 and m==0x20f)then
     local last=two and 32 or 16;local base=S.ground(d,x*16+8,(y+1)*16)
     art(x,y,16,last,function(s,t,mid,u,v)local r,g,b=pixel(ts,mid,u,v);return not floorColors[color(r,g,b)] end,
      function(s,t)return{x*16+s,base+(last-t)*(two and C.largeRubbleScale or C.smallRubbleScale),y*16+last-2}end)
     contacts[#contacts+1]={xx+x*16+8,zz+y*16+last-2,7,3,.35}
    end
   elseif summit and m==0x264 then tile(0x234,x*16,y*16,0)
   elseif summit and m==0x2ad then
    tile(0x234,x*16,y*16,0)
    art(x,y,16,16,nil,function(s,t)return{x*16+s,13*(16-t)/16,y*16+14}end)
   else tile(m,x*16,y*16,h)end
  end
 end end
 if summit then
  -- The drop is a hanging stone body, never an extra walkable plane.
  for y=3,17 do
   local h=S.ground(d,0,y*16+8)
   for _,x in ipairs({0,L.width*16})do
    G.quad(out,{x+xx,h,y*16+zz},{x+xx,h,(y+1)*16+zz},{x+xx,-C.skirtDepth,(y+1)*16+zz},{x+xx,-C.skirtDepth,y*16+zz},G.uv(ts,0x2a2),G.HANGING_FACADE)
   end
  end
  for x=0,L.width-1 do
   G.quad(out,{x*16+xx,-C.terraceDrop,288+zz},{(x+1)*16+xx,-C.terraceDrop,288+zz},{(x+1)*16+xx,-C.skirtDepth,288+zz},{x*16+xx,-C.skirtDepth,288+zz},G.uv(ts,0x2a2),G.HANGING_FACADE)
  end
 end
 return out,{contacts=contacts,lights={},buildings=0,trees=0,cells=L.width*L.height,vertices=#out,terrainCells=0,skyPillar=true}
end
function S.light(d,result)
 if not S.profile(d)then return end
 if S.summit(d)then
  result.cave=false;result.flash=false
 else
  if d.id=='EM_SKY_PILLAR_OUTSIDE'or d.id=='EM_SKY_PILLAR_ENTRANCE'then return end
  local night=V.require('DayNight').windowLight()
  result.cave=false;result.flash=false;result.ambient={.39-.18*night,.42-.18*night,.50-.16*night};result.sun=.08*(1-night)
  result.lights={};result.sprites={};result.shafts={}
  -- Light enters the actual stair opening; no invented lamps in these ruins.
  for _,w in ipairs(d.warps or{})do if w.y==1 then
   result.lights[#result.lights+1]={x=w.x*16+8,y=30,z=34,radius=-100,power=.48,color={.65,.80,1}}
   result.shafts[#result.shafts+1]={x=w.x*16+8,z=36,width=17,height=110,alpha=.075,fade=1,slant=.25,spread=1.3,color={.67,.82,1}}
  end end
 end
end
local backdrop=[[
uniform float clock;
uniform float night;
uniform vec2 viewSize;
float noise(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
float smoothNoise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(noise(i),noise(i+vec2(1,0)),f.x),mix(noise(i+vec2(0,1)),noise(i+1.),f.x),f.y);}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 xy){
 vec2 p=xy/viewSize;
 vec3 top=mix(vec3(.17,.35,.57),vec3(.025,.045,.10),night);
 vec3 horizon=mix(vec3(.58,.72,.81),vec3(.12,.16,.25),night);
 vec3 sky=mix(top,horizon,smoothstep(0.,.9,p.y));
 vec2 wind=vec2(clock*.012,clock*.004);
 float a=smoothNoise(p*vec2(5.,3.)+wind);
 float b=smoothNoise(p*vec2(12.,8.)+wind*1.4);
 float cloud=smoothstep(.30,.65,a*.72+b*.28);
 float rim=smoothstep(.40,.65,a*.72+b*.28);
 cloud*=smoothstep(.16,.7,p.y);
 sky=mix(sky,mix(mix(vec3(.61,.73,.83),vec3(.88,.91,.94),rim),vec3(.23,.29,.40),night),cloud*.85);
 return vec4(sky,1.);
}]]
function S.drawBackdrop(d,w,h,time)
 if not S.summit(d)then return end
 S.shader=S.shader or V.require('ShaderCompiler').newShader(backdrop)
 love.graphics.push('all');love.graphics.setShader(S.shader);love.graphics.setDepthMode();love.graphics.setColor(1,1,1,1)
 S.shader:send('clock',time);S.shader:send('night',V.require('DayNight').windowLight());S.shader:send('viewSize',{w,h});love.graphics.rectangle('fill',0,0,w,h);love.graphics.pop()
end
return S
