-- Native LOVE rendition of the approved paper popup, with one rear lid hinge.
-- Art is shared with the reviewed preview; actors/audio come from the ROM.
local V=...
local M=V.require('Mat4')
local Layout=V.data('EmeraldTerrarium')
local Habitats=V.require('battle/terrarium/EmeraldHabitats')
local ArtCoverage=V.require('battle/terrarium/EmeraldArtCoverage')
local PopupActors=V.require('battle/PopupActors')
local Slots=V.require('battle/BattleSlots')
local PopupDialogue=V.require('battle/PopupDialogue')
local AmbientMotion=V.require('battle/terrarium/AmbientMotion')
local CameraMotion=V.require('battle/terrarium/CameraMotion')
local AutoFrame=V.require('battle/terrarium/AutoFrame')
local ResponsiveLayout=V.require('battle/terrarium/ResponsiveLayout')
local DoublesLayout=V.require('battle/terrarium/DoublesLayout')
local PaperPlatform=V.require('battle/terrarium/PaperPlatform')
local PaperDock=V.require('battle/terrarium/PaperDock')
local BattleViewport=V.require('battle/terrarium/BattleViewport')
local idleSound=V.require('battle/terrarium/IdleSound')()
local S={R=102,OPEN=2.05,END=PopupActors.READY,SWITCH_END=5.6}
S.timings={fast={flash=.10,arrival=.30,ready=.90,panel=.34,spread=.07,fold=.45,actor=.50,actorFold=.35},
 balanced={flash=.16,arrival=.55,ready=1.70,panel=.60,spread=.10,fold=.90,actor=.85,actorFold=.60}}
local format={{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexShade','float',1}}
local shaderSource=[[
uniform mat4 vp;uniform mat4 model;uniform float material;uniform float flow;
uniform float battleSpritePass;uniform float battleDepthTest;uniform Image battleDepth;
uniform float popupSpriteFold;
uniform float seaMode;uniform float shadowPass;uniform vec2 shadowOffset;
uniform vec3 eye;uniform float charge;
uniform vec4 stagePlatform;uniform float stageDock;
uniform vec4 paperEffectArea;uniform float paperPulse;uniform Image waterScene;
uniform int lightCount;uniform vec4 lightPosition[4];uniform vec4 lightColor[4];
varying vec3 world;varying vec3 normal;varying float shade;
#ifdef VERTEX
attribute float VertexShade;
float basinHeight(vec2 xz){return -46.0+43.0*pow(length(xz)/100.85,3.0);}
vec4 position(mat4 t,vec4 p){
 world=(model*p).xyz;
 if(shadowPass>.5){
  if(seaMode>.5){
   // Intersect the light ray with the same curved bowl as the seabed mesh.
   // A flat receiver at -43 hid every foreground coral shadow under its rim.
   vec3 source=world;float low=0.0;float high=max(0.0,source.y+46.0);
   for(int i=0;i<10;i++){
    float travel=(low+high)*.5;
    vec2 xz=source.xz+travel*vec2(.48,-.40)+shadowOffset;
    if(source.y-travel>basinHeight(xz))low=travel;else high=travel;
   }
   world.xz=source.xz+(low+high)*.5*vec2(.48,-.40)+shadowOffset;
   // The bowl is tessellated in 12 radial rings: cover its interpolation error.
   world.y=basinHeight(world.xz)+.45;
  }else{
   float floorY=-2.20;
   if(stageDock>.5&&abs(world.x)>=56.0&&abs(world.x)<=90.0&&world.z>=-55.0&&world.z<=65.0&&length(world.xz)<100.0)floorY=-1.25;
   if(stagePlatform.z>0.0&&length(world.xz-stagePlatform.xy)<stagePlatform.z)floorY=stagePlatform.w+.05;
   float height=max(0.0,world.y-floorY);world.xz+=height*vec2(.48,-.40)+shadowOffset;world.y=floorY;
  }
 }
 normal=normalize((model*vec4(normalize(p.xyz),0.0)).xyz);shade=VertexShade;return vp*vec4(world,1.0);
}
#endif
#ifdef PIXEL
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
 vec4 p=Texel(tex,battleSpritePass>.5 && popupSpriteFold<.5?screen/love_ScreenSize.xy:uv);
 if(p.a<.01)discard;
 if(shadowPass>.5){if(length(world.xz)>100.7)discard;return vec4(.12,.10,.08,p.a*color.a);}
 if(battleDepthTest>.5 && gl_FragCoord.z>Texel(battleDepth,screen/love_ScreenSize.xy).r+.0000001)discard;
 vec3 light=vec3(1.0);
 for(int i=0;i<4;i++){if(i<lightCount){float f=max(0.0,1.0-length(world-lightPosition[i].xyz)/lightPosition[i].w);light+=lightColor[i].rgb*lightColor[i].a*f*f*.16;}}
 if(battleSpritePass>.5){p.rgb/=max(p.a,.001);if(seaMode>.5&&world.y< -2.0)p.rgb=mix(p.rgb,p.rgb*vec3(.62,.87,1.0),.42);return vec4(p.rgb*light,p.a)*color;}
 if(material>1.5 && material<2.5){
  vec3 r=reflect(normalize(world-eye),normalize(normal));
  float a=atan(r.x,r.z);float band=pow(max(0.0,cos(a*3.0+.7)),18.0);
  vec3 silver=mix(vec3(.31,.40,.44),vec3(.69,.80,.82),.5+.5*r.y);
  silver+=vec3(.23,.26,.27)*band+vec3(.05,.2,.27)*charge;
  return vec4(silver,1.0)*color;
 }
 if(material>2.5 && material<3.5){
  vec2 xy=uv*vec2(1448.0,1086.0);
  bool falls=(xy.x>932.0&&xy.x<1009.0&&xy.y>282.0&&xy.y<440.0)
   ||(xy.x>849.0&&xy.x<936.0&&xy.y>474.0&&xy.y<524.0)
   ||(xy.x>780.0&&xy.x<908.0&&xy.y>547.0&&xy.y<583.0);
  if(xy.x>670.0 && xy.x<1020.0 && xy.y>270.0 && xy.y<632.0 && p.b>p.r*1.12 && p.g>p.r*1.12){
   float streak=pow(max(0.0,sin(xy.x*.6)),10.0)*pow(max(0.0,sin(xy.y*.14-flow*10.0+xy.x*.5)),5.0);
   float ripple=pow(max(0.0,sin(xy.y*.65+xy.x*.045-flow*4.3)),12.0)
    *(.5+.5*sin(xy.x*.16-flow*1.8));
   float wave=sin(xy.x*.08+xy.y*.21-flow*3.0);
   p.rgb=mix(p.rgb,vec3(.74,.93,.96),falls?streak*.7:ripple*.42);
   p.rgb*=1.0+(falls?.025:.06)*wave;
  }
 }
 if(material>3.5 && material<4.5){
  // A single continuous translucent paper-water sheet. Refraction samples a
  // separate scene copy, never the active framebuffer. Dry rock tops keep depth.
  vec2 q=world.xz;
  float phase=q.y*.145+sin(q.x*.065)*.75-flow*1.15;
  float swell=sin(phase);float cross=sin(q.x*.11-q.y*.08+flow*.65);
  vec2 drift=vec2(cos(phase)*.0014,sin(q.x*.09+phase)*.0010);
  float edge=1.0-smoothstep(95.0,100.7,length(q));
  vec2 screenUV=screen/love_ScreenSize.xy;
  vec3 original=Texel(waterScene,screenUV).rgb;
  vec3 bed=Texel(waterScene,clamp(screenUV+drift*edge,vec2(0.0),vec2(1.0))).rgb;
  float crest=smoothstep(.90,.985,swell)*(.35+.65*smoothstep(-.5,.5,sin(q.x*.095+flow*.32)));
  float second=smoothstep(.965,.995,sin(phase+1.15+cross*.25))*.32;
  float rim=(1.0-smoothstep(1.0,2.4,abs(length(q)-98.0)))*.38;
  float wake=0.0;
  for(int i=0;i<4;i++){
   vec2 anchor=i==0?vec2(-66.9,15.0):i==1?vec2(66.9,6.0):i==2?vec2(-29.0,-20.0):vec2(29.0,-28.0);
   float radius=length(q-anchor);float wave=sin(radius*.95-flow*1.8);
   wake+=smoothstep(.88,.99,wave)*(1.0-smoothstep(7.0,13.0,radius))*.32;
  }
  vec3 water=mix(bed*vec3(.63,.91,.97),vec3(.035,.42,.57),.22);
  water=mix(water,vec3(.23,.67,.74),(.5+.5*cross)*.09);
  water=mix(water,vec3(.78,.94,.91),clamp(crest*.55+second+rim+wake,0.0,.72));
  return vec4(mix(original,water,color.a),1.0);
 }
 if(material>4.5 && material<5.5)return vec4(vec3(.83,.80,.71)*shade,p.a)*color;
 if(material>8.5 && material<9.5){
  // Water printed on individual paper vents: scroll fine highlights without
  // distorting the cut edge or moving the surrounding masonry.
  if(p.b>p.r*1.45&&p.g>p.r*1.20&&p.g>.58&&p.r<.65){
   float lines=pow(max(0.0,sin(uv.y*360.0-flow*4.0+sin(uv.x*170.0))),12.0);
   p.rgb=mix(p.rgb,vec3(.82,.95,.92),lines*.27);
  }
 }
 if(material>9.5 && material<10.5){
  // Cyan signal lamps and teleport pads retain their actual alpha silhouette.
  if(p.b>.55&&p.g>.50&&p.b>p.r*1.25){
   float chase=.5+.5*sin(uv.x*38.0-flow*2.2);
   p.rgb=mix(p.rgb,vec3(.73,.94,1.0),pow(chase,5.0)*.35);
  }
 }
 if(material>19.5 && material<20.5){
  // Warm paper sparks are yellow, not cyan. Keep dark machinery unlit.
  float gold=smoothstep(.14,.32,p.r-p.b)*smoothstep(.45,.72,p.g);
  float chase=pow(.5+.5*sin(uv.x*38.0-flow*2.2),5.0);
  p.rgb=mix(p.rgb,vec3(1.0,.94,.63),gold*chase*.32);
 }
 if(material>20.5 && material<21.5){
  // Printed violet rings shimmer while their stems and plinth remain fixed.
  float violet=smoothstep(.025,.12,min(p.r,p.b)-p.g);
  float glint=pow(.5+.5*sin(uv.y*32.0+uv.x*18.0-flow*.9),9.0);
  p.rgb=mix(p.rgb,vec3(.95,.79,1.0),violet*glint*.24);
 }
 if(material>10.5 && material<11.5){
  if(p.r>.80&&p.g>.62&&p.g>p.b*1.13)
   p.rgb*=.96+.035*sin(flow*1.7+uv.x*13.0)+.012*sin(flow*4.3);
 }
 if(material>11.5 && material<12.5){
  // Only the two warm eyes in the isolated ghost relief reveal themselves.
  if(p.r>.65&&p.g>.50&&p.r>p.b*1.2)
   p.rgb=mix(vec3(.22,.22,.36),p.rgb,clamp(paperPulse,0.0,1.0));
 }
 if(material>13.5 && material<14.5){
  // Printed freshwater ripples drift across the water, keeping green lily
  // pads and the actual cut-paper shoreline intact.
  if(p.g>p.r*1.25 && p.b>p.r*1.4){
   float crest=pow(max(0.0,sin(world.z*.19+sin(world.x*.09)*.7-flow*1.1)),14.0);
   float ripple=sin(world.x*.09-world.z*.12+flow*.55);
   p.rgb=mix(p.rgb,vec3(.68,.89,.85),crest*.20);
   p.rgb*=1.0+ripple*.045;
  }
 }
 if(material>12.5 && material<13.5){
  if(p.r>.38&&p.g>.39&&p.b<min(p.r,p.g)*.72){
   float glint=pow(max(0.0,sin(uv.y*47.0-flow*.55)),12.0)*.08+paperPulse*.30;
   p.rgb=mix(p.rgb,vec3(.67,.88,.49),glint);
  }
 }
 if(material>16.5 && material<17.5){
  // Rain is confined to the blue window panes, never their wood mullions.
  if(p.b>p.r*1.09 && p.b>.24){
   float streak=pow(max(0.0,sin(uv.x*610.0+uv.y*290.0)),28.0)*pow(max(0.0,sin(uv.y*73.0-flow*4.0)),7.0);
   p.rgb=mix(p.rgb,vec3(.78,.89,.95),streak*.38);
  }
 }
 if(material>18.5 && material<19.5){
  // Muted cave water needs a lower luminance threshold than bright waterfalls.
  // Blue-green chroma excludes the grey tablets and green moss on these flats.
  if(p.b>p.r*1.18 && p.g>p.r*1.22 && p.b>p.g*.86 && p.g>.22){
   float crest=pow(max(0.0,sin(uv.y*270.0-flow*2.1+sin(uv.x*93.0))),10.0);
   p.rgb=mix(p.rgb,vec3(.65,.83,.81),crest*.27);
  }
 }
 if(material>17.5 && material<18.5){
  float sheen=pow(max(0.0,sin(uv.x*18.0-flow*.35)),18.0)*.08;
  p.rgb+=vec3(sheen);
 }
 if(material>14.5 && material<15.5){
  // The red/orange printed magma moves; cooled basalt and cut edges stay put.
  float molten=smoothstep(.18,.34,p.r-p.b)*smoothstep(.45,.70,p.r);
  float current=sin(uv.y*123.0+sin(uv.x*61.0)*1.6-flow*.85);
  float seam=pow(max(0.0,current),9.0);
  p.rgb=mix(p.rgb,vec3(1.0,.69,.20),molten*seam*.26);
  p.rgb*=1.0+molten*.045*sin(flow*.9+uv.x*19.0);
 }
 if(material>15.5 && material<16.5){
  // Slow frost reflections, never water flow: fine glints cross blue paper.
  float ice=smoothstep(.04,.18,p.b-p.r);
  float glint=pow(max(0.0,sin(uv.x*31.0+uv.y*17.0-flow*.31)),24.0);
  p.rgb=mix(p.rgb,vec3(.87,.95,1.0),ice*glint*.17);
 }
 if(material>7.5 && material<8.5){
  vec2 xy=uv*vec2(1448.0,1086.0);
  bool warm=p.r>p.b*1.75&&p.g>p.b*1.35&&p.r>.7&&p.g>.42;
  bool specimen=xy.x>880.0&&xy.x<981.0&&xy.y>200.0&&xy.y<315.0&&p.b>.53&&p.r>.60;
  if(warm)p.rgb*=.90+.10*sin(flow*2.1+xy.x*.04)+.035*sin(flow*4.7);
  if(specimen)p.rgb=mix(p.rgb,vec3(.99,.94,.82),pow(max(0.0,sin(xy.x*.045+xy.y*.019-flow*.65)),18.0)*.24);
 }
 if(material>5.5 && material<7.5){
  vec2 xy=uv*vec2(1448.0,1086.0);
  if(xy.x>paperEffectArea.x&&xy.y>paperEffectArea.y&&xy.x<paperEffectArea.z&&xy.y<paperEffectArea.w&&p.b>p.r*1.15&&p.g>p.r*1.1){
   if(material<6.5){float ripple=pow(max(0.0,sin(xy.y*.19+xy.x*.025-flow*2.0)),12.0);p.rgb=mix(p.rgb,vec3(.57,.86,.90),ripple*.18);}
   else {
    vec2 center=(paperEffectArea.xy+paperEffectArea.zw)*.5;
    vec2 localUV=(xy-center)/(paperEffectArea.zw-paperEffectArea.xy);
    float turn=pow(max(0.0,cos(atan(localUV.y,localUV.x)-flow*1.8)),8.0);
    p.rgb+=vec3(.20,.65,.75)*(paperPulse+turn*.18);
   }
  }
 }
 return p*vec4(light*shade,1.0)*color;
}
#endif
]]
local function clamp(x)return math.max(0,math.min(1,x))end
local function ease(x)x=clamp(x);return x*x*(3-2*x)end
local function mesh(vertices)
 local result=love.graphics.newMesh(format,vertices,'triangles','static')
 S.meshes[#S.meshes+1]=result;return result
end
local function vertex(x,y,z,u,v,shade)return{x,y,z,u or 0,v or 0,shade or 1}end
local function tri(out,a,b,c)out[#out+1]=a;out[#out+1]=b;out[#out+1]=c end
local function quad(out,a,b,c,d)tri(out,a,b,c);tri(out,a,c,d)end
local function disk(radius,inner)
 local out={}
 for i=0,95 do
  local a,b=i*math.pi/48,(i+1)*math.pi/48
  local function p(r,t)return vertex(math.cos(t)*r,math.sin(t)*r,0,.5+math.cos(t)*r/radius*.5,.5-math.sin(t)*r/radius*.5)end
  if inner then quad(out,p(inner,a),p(radius,a),p(radius,b),p(inner,b))else tri(out,p(0,0),p(radius,a),p(radius,b))end
 end
 return mesh(out)
end
local function sphere(radius,theta0,thetaLength,phi0,phiLength,outer)
 local out={};local nx,ny=72,24
 if phiLength<6 then nx=12 end
 local function p(i,j)
  local t=theta0+thetaLength*j/ny;local a=phi0+phiLength*i/nx
  local x,y,z=-radius*math.cos(a)*math.sin(t),radius*math.cos(t),radius*math.sin(a)*math.sin(t)
  local u,v=.5,.5
  if outer then
   u=(724+x/30*148)/1448
   v=(538-(y*math.cos(math.rad(8))-z*math.sin(math.rad(8)))/30*148)/1086
   if theta0>=math.pi/2 then v=math.max(v,.55)end
  end
  return vertex(x,y,z,u,v)
 end
 for j=0,ny-1 do for i=0,nx-1 do quad(out,p(i,j),p(i+1,j),p(i+1,j+1),p(i,j+1))end end
 return mesh(out)
end
-- Decode a texture once while its stage is assembled. The CPU copy supplies
-- alpha components and the paper swatch, then is released after panel upload.
local decodedImages,componentCache={},{}
local function imageData(name)
 local filename=name:find('.',1,true)and name or name..'.jpg'
 if not decodedImages[filename]then
  decodedImages[filename]=V.require('battle/terrarium/PaperArtAssets').load(filename)
 end
 return decodedImages[filename]
end
local function clearDecoded()
 for _,data in pairs(decodedImages)do data:release()end;decodedImages={}
end
local function image(name)
 local filename=name:find('.',1,true)and name or name..'.jpg'
 -- Continuous painted floor sheets need minification filtering when the
 -- lid opens and the settled camera moves closer. Keep cutout atlases at
 -- their existing sampling so mip levels cannot bleed across paper panels.
 local planar=filename:match('%-floor%.png$')~=nil or filename=='floor.jpg'
 local result=love.graphics.newImage(imageData(name),{mipmaps=planar})
 result:setFilter('linear','linear',planar and 4 or 1)
 if planar then result:setMipmapFilter('linear',0)end
 return result
end
local function buildPanels(layout)
 local panels={}
 local function alpha(name)return imageData(name)end
 -- Disconnected clouds/leaves in an atlas rectangle are separate physical
 -- paper cards. Their original arrangement is preserved without editing pixels.
 local expanded={}
 for _,def in ipairs(layout)do
  local pieces
  if def.mount=='lid'and def.cutout and def.texture and #def.points==4 and not def.preservePaperPiece then
   local x0,y0,x1,y1=def.points[1][1],def.points[1][2],def.points[3][1],def.points[3][2]
   local key=def.texture..':'..x0..':'..y0..':'..x1..':'..y1
   pieces=componentCache[key]
   if not pieces then
    pieces={};local data=alpha(def.texture);local step=2
    local w,h=math.ceil((x1-x0)/step),math.ceil((y1-y0)/step);local pixels={}
    for y=0,h-1 do for x=0,w-1 do
     local _,_,_,a=data:getPixel(math.min(data:getWidth()-1,math.floor(x0+x*step)),math.min(data:getHeight()-1,math.floor(y0+y*step)))
     if a>.5 then pixels[y*w+x]=true end
    end end
    for n=0,w*h-1 do if pixels[n]then
     local todo={n};pixels[n]=nil;local ax,ay,bx,by=w,h,0,0;local count=0
     while #todo>0 do
      local i=table.remove(todo);local x,y=i%w,math.floor(i/w);count=count+1
      ax=math.min(ax,x);ay=math.min(ay,y);bx=math.max(bx,x);by=math.max(by,y)
      for _,j in ipairs({x>0 and i-1 or -1,x<w-1 and i+1 or -1,y>0 and i-w or -1,y<h-1 and i+w or -1})do
       if pixels[j]then pixels[j]=nil;todo[#todo+1]=j end
      end
     end
     if count>math.max(40,w*h*.01)then pieces[#pieces+1]={math.max(x0,x0+ax*step-2),math.max(y0,y0+ay*step-2),math.min(x1,x0+(bx+1)*step+2),math.min(y1,y0+(by+1)*step+2)}end
    end end
    componentCache[key]=pieces
   end
   if #pieces>1 then
    for i,b in ipairs(pieces)do
     local d={};for k,v in pairs(def)do d[k]=v end
     local unit=def.width*30/(x1-x0)
     d.points={{b[1],b[2]},{b[3],b[2]},{b[3],b[4]},{b[1],b[4]}}
     d.width=def.width*(b[3]-b[1])/(x1-x0)
     d.x=def.x+((b[1]+b[3]-x0-x1)/2)*unit/30*(def.mirror and -1 or 1)
     d.y=(def.y or -1.35)+(y1-b[4])*unit*(def.heightScale or 1)
     d.begin=def.begin+(i-1)*.025;d.pivot=nil;expanded[#expanded+1]=d
    end
   else expanded[#expanded+1]=def end
  else expanded[#expanded+1]=def end
 end
 layout=expanded
 for _,def in ipairs(layout)do
  if def.texture and not S.images[def.texture]then S.images[def.texture]=image(def.texture)end
  local x0,y0,x1,y1=math.huge,math.huge,-math.huge,-math.huge
  for _,p in ipairs(def.points)do x0=math.min(x0,p[1]);x1=math.max(x1,p[1]);y0=math.min(y0,p[2]);y1=math.max(y1,p[2])end
  local scale=def.width*30/(x1-x0);local flat={};local vertices={};local backs={};local edges={}
  for _,p in ipairs(def.points)do flat[#flat+1]=p[1];flat[#flat+1]=p[2]end
  local function p(x,y,z)
   local u=(x-(x0+x1)/2)/(x1-x0)*2
   return vertex((x-(x0+x1)/2)*scale,(y1-y)*scale*(def.heightScale or 1),z+(def.curve or 0)*u*u,(def.mirror and(x0+x1-x)or x)/(def.imageWidth or 1448),y/(def.imageHeight or 1086))
  end
  if def.cutout and #def.points==4 then
   -- Transparent artwork is tessellated into a gently curved paper ribbon.
   -- Its alpha silhouette also masks the reverse face, never an opaque card.
   for i=0,23 do
    local a,b=x0+(x1-x0)*i/24,x0+(x1-x0)*(i+1)/24
    quad(vertices,p(a,y1,.6),p(b,y1,.6),p(b,y0,.6),p(a,y0,.6))
    quad(backs,p(a,y1,0),p(a,y0,0),p(b,y0,0),p(b,y1,0))
   end
  else for _,t in ipairs(love.math.triangulate(flat))do
   tri(vertices,p(t[1],t[2],.6),p(t[3],t[4],.6),p(t[5],t[6],.6))
   tri(backs,p(t[1],t[2],0),p(t[5],t[6],0),p(t[3],t[4],0))
  end end
  if not def.cutout then for i,a in ipairs(def.points)do local b=def.points[i%#def.points+1];quad(edges,p(a[1],a[2],0),p(b[1],b[2],0),p(b[1],b[2],.6),p(a[1],a[2],.6))end end
  local supports
  if def.support and(def.y or 0)>0 then
   local strips={};local height=def.y+1.35
   for _,x in ipairs({-def.width*30*.28,def.width*30*.28})do
    quad(strips,vertex(x-1.25,0,0,0,0),vertex(x+1.25,0,0,1,0),vertex(x+1.25,height,0,1,1),vertex(x-1.25,height,0,0,1))
   end
   supports=mesh(strips)
  end
  local hanging
  if def.mount=='lid'and def.hanging~=false then
   local height=(y1-y0)*scale*(def.heightScale or 1)
   local data
   if def.texture then
    data=alpha(def.texture)
   end
   hanging={height=height,points={}}
   for _,fraction in ipairs(def.hangingFractions or{.28,.72})do
    local px=x0+(x1-x0)*fraction;local py=y0
    if data then
     local sampleX=math.floor(def.mirror and x0+x1-px or px)
     for row=math.floor(y0),math.min(data:getHeight()-1,math.ceil(y1)-1)do
      local _,_,_,a=data:getPixel(math.max(0,math.min(data:getWidth()-1,sampleX)),row)
      if a>.55 then py=row+1;break end
     end
    end
    hanging.points[#hanging.points+1]={(px-(x0+x1)/2)*scale,(y1-py)*scale*(def.heightScale or 1),.75}
   end
   local v={};for i=1,#hanging.points*6 do v[i]=vertex(0,0,0)end
   hanging.mesh=mesh(v)
  end
  panels[#panels+1]={def=def,front=mesh(vertices),back=mesh(backs),edge=#edges>0 and mesh(edges)or nil,supports=supports,hanging=hanging}
 end
 clearDecoded()
 return panels
end
function S.prepareShader()
 S.shader=S.shader or V.require('ShaderCompiler').newShader(shaderSource)
end
local function init()
 if S.meshes then return end
 S.meshes={};S.images={}
 for _,name in ipairs({'landscape','shell','floor','paper'})do S.images[name]=image(name)end
 local paleData=love.image.newImageData(150,150)
 paleData:paste(imageData('paper'),0,0,350,780,150,150)
 S.images.pale=love.graphics.newImage(paleData);paleData:release()
 S.prepareShader()
 local d=love.image.newImageData(1,1);d:setPixel(0,0,1,1,1,1);S.white=love.graphics.newImage(d);d:release()
 S.bottom=sphere(S.R,math.pi/2,math.pi/2,0,math.pi*2,true)
 S.top=sphere(S.R,0,math.pi/2,0,math.pi*2,true)
 S.inside=sphere(S.R-1.35,0,math.pi/2,0,math.pi*2,false)
 S.rim=disk(S.R+.18,S.R-1.6)
 local band={}
 for i=0,95 do
  local a,b=i*math.pi/48,(i+1)*math.pi/48
  local function p(t,y)return vertex(math.cos(t)*(S.R+.3),y,math.sin(t)*(S.R+.3))end
  quad(band,p(a,0),p(b,0),p(b,-3.15),p(a,-3.15))
 end
 S.band=mesh(band)
 local collar={}
 for i=0,95 do
  local a,b=i*math.pi/48,(i+1)*math.pi/48
  local function p(t,y)return vertex(math.cos(t)*(S.R-1.5),y,math.sin(t)*(S.R-1.5))end
  quad(collar,p(a,0),p(b,0),p(b,-2.4),p(a,-2.4))
 end
 S.collar=mesh(collar)
 -- Overlap the inner rim; the former radius left a visible open annulus.
 S.floor=disk(S.R-1.15)
 for i=1,S.floor:getVertexCount()do local x,y,z,u,v,s=S.floor:getVertex(i);S.floor:setVertex(i,x,y,z,.04+.92*u,.04+.92*v,s)end
 local basin={}
 for ring=0,11 do for i=0,95 do
  local function p(r,t)return vertex(math.cos(t)*r,-46+43*(r/100.85)^3,math.sin(t)*r,.5+math.cos(t)*r/201.7,.5+math.sin(t)*r/201.7)end
  local a,b=i*math.pi/48,(i+1)*math.pi/48;local r0,r1=ring*100.85/12,(ring+1)*100.85/12
  quad(basin,p(r0,a),p(r1,a),p(r1,b),p(r0,b))
 end end
 S.seaFloor=mesh(basin);S.waterSurface=disk(100.7)
 local shadow={};quad(shadow,vertex(-1,0,-1,0,0),vertex(1,0,-1,1,0),vertex(1,0,1,1,1),vertex(-1,0,1,0,1));S.seaShadow=mesh(shadow)
 S.bubble=disk(1,.78)
 S.waterRipple=disk(1,.86)
 S.buttonHalo=disk(25.2);S.buttonFace=disk(18.3);S.buttonRing=disk(19.05,17.7)
 S.digHole=disk(1)
 local pebble={};local points={{-.9,-.3},{-.7,.45},{-.1,.8},{.65,.5},{1,-.1},{.4,-.55},{-.4,-.6}}
 for i,a in ipairs(points)do local b=points[i%#points+1];local shade=.76+(i%3)*.11
  tri(pebble,vertex(0,0,0,.5,.5,shade),vertex(a[1],a[2],0,.5+a[1]*.3,.5+a[2]*.3,shade),vertex(b[1],b[2],0,.5+b[1]*.3,.5+b[2]*.3,shade))
 end
 S.pebble=mesh(pebble)
 local star={};local starPoints={{0,1},{.18,.18},{1,0},{.18,-.18},{0,-1},{-.18,-.18},{-1,0},{-.18,.18}}
 for i,a in ipairs(starPoints)do local b=starPoints[i%#starPoints+1];tri(star,vertex(0,0,0),vertex(a[1],a[2],0),vertex(b[1],b[2],0))end
 S.star=mesh(star)
 local spark={};local zig={{-1,0},{-.55,.16},{-.17,-.19},{.2,.17},{.55,-.12},{1,0}}
 for i=1,#zig-1 do local a,b=zig[i],zig[i+1]
  quad(spark,vertex(a[1],a[2]-.028,0),vertex(b[1],b[2]-.028,0),vertex(b[1],b[2]+.028,0),vertex(a[1],a[2]+.028,0))
 end
 S.spark=mesh(spark)
 local steam={}
 for i=0,17 do
  local function p(t,side)local w=.20*math.sin(t*math.pi)+.035;return vertex(math.sin(t*7)*.34+side*w,t*2.3,0)end
  quad(steam,p(i/18,-1),p(i/18,1),p((i+1)/18,1),p((i+1)/18,-1))
 end
 S.steam=mesh(steam)
 local torn={}
 for i=0,23 do
  local a,b=i*math.pi/12,(i+1)*math.pi/12
  local function p(t,r)return vertex(math.cos(t)*r,math.sin(t)*r,0,.5,.5)end
  quad(torn,p(a,.84),p(a,1.08+.08*math.sin(i*2.7)),p(b,1.08+.08*math.sin((i+1)*2.7)),p(b,.84))
 end
 S.digRim=mesh(torn)
 S.digChip=mesh({vertex(-.6,0,0),vertex(.6,0,0),vertex(.1,1.15,0)})
 for i=1,S.buttonFace:getVertexCount()do local x,y,z,u,v,s=S.buttonFace:getVertex(i);S.buttonFace:setVertex(i,x,y,z,(621+u*203)/1448,(564+v*203)/1086,s)end
 S.mirrors={sphere(S.R-2.31,0,.295,0,math.pi*2,false)}
 for i=0,9 do S.mirrors[#S.mirrors+1]=sphere(S.R-2.31,.33,1.16,i*math.pi/5+.022,math.pi/5-.044,false)end
 S.seaMirrors={}
 for i=0,9 do S.seaMirrors[#S.seaMirrors+1]=sphere(S.R-2.31,1.22,.27,i*math.pi/5+.022,math.pi/5-.044,false)end
 S.panels=buildPanels(Layout)
end
local function trimStages()
 local oldest,age,count=nil,nil,0
 for key,stage in pairs(S.stages or{})do
  count=count+1;if not age or stage.used<age then oldest,age=key,stage.used end
 end
 if count<3 then return end
 local stage=S.stages[oldest];S.stages[oldest]=nil
 local discard={};for _,m in ipairs(stage.ownedMeshes or{})do discard[m]=true;m:release()end
 for i=#S.meshes,1,-1 do if discard[S.meshes[i]]then table.remove(S.meshes,i)end end
 local keep={landscape=true,shell=true,floor=true,paper=true,pale=true,kyogre=true}
 for _,other in pairs(S.stages)do for name in pairs(other.imageNames)do keep[name]=true end end
 for name,img in pairs(S.images)do if not keep[name]then img:release();S.images[name]=nil end end
 componentCache={};clearDecoded()
end
function S.create(game,battle)
 local edition=require('src.core.GameVersion').get()
 if edition~='emerald'and edition~='firered'and edition~='leafgreen'then return nil,'unsupported paper edition'end
 local id,def=V.require('WorldAdapter').current(game)
 local worldState
 if id=='EM_SHOAL_CAVE_LOW_TIDE_ENTRANCE_ROOM'or id=='EM_SHOAL_CAVE_LOW_TIDE_INNER_ROOM'then
  worldState={shoalHighTide=require('src.core.game3.rse.init').flag('FLAG_SYS_SHOAL_TIDE')}
 end
 local habitat
 if edition=='emerald'then habitat=Habitats.resolveBattle(id,def,battle,worldState)
 else habitat=V.require('battle/terrarium/KantoPaperHabitats').resolveBattle(id,def,battle)end
 if not habitat then return nil,'Kanto location keeps its authored terrarium'end
 init()
 if battle.link and not battle.towerLinkMulti then habitat={id=id,key='facility:link',family='facility',landmark='link',reason='link battle'}end
 local registry=V.data('EmeraldTerrariumArt')
 if edition~='emerald'then registry=V.require('battle/terrarium/KantoPaperArt').registry(registry)end
 local art,artStatus,artKey=ArtCoverage.resolve(habitat,registry)
 if art and art.kanto then artStatus='kanto-composed'end
 local eye,target={0,195,450},{0,48,-12}
 if art and art.sea then eye,target={0,250,370},{0,24,-18}end
 if art and art.camera then eye,target=art.camera.eye,art.camera.target end
 local vp=M.mul(M.scale(1,-1,1),M.mul(M.perspective(math.rad(43),240/160,1,3000),M.lookAt(eye,target,{0,1,0})))
 -- Keep the front arena above the original command panel. A fixed camera is
 -- used throughout flight/opening; only the entire ball moves during flight.
 local framing=M.identity();framing[6]=1.34;framing[8]=-.16;framing[1]=1.34
 vp=M.mul(framing,vp)
 local feet={player={-24.6,30.6},enemy={25.2,27.3},playerTrainer={-63,20.55}}
 local ground={player=-1.74,enemy=-1.74,playerTrainer=(-.045+72*1.12/184)*30}
 if not battle.wild then feet.enemyTrainer={63.6,7.35};ground.enemyTrainer=(-.045+74*1.12/182)*30 end
 local scene={kind='terrarium',edition=edition,paperPopup=true,map=id,scale=1,contactScale=.42,focus={px=0,py=0},vp=vp,eye=eye,target=target,feet=feet,ground=ground,time=8,waterTime=0,cinematic=false}
 scene.viewportGame=game
 scene.nonBlocking=battle.link==true
 scene.habitat=habitat;scene.artStatus=artStatus;scene.artKey=artKey;scene.ambientPlan=art and art.ambientPlan
 -- Only illustrated, reviewed assets can enter this registry.
 scene.stage=nil
 if art then
  S.stages=S.stages or{}
  local stageKey=artKey..':'..art.landscape..':'..(art.layoutKey or art.layout)..(battle.double and ':double' or '')..(battle.partner and ':partner' or '')..(battle.trainerB and ':two-opponents' or '')..(battle.multi and ':multi' or '')
  if not S.stages[stageKey]then
   trimStages();local meshStart=#S.meshes
   local landscape=S.images[art.landscape]or image(art.landscape);local floor=art.floor==art.landscape and landscape or S.images[art.floor]or image(art.floor)
   S.images[art.landscape]=landscape;S.images[art.floor]=floor
   local floorMesh
   if art.floorRect then
    floorMesh=disk(S.R-1.15);local r=art.floorRect;local iw,ih=floor:getDimensions()
    for i=1,floorMesh:getVertexCount()do local x,y,z,u,v,shade=floorMesh:getVertex(i)
     floorMesh:setVertex(i,x,y,z,(r[1]+u*(r[3]-r[1]))/iw,(r[2]+v*(r[4]-r[2]))/ih,shade)
    end
   end
   local layout
   if art.kanto then layout=V.require('battle/terrarium/KantoPaperArt').layout(art)
   else layout=V.data(art.layout);if art.layoutKey then layout=layout[art.layoutKey]end end
   layout=V.data('EmeraldFinishingEvents').apply(artKey,layout)
   local natureEvents=V.data('EmeraldNatureEventCards')[artKey] or V.data('EmeraldUnderseaEventCards')[artKey] or V.data('EmeraldShoreEventCards')[artKey]
   if natureEvents then
    -- Do not mutate the shared source layout or accumulate cards on view changes.
    local composed={};for _,d in ipairs(layout)do composed[#composed+1]=d end
    for _,d in ipairs(natureEvents)do composed[#composed+1]=d end
    layout=composed
   end
   if art.platform and art.platform.paperStack then
    local composed={};for _,d in ipairs(layout)do composed[#composed+1]=d end
    for _,d in ipairs(PaperPlatform.cards(art.platform))do composed[#composed+1]=d end
    layout=composed
   end
   if battle.double then layout=DoublesLayout.panels(layout,art)end
   local platform
   if art.platform then
    local p=art.platform;local tex=S.images[p.texture]or image(p.texture);S.images[p.texture]=tex
    local function edgeRadius(t)return p.radius+(p.edge or 0)*(.55+.25*math.sin(t*5)+.20*math.sin(t*9+.7))end
    local top=disk(p.radius);local iw,ih=tex:getDimensions();local r=p.rect
    for i=1,top:getVertexCount()do local x,y,z,u,v,shade=top:getVertex(i)
     if p.edge and x*x+y*y>0 then local factor=edgeRadius(math.atan2(-y,x))/p.radius;x,y=x*factor,y*factor end
     top:setVertex(i,x,y,z,(r[1]+u*(r[3]-r[1]))/iw,(r[2]+v*(r[4]-r[2]))/ih,shade)
    end
    local side={}
    local strata=(p.paperStack or p.paperDock)and 0 or(p.strata or 4)
    for layer=0,strata-1 do for i=0,95 do
     local function edge(t,y)
      local radius=edgeRadius(t)+(layer%2)*(p.edge and .45 or .20)
      return vertex(math.cos(t)*radius,y,math.sin(t)*radius,(i%12)/12,(layer%2)*.45,p.strata and(.78+(layer%3)*.08)or(.84+layer*.035))
     end
     local a,b=i*math.pi/48,(i+1)*math.pi/48;local bottom=p.bottom or -2.25;local h=(p.height-bottom)/strata
     quad(side,edge(a,bottom+layer*h),edge(b,bottom+layer*h),edge(b,bottom+(layer+1)*h),edge(a,bottom+(layer+1)*h))
    end end
    platform={def=p,top=top,texture=tex}
    if p.paperDock then
     local wood=PaperDock.build(p)
     platform.wood={faces=mesh(wood.faces),edges=mesh(wood.edges),posts=mesh(wood.posts),braces=#wood.braces>0 and mesh(wood.braces)or nil}
    elseif p.paperStack then
     local stack=PaperPlatform.build(p,edgeRadius)
     platform.side=mesh(stack.sides);platform.ledges=mesh(stack.ledges);platform.seams=mesh(stack.seams)
    else platform.side=mesh(side)end
   end
   local dock
   if art.dockPiers then
    local top,sides={},{}
    -- Separate thin paper dock wings. Clip their outer ends to the round
    -- bowl; dock props and trainer platforms must not float over water.
    for _,sign in ipairs({-1,1})do for z=-55,60,5 do
     local function point(x,h,q)return vertex(sign*x,h,q,(sign*x+S.R)/(S.R*2),(q+S.R)/(S.R*2))end
     local a=math.min(90,math.sqrt((S.R-2)^2-z*z))
     local b=math.min(90,math.sqrt((S.R-2)^2-(z+5)^2))
     quad(top,point(56,-1.30,z),point(a,-1.30,z),point(b,-1.30,z+5),point(56,-1.30,z+5))
     quad(sides,point(a,-1.30,z),point(a,-4,z),point(b,-4,z+5),point(b,-1.30,z+5))
     if z==-55 or z==40 then
      local x=74
      quad(sides,point(x-2,-1.30,z),point(x+2,-1.30,z),point(x+2,-38,z),point(x-2,-38,z))
     end
    end end
    dock={top=mesh(top),side=mesh(sides),texture=platform.texture}
   end
   S.stages[stageKey]={rawLayout=layout,texture=landscape,floor=floor,floorMesh=floorMesh,panels=buildPanels(layout),water=art.water,sea=art.sea,basin=art.basin or art.sea,dock=dock,floorFlow=art.floorFlow,floorLava=art.floorLava,floorFrost=art.floorFrost,paperCaps=art.paperCaps~=false and art.battlerGround~=nil,platform=platform}
   local stage=S.stages[stageKey];stage.ownedMeshes={};stage.imageNames={[art.landscape]=true,[art.floor]=true}
   if art.platform then stage.imageNames[art.platform.texture]=true end
   for _,d in ipairs(layout)do if d.texture then stage.imageNames[d.texture]=true end end
   for i=meshStart+1,#S.meshes do stage.ownedMeshes[#stage.ownedMeshes+1]=S.meshes[i]end
  end
  S.stageClock=(S.stageClock or 0)+1;S.stages[stageKey].used=S.stageClock
  scene.stage=S.stages[stageKey];scene.ambientOrigin=art.smoke
  if art.battleFootprint then
   local p=art.battleFootprint;scene.battleFootprint={x=p.x,z=p.z,radius=p.radius}
  end
  if art.battlerGround then scene.ground.player=art.battlerGround;scene.ground.enemy=art.battlerGround end
  if art.trainerGround then scene.ground.playerTrainer=art.trainerGround;if not battle.wild then scene.ground.enemyTrainer=art.trainerGround end end
  if (art.sea or art.basin)and not S.images.kyogre then S.images.kyogre=image('kyogre-shadow.png');clearDecoded()end
 end
 if art and art.sea then
  scene.lidAngle=-3.0
  scene.feet.player={-29,-18};scene.feet.enemy={29,-26};scene.ground.player=7.5;scene.ground.enemy=7.5
  scene.feet.playerTrainer={-66.9,17};scene.ground.playerTrainer=3.7
  if not battle.wild then scene.feet.enemyTrainer={66.9,8};scene.ground.enemyTrainer=4.7 end
 end
 -- Authored coordinates are copied per battle: animation never mutates the
 -- registry or another habitat. EffectFit, shadows, throws and Dig all read
 -- these same feet/rest anchors through PaperBattlePresentation.
 if art and art.anchors then
  for side,p in pairs(art.anchors)do
   if feet[side]then feet[side]={p[1],p[3]};ground[side]=p[2]end
  end
 end
 scene.safari=battle.safari==true
 if scene.safari then feet.player=nil;ground.player=nil end
 scene.double=battle.double==true
 if scene.double then
  -- Four independent floor anchors follow native depth order (3,1,0,2).
  -- Keep an entire Dig aperture inside the physical battle floor.
  local platform=scene.stage and scene.stage.platform
  local floor=platform and platform.def or scene.battleFootprint or{x=0,z=15,radius=80}
  scene.battleFootprint=floor
  local y=platform and floor.height or ground.player
  for side,p in pairs(DoublesLayout.feet)do
   feet[side]={p[1],p[2]};ground[side]=y
  end
 end
 if scene.double and(battle.partner or battle.trainerB or battle.multi)then
  local stage=scene.stage
  if not stage then return nil,'no authored multi-trainer stage'end
  if not stage.multiFeet then
   local layout,anchors=DoublesLayout.trainers(stage.rawLayout,feet,ground,battle)
   if not layout then return nil,anchors end
   stage.panels=buildPanels(layout);stage.multiFeet=anchors
  end
  for side,p in pairs(stage.multiFeet)do feet[side]={p[1],p[3]};ground[side]=p[2]end
 end
 scene.cameraBase=vp;scene.zoom=1;scene.idleAge=0
 S.preference(scene)
 scene.wild=battle.wild;scene.rest={};for k,p in pairs(feet)do scene.rest[k]={p[1],ground[k],p[2]}end
 return scene
end
function S.enter(scene,entry)
 S.leave(scene)
 scene.idleAge=0;scene.idlePulse=0;AmbientMotion.reset(scene)
 scene.introStyle=V.mod and V.mod.options:get('gen3TerrariumIntro')or'balanced'
 scene.timing=S.timings[scene.introStyle]or S.timings.balanced
 scene.fast=entry=='switch'or scene.introStyle~='cinematic'
 scene.nativeIntroVisible=scene.nonBlocking==true
 scene.entry=entry;scene.elapsed=0;scene.time=entry=='battle'and 0 or 1.4;scene.cinematic=true;scene.soundPlayed=false;scene.soundCount=0
 if entry=='battle'then scene.popupOwnsIntro=scene.wild and not scene.double end
 if entry=='battle'and scene.wild and not scene.double then scene.dialogue=PopupDialogue.new(scene.fast,scene.introStyle,scene.safari)end
end
-- Keep authored poses on one timeline; fast mode overlaps the native intro.
function S.entryTime(elapsed,timing)
 local t=timing or S.timings.fast
 if elapsed<=t.flash then return elapsed*.16/t.flash end
 if elapsed<t.arrival then return .16+(elapsed-t.flash)*(S.OPEN-.16)/(t.arrival-t.flash)end
 if elapsed<t.ready then return S.OPEN+(elapsed-t.arrival)*(5.2-S.OPEN)/(t.ready-t.arrival)end
 return 5.2+(elapsed-t.ready)*3
end
function S.panelProgress(scene,def)
 if scene.fast then
  local begin=scene.entry=='switch'and .065 or scene.timing.panel
  local spread=scene.entry=='switch'and .035 or scene.timing.spread
  local duration=scene.entry=='switch'and .25 or scene.timing.fold
  local offset=(def.foldOffset or 0)*(scene.entry=='switch'and .15 or 1)
  return ease((scene.elapsed-begin-(def.begin-3.12)*spread-offset)/duration)
 end
 return ease((scene.time-def.begin-.4)/def.duration)
end
function S.update(game,scene,dt)
 local was=scene.cinematic
 scene.waterTime=scene.waterTime+math.max(0,math.min(dt or 0,.1))
 if was then
  local duration=scene.entry=='battle'and 5.2 or S.SWITCH_END
  local step=math.max(0,math.min(dt or 0,.1))
  scene.elapsed=(scene.elapsed or 0)+step
  local nextTime=scene.time+step
  if scene.fast then nextTime=scene.entry=='battle'and S.entryTime(scene.elapsed,scene.timing)or 1.4+scene.elapsed*(S.SWITCH_END-1.4)/.4 end
  scene.time=math.min(duration,nextTime)
  if not scene.soundPlayed and scene.time>=S.OPEN then
   require('src.core.game3.audio').playSe('SE_BALL_OPEN');scene.soundPlayed=true;scene.soundCount=scene.soundCount+1
  end
  scene.cinematic=scene.time<duration
  if not scene.cinematic and not scene.nonBlocking and not(scene.fast and scene.dialogue)then game.input:reset()end
 end
 scene.nativeIntroVisible=scene.fast and scene.entry=='battle'and scene.elapsed>=scene.timing.arrival
 if scene.nonBlocking then scene.nativeIntroVisible=true end
 local hold=was and not scene.nativeIntroVisible
 if scene.dialogue and not hold then
  if require('src.core.game3.battle')._phase=='intro'then PopupDialogue.update(scene.dialogue,math.max(0,math.min(dt or 0,.1)))
  else PopupDialogue.finish(scene.dialogue)end
 end
 if scene.cameraBase then
  local battle=require('src.core.game3.battle');local ui=require('src.core.game3.battle.ui')
  local cursor=tostring(ui._mode)..':'..tostring(ui._menuIndex)..':'..tostring(ui._moveIndex)
  local input=game.input;local pressed=input and input.pressQueue and #input.pressQueue>0
  for _,held in pairs(input and(input.state or input.down)or{})do if held then pressed=true;break end end
  local ready=not was and battle._phase=='command'and not ui.dialogPending()and not pressed and not require('src.ui.game3.stack').busy()
  AmbientMotion.update(scene,dt,ready)
  CameraMotion.activity(scene,ready,cursor,math.max(0,math.min(dt or 0,.1)))
  S.preference(scene)
  if scene.autoZoomTarget then
   scene.autoZoomAge=(scene.autoZoomAge or 0)+math.max(0,math.min(dt or 0,.1))
   local done;scene.zoom,done=AutoFrame.sample(scene.autoZoomFrom,scene.autoZoomTarget,scene.autoZoomAge)
   if done then scene.autoZoomTarget=nil;scene.autoZoomSettled=true end
  end
  if CameraMotion.impact(scene)and V.mod.options:get('gen3TerrariumIdleSound')~=false then
   if idleSound.play(require('src.core.game3.audio')._sfxVolume or 1)then scene.idleSoundCount=(scene.idleSoundCount or 0)+1 end
  end
  if scene.idleAge==0 or V.mod.options:get('gen3TerrariumIdleSound')==false then idleSound.stop()end
  S.camera(scene)
 end
 return hold
end
function S.leave(scene)
 idleSound.stop()
 if scene then scene.idleAge=0;scene.idleBeat=nil end
end
function S.preference(scene)
 local value=tonumber(V.mod.options:get('gen3TerrariumZoom'))or 1
 value=math.max(.65,math.min(2.5,value))
 if scene.zoomPreference~=value then
  if scene.zoomPreference~=nil then scene.autoZoomManual=true;scene.autoZoomTarget=nil end
  scene.zoomPreference=value;scene.zoom=value;S.leave(scene)
 end
end
function S.idlePlaying()return idleSound.playing()end
local function openShellFit(scene)
 if scene.openShellFit then return scene.openShellFit end
 local project=V.require('Camera').project
 local minX,minY,maxX,maxY=1,1,0,0
 local a=scene.lidAngle or -1.94;local co,si=math.cos(a),math.sin(a)
 -- The final open shell, not its current animated pose: no camera pumping
 -- during the approach/opening. This also handles the sea's different hinge.
 for ring=0,24 do for step=0,48 do
  local t,p=math.pi*ring/24,2*math.pi*step/48
  local x,y,z=-S.R*math.cos(p)*math.sin(t),S.R*math.cos(t),S.R*math.sin(p)*math.sin(t)
  if y>0 then y,z=co*y-si*(z+S.R),si*y+co*(z+S.R)-S.R end
  local u,v=project(scene.cameraBase,x,y,z)
  if u then minX=math.min(minX,u);maxX=math.max(maxX,u);minY=math.min(minY,v);maxY=math.max(maxY,v)end
 end end
 local scale=math.min(1,.94/(maxX-minX),.94/(maxY-minY))
 scene.openShellFit={scale,scale*(1-minX-maxX),scale*(1-minY-maxY)}
 return scene.openShellFit
end
function S.camera(scene)
 local width,height=love.graphics.getDimensions()
 local safe=package.loaded['src.core.SafeArea']
 if safe and safe.windowRect then local _,_,w,h=safe.windowRect();if w and h and w>0 and h>0 then width,height=w,h end end
 if scene.viewportGame then local _,_,w,h=BattleViewport.safeRect(scene.viewportGame);width,height=w,h end
 if scene.aspectOverride then width,height=scene.aspectOverride,1 end
 local layout=ResponsiveLayout.apply(scene,width,height)
 local roll,pulse=CameraMotion.sample(scene.idleAge or 0);scene.idlePulse=pulse
 -- Same inverse camera roll as VASC: every actor and prop stays attached.
 local dy,dz=scene.eye[2]-scene.target[2],scene.eye[3]-scene.target[3]
 local len=math.sqrt(dy*dy+dz*dz);local q=M.fromQuat(0,dy/len*math.sin(-roll/2),dz/len*math.sin(-roll/2),math.cos(roll/2))
 local rocking=M.mul(M.translate(0,-64,0),M.mul(q,M.translate(0,64,0)))
 local zoom=(scene.zoom or 1)*layout.camera;local framing=M.identity();framing[1]=zoom;framing[6]=zoom
 -- Zoom toward the arena between the combatants, not the ball's lid. Move
 -- that focus slightly up on close views to keep feet above the native HUD.
 framing[8]=zoom>1 and(.125*(1-zoom)-.10*clamp((zoom-1)/1.5))or(-.16*(1-zoom))
 scene.vp=M.mul(framing,M.mul(scene.cameraBase,rocking))
 -- A tall window can reveal the whole lid. Its off-screen top must not turn
 -- into a visibly sliced horizontal edge when the canvas floats below the HUD.
 local amount=require('src.core.game3.battle.ui').presentationHudVersion==1 and ease((1.3-width/height)/.5)or 0
 scene.windowFitScale=1
 if amount>0 then
  local fit=openShellFit(scene);local aperture=M.identity()
  scene.windowFitScale=1+(fit[1]-1)*amount
  aperture[1],aperture[6]=scene.windowFitScale,scene.windowFitScale
  aperture[4],aperture[8]=fit[2]*amount,fit[3]*amount
  scene.vp=M.mul(aperture,scene.vp)
 end
end
function S.wheel(scene,dy)
 scene.autoZoomManual=true;scene.autoZoomTarget=nil
 scene.zoom=CameraMotion.zoom(scene.zoom or 1,dy);S.leave(scene);S.camera(scene)
end
local depthRows,depthAt,depthChanged,depthOwner={},0,true,nil
local depthFlow
local function depthValue(value)
 value=value==nil and false or value
 depthAt=depthAt+1;if depthRows[depthAt]~=value then depthRows[depthAt]=value;depthChanged=true end
end
local function draw(mesh,tex,model,material,color)
 local mode,write=love.graphics.getDepthMode()
 if write then
  depthValue(mesh);depthValue(tex);depthValue(material or 0)
  for i=1,16 do depthValue(model[i])end
  -- Animated materials may change their alpha coverage.
  if material and material~=0 and material~=5 then depthValue(depthFlow)end
  depthValue(color and color[4]or 1)
 end
 V.require('UniformState').send(S.shader,'model','row',model);V.require('UniformState').send(S.shader,'material',material or 0)
 if color then love.graphics.setColor(unpack(color))else love.graphics.setColor(1,1,1,1)end;mesh:setTexture(tex or S.white);love.graphics.draw(mesh)
end
local modelPool,modelAt={},0
local function model(base,x,y,z,angle)
 modelAt=modelAt+1;local out=modelPool[modelAt]or{};modelPool[modelAt]=out
 local c,t=math.cos(angle or 0),math.sin(angle or 0)
 for row=0,3 do local k=row*4;out[k+1]=base[k+1];out[k+2]=base[k+2]*c+base[k+3]*t;out[k+3]=-base[k+2]*t+base[k+3]*c;out[k+4]=base[k+1]*x+base[k+2]*y+base[k+3]*z+base[k+4]end
 return out
end
local function transformPoint(m,p)
 return {m[1]*p[1]+m[2]*p[2]+m[3]*p[3]+m[4],m[5]*p[1]+m[6]*p[2]+m[7]*p[3]+m[8],m[9]*p[1]+m[10]*p[2]+m[11]*p[3]+m[12]}
end
local function hangingThreads(scene,panel,transform,lid)
 local v={};local d=panel.def
 for _,point in ipairs(panel.hanging.points)do
  local lower=transformPoint(transform,point)
  local x=math.max(-S.R+2,math.min(S.R-2,ResponsiveLayout.panelX(scene,d)+point[1]))
  local upper=transformPoint(lid,{x,.5,math.sqrt(S.R*S.R-x*x)-.7})
  -- Thin cream thread joins the actual lid rim to the alpha edge of the card.
  local width=.15
  quad(v,vertex(lower[1]-width,lower[2],lower[3]),vertex(lower[1]+width,lower[2],lower[3]),vertex(upper[1]+width,upper[2],upper[3]),vertex(upper[1]-width,upper[2],upper[3]))
 end
 panel.hanging.mesh:setVertices(v)
 draw(panel.hanging.mesh,nil,M.identity(),0,{.86,.82,.69,.91})
end
function S.panelBase(scene,def,base,lid)
 if def.mount~='lid'then return base end
 -- Authored in the fully open pose. Undo that pose, then use the actual
 -- hinge transform so hanging cutouts cannot float independently of the lid.
 local angle=scene.lidAngle or -1.94
 if not scene.inverseOpen or scene.inverseOpenAngle~=angle then
  scene.inverseOpen=M.mul(M.translate(0,0,-S.R),M.mul(M.rotateX(-angle),M.translate(0,0,S.R)));scene.inverseOpenAngle=angle;scene.panelLidSource=nil
 end
 if scene.panelLidSource~=lid then scene.panelLidBase=M.mul(lid,scene.inverseOpen);scene.panelLidSource=lid end
 return scene.panelLidBase
end
function S.panelHeight(def,progress)
 if def.foldBaseY then
  local offset=def.y-def.foldBaseY
  local angle=(1-progress)*math.pi/2*def.direction
  return def.foldBaseY+offset*math.cos(angle),def.z*30+offset*math.sin(angle)
 end
 if not def.support then return def.y or -1.35,def.z*30 end
 local height=def.y+1.35
 -- A rigid rear paper support folds at the floor. Its upper endpoint carries
 -- the elevated scenery, avoiding a floating terrace halfway through opening.
 return -1.35+height*progress,def.z*30-height*math.sqrt(math.max(0,1-progress*progress))
end
-- Geometry and its projected shadow must share the exact folded/moving pose.
-- Compute it once per panel and frame; transient event cards can be absent.
function S.panelPose(scene,p,base,lid)
 local d=p.def;local progress=S.panelProgress(scene,d);local angle=(1-progress)*math.pi/2*d.direction
 -- Floor puzzle pads and water strips remain flat when the stage has unfolded.
 if d.restPitch then angle=angle+d.restPitch*progress end
 -- eventMotion animates a persistent prop; ambientCard is visible only
 -- during its event. A closed door/idle hanging card must remain present.
 local motion=d.ambientCard or d.eventMotion
 local ambientPose=motion and AmbientMotion.cardPose(scene,motion,d)
 if d.ambientCard and not ambientPose then progress=0 end
 if progress<=0 then return nil,progress end
 if d.wave then angle=angle+(math.sin(scene.waterTime*1.10+d.wave)*.044+math.sin(scene.waterTime*.53+d.wave)*.012)*progress end
 if d.sway then angle=angle+(math.sin(scene.waterTime*1.2+d.x)*.042+math.sin(scene.waterTime*.71+d.z)*.016)*progress end
 local rise=d.floatY and math.sin(scene.waterTime*.8+(d.floatPhase or 0))*d.floatY*progress or 0
 local drift=d.driftX and math.sin(scene.waterTime*.19+d.x)*d.driftX*progress or 0
 local panelY,panelZ=S.panelHeight(d,progress)
 local panelX=ResponsiveLayout.panelX(scene,d)
 local transform=model(S.panelBase(scene,d,base,lid),panelX+drift,panelY+rise,panelZ,d.fixedYaw and 0 or angle)
 if d.fixedYaw then transform=M.mul(transform,M.mul(M.rotateY(d.fixedYaw),M.rotateX(angle)))end
 if ambientPose then
  transform=M.mul(transform,M.mul(M.translate(ambientPose.x,ambientPose.y+(d.pivot or 0),ambientPose.z or 0),M.mul(M.fromQuat(0,0,math.sin(ambientPose.spin/2),math.cos(ambientPose.spin/2)),M.translate(0,-(d.pivot or 0),0))))
  if ambientPose.pitch then transform=M.mul(transform,M.mul(M.translate(0,d.pivot or 0,0),M.mul(M.rotateX(ambientPose.pitch),M.translate(0,-(d.pivot or 0),0))))end
  if ambientPose.scale then transform=M.mul(transform,M.scale(ambientPose.scale,ambientPose.scale,1))end
  if ambientPose.turn then transform=M.mul(transform,M.rotateY(ambientPose.turn))end
 end
 if d.turn then transform=M.mul(transform,M.rotateY(math.sin(scene.waterTime*.7+d.x)*d.turn*progress))end
 if d.oscillate or d.eventSway or d.spin then
  local turn=((d.spin or 0)*scene.waterTime+math.sin(scene.waterTime*.65+(d.floatPhase or 0))*(d.oscillate or 0)+(d.eventSway or 0)*AmbientMotion.pulse(scene))*progress
  transform=M.mul(transform,M.mul(M.translate(0,d.pivot or 0,0),M.mul(M.fromQuat(0,0,math.sin(turn/2),math.cos(turn/2)),M.translate(0,-(d.pivot or 0),0))))
 end
 if p.hanging and not d.rigidHanging then
  local turn=(math.sin(progress*math.pi*3)*(1-progress)*.09+math.sin(scene.waterTime*.8+d.x)*.008)*progress
  transform=M.mul(transform,M.mul(M.translate(0,p.hanging.height,0),M.mul(M.fromQuat(0,0,math.sin(turn/2),math.cos(turn/2)),M.translate(0,-p.hanging.height,0))))
 end
 return transform,progress
end
local function panelTexture(scene,p)
 return p.def.texture and S.images[p.def.texture]or(scene.stage and scene.stage.texture or S.images.landscape)
end
function S.pose(scene)
 local t=scene.time
 local entrance=scene.entry=='switch'and 1 or ease((t-.5)/.88)
 local scale=.075+.925*entrance
 local base=M.mul(M.translate((1-entrance)*-84,(1-entrance)*63+math.sin(entrance*math.pi)*15,(1-entrance)*-135),M.scale(scale,scale,scale))
 local lid=M.mul(base,M.mul(M.translate(0,0,-S.R),M.mul(M.rotateX((scene.lidAngle or -1.94)*ease((t-S.OPEN)/1.45)),M.translate(0,0,S.R))))
 local charge=ease((t-1.4)/.6)*(1-ease((t-S.OPEN)/.58))
 return base,lid,charge,scale
end
function S.radiance(time)
 return ease((time-1.68)/.37)*(1-ease((time-2.22)/.85))
end
-- Screen-space bloom follows the actual two 3D rim loops. It intentionally
-- spills over their silhouettes, concealing the cut edge as the latch releases.
local function seamLight(scene,base,lid)
 local strength=S.radiance(scene.time);if strength<=0 then return end
 local project=V.require('Camera').project
 love.graphics.setBlendMode('add','alphamultiply')
 for _,transform in ipairs({base,lid})do
  local m=M.mul(scene.vp,transform);local cx,cy=project(m,0,0,0);cx,cy=cx*240,cy*160
  local loop,vertices={},{}
  for i=0,64 do
   local a=i*math.pi/32;local x,y=project(m,math.cos(a)*S.R,0,math.sin(a)*S.R);x,y=x*240,y*160
   loop[#loop+1]=x;loop[#loop+1]=y
   if i<64 then
    local dx,dy=x-cx,y-cy;local n=math.sqrt(dx*dx+dy*dy);dx,dy=dx/n,dy/n
    local length=(13+25*(.5+.5*math.sin(i*2.399)))*strength
    local width=.8+1.8*(.5+.5*math.cos(i*1.7))
    local function v(px,py,r,g,b,alpha)return{px,py,0,0,r,g,b,alpha}end
    local a0=v(x-dy*width,y+dx*width,.65,.88,1,strength*.45)
    local b0=v(x+dy*width,y-dx*width,.65,.88,1,strength*.45)
    local c0=v(x+dx*length+dy*width*.15,y+dy*length-dx*width*.15,.15,.48,1,0)
    local d0=v(x+dx*length-dy*width*.15,y+dy*length+dx*width*.15,.15,.48,1,0)
    for _,vtx in ipairs({a0,b0,c0,a0,c0,d0})do vertices[#vertices+1]=vtx end
   end
  end
  S.rays=S.rays or love.graphics.newMesh(vertices,'triangles','stream');S.rays:setVertices(vertices)
  love.graphics.setColor(1,1,1,1);love.graphics.draw(S.rays)
  for _,band in ipairs({{8,.08},{4,.18},{1.8,.5},{.65,.95}})do
   love.graphics.setLineWidth(band[1]);love.graphics.setColor(.45,.78,1,band[2]*strength);love.graphics.line(loop)
  end
 end
 love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.setColor(1,1,1,1)
end
local function throwBall(scene,presentation,record)
 if scene.safari then return end
 local x,y=V.require('battle/PaperBattleScene').foot(scene,'player')
 local time=scene.dialogue and scene.dialogue.throwTime or scene.time
 local active=scene.dialogue and scene.dialogue.phase=='throw'or not scene.dialogue and scene.cinematic
 local p=PopupActors.throw(time,'battle',active,presentation.trainerHands and presentation.trainerHands.playerTrainer,{x,y-1})
 if scene.entry=='switch'and scene.cinematic then return end
 if not p then return end
 local Ui=require('src.core.game3.battle.ui');local Anim=require('src.core.game3.battle.anim')
 local img,q=Ui.ballQuad(Anim.ballIdOf('player'),p.landed and 1 or 0)
 if img then
  love.graphics.setColor(1,1,1,p.landed and p.flash or 1)
  love.graphics.draw(img,q,p.x,p.y,p.rot,p.scale,p.scale,8,8)
 end
 if p.landed then
  love.graphics.setBlendMode('add','alphamultiply')
  local radius=2+(1-p.flash)*7
  for i=3,1,-1 do love.graphics.setColor(.45,.8,1,p.flash*.22/i);love.graphics.circle('fill',p.x,p.y,radius*i*.6)end
  love.graphics.setBlendMode('alpha','alphamultiply')
 end
 love.graphics.setColor(1,1,1,1)
end
function S.drawIntroOverlay(presentation,record)
 if record.scene.dialogue then throwBall(record.scene,presentation,record)end
end
local function actors(scene)
 local time=scene.dialogue and scene.dialogue.throwTime or scene.time
 if scene.dialogue then
  if scene.dialogue.throwTime and time>=PopupActors.RELEASE then scene.popupBallThrown=true end
 elseif scene.entry=='battle'and scene.time>=PopupActors.RELEASE then scene.popupBallThrown=true end
 scene.actorVisible={};scene.actorFold={};scene.actorLean={}
 for side,p in pairs(scene.rest)do
  local progress=PopupActors.progress(side,scene.time,scene.entry,scene.cinematic)
  if scene.double and scene.fast and scene.cinematic and scene.entry=='battle'then progress=ease((scene.elapsed-scene.timing.actor)/scene.timing.actorFold)end
  if scene.fast and scene.cinematic and scene.entry=='switch'then progress=ease((scene.elapsed-.25)/.15)end
  if scene.dialogue then
   local staged=progress
   progress=scene.dialogue[side]or 0
   if scene.cinematic then
    if scene.entry=='switch'then progress=math.min(progress,staged)
    elseif scene.fast then progress=math.min(progress,ease((scene.elapsed-scene.timing.actor)/scene.timing.actorFold))
    else progress=0 end
   end
  elseif require('src.core.game3.battle')._phase=='intro'then
   -- Trainer battles and live view switches retain native send-out ownership.
   -- An authored wall-clock fold must never reveal an unannounced Pokemon.
   local anim=require('src.core.game3.battle.anim')
   local id=Slots.id(side)
   if id~=nil then
    local native=anim.present(id)
    if not native or native.visible==false or native.invisible or native.battlerInvisible then progress=0 end
   else
    -- Partner portraits share their side's native trainer controller.
    local key=side:sub(1,6)=='player'and'player'or'enemy'
    local native=anim.stage().trainer[key]
    if not native or not native.visible then progress=0 end
   end
  end
  scene.actorVisible[side]=progress>0
  scene.actorFold[side]=progress
  scene.actorLean[side]=PopupActors.lean(side,time,'battle',scene.dialogue and scene.dialogue.phase=='throw'or not scene.dialogue and scene.cinematic and scene.entry=='battle')
  scene.feet[side][1]=p[1];scene.feet[side][2]=p[3];scene.ground[side]=p[2]
 end
end
local function ambientDetails(scene,base)
 local details=AmbientMotion.samples(scene)
 for _,p in ipairs(AmbientMotion.continuous(scene))do details[#details+1]=p end
 for _,p in ipairs(details)do
  if p.kind=='kyogre'and scene.stage and scene.stage.basin and S.images.kyogre then
   local transform=M.mul(M.mul(base,M.translate(p.x,p.y,p.z)),M.mul(M.rotateY(p.spin),M.scale(p.size,1,p.size)))
   love.graphics.setDepthMode('lequal',false);draw(S.seaShadow,S.images.kyogre,transform,0,{1,1,1,p.alpha});love.graphics.setDepthMode('less',true)
  elseif p.kind=='waterRipple'then
   -- Rings lie on the actual flat water surface, so rocks and piers occlude
   -- them naturally. No upright bubble rings or decals across dry platforms.
   local transform=M.mul(model(base,p.x,p.y,p.z,-math.pi/2),M.scale(p.size,p.size,1))
   -- A fading ring must not punch an invisible depth hole in later rings.
   love.graphics.setDepthMode('lequal',false)
   draw(S.waterRipple,S.images.pale,transform,0,{.80,.96,.96,p.alpha})
   love.graphics.setDepthMode('less',true)
  elseif p.kind~='kyogre'then
   local turn=M.fromQuat(0,0,math.sin(p.spin/2),math.cos(p.spin/2))
   local transform=M.mul(model(base,p.x,p.y,p.z),M.mul(turn,M.scale(p.size,p.size,1)))
   local color=p.kind=='leaf'and{.49,.60,.25,p.alpha}or p.kind=='wisp'and{.95,.95,.87,p.alpha}or p.kind=='smoke'and{.85,.86,.81,p.alpha}or p.kind=='steam'and{.86,.94,.92,p.alpha}or p.kind=='spark'and{.75,.94,1,p.alpha}or p.kind=='bubble'and{.70,.94,1,p.alpha}or p.kind=='star'and{.62,.80,1,p.alpha}or{.72,.64,.52,p.alpha}
   if p.kind=='healLight'then color={1,.52,.58,p.alpha}elseif p.kind=='receipt'then color={.97,.94,.82,p.alpha}elseif p.kind=='ember'then color={1,.48,.11,p.alpha}elseif p.kind=='salt'then color={.93,.91,.83,p.alpha}end
   draw((p.kind=='bubble'or p.kind=='healLight')and S.bubble or p.kind=='receipt'and S.steam or p.kind=='star'and S.star or p.kind=='spark'and S.spark or(p.kind=='steam'or p.kind=='wisp')and S.steam or p.kind=='leaf'and S.digChip or S.pebble,S.images.pale,transform,0,color)
  end
 end
end
local function digGround(scene,presentation,record,base)
 for side,d in pairs(record.dig or{})do
  local sample=d.sample;local foot=scene.rest[side]
  if sample and sample.hole>0 and foot then
   local b=Slots.battler(record.battle,side);local species=b and(b.species or b.mon and b.mon.species)
   local radius=math.max(4.8,math.min(16,presentation:height(species)*.55))*math.sqrt(sample.hole)
   -- The sea caps are illustrated on upright paper cards. A world-horizontal
   -- hole intersects that card and loses its rear half to the depth buffer.
   -- Attach the elliptical cutout to the cap's paper plane instead; keep depth
   -- testing so actors and foreground scenery still overlap it normally.
   local paperCap=scene.stage and(scene.stage.sea or scene.stage.paperCaps)
   local angle=paperCap and 0 or -math.pi/2
   local squash=paperCap and .36 or .78
   local ground=model(base,foot[1],foot[2]+.08,foot[3],angle)
   draw(S.digHole,nil,M.mul(ground,M.scale(radius,radius*squash,1)),0,{.18,.11,.065,1})
   local rim=model(base,foot[1],foot[2]+(paperCap and .08 or .12),foot[3]+(paperCap and .04 or 0),angle)
   draw(S.digRim,S.images.pale,M.mul(rim,M.scale(radius,radius*squash,1)),0,{.69,.44,.23,1})
   if d.phase=='down'or d.phase=='up'then
    for i=1,7 do
     local t=(d.age*2.6+i*.137)%1;local a=i*2.399
     local distance=radius*(.7+t*.9)
     local chip=model(base,foot[1]+math.cos(a)*distance,
      foot[2]+math.sin(t*math.pi)*4.5+.15+(paperCap and math.sin(a)*distance*squash or 0),
      foot[3]+(paperCap and .15 or math.sin(a)*distance*.78),-t*math.pi)
     draw(S.digChip,S.images.pale,M.mul(chip,M.scale(1.1,1.1,1.1)),0,{.67,.44,.24,(1-t)*sample.hole})
    end
   end
  end
 end
end
function S.render(game,scene,width,height,presentation,record)
 modelAt=0;depthAt=0;depthChanged=depthOwner~=scene;depthOwner=scene;depthFlow=scene.waterTime
 if V.require('WorldAdapter').current(game)~=scene.map then return nil,'map changed during battle'end
 -- Match the physical window and supersample paper edges; the old 3x
 -- scenery canvas was enlarged again when presented at desktop resolution.
 local fit=require('src.render.Renderer'):fitScale()
 local size=V.require('battle/BattleResolution').scenery(fit)
 local w,h=math.floor(width*size),math.floor(height*size)
 if not S.canvas or S.canvas:getWidth()~=w or S.canvas:getHeight()~=h then
  if S.canvas then S.canvas:release();S.depth:release()end
  if S.waterCopy then S.waterCopy:release();S.waterCopy=nil end
  S.canvas=love.graphics.newCanvas(w,h,{dpiscale=1});S.canvas:setFilter('nearest','nearest')
  S.depth=love.graphics.newCanvas(w,h,{format='depth24',readable=true,dpiscale=1});S.depth:setFilter('nearest','nearest')
 end
 actors(scene);presentation:prepare(record)
 for side,pop in pairs(record.nativePops or{})do
  if pop.battler==Slots.battler(record.battle,side)then
   scene.actorVisible[side]=true;scene.actorFold[side]=ease(pop.age/.45)
   presentation:prepareIntro(record,{side})
  end
 end
 scene.actorFall={}
 for side,f in pairs(record.faints or{})do
  if not f.complete and f.battler==Slots.battler(record.battle,side)then
   scene.actorFall[side]=true;scene.actorFold[side]=PopupActors.faintFold(f.progress)
   presentation:prepareIntro(record,{side},'faint')
  end
 end
 if presentation:replacesIntro(record)then presentation:prepareIntro(record)end
 if not presentation:replacesIntro(record)then
  for side,m in pairs(record.spawnMotion or{})do if not m.done and not(record.faints and record.faints[side])then presentation:prepareIntro(record,{side})end end
 end
 for side in pairs(record.dig or{})do if not(record.faints and record.faints[side]and not record.faints[side].complete)then presentation:prepareIntro(record,{side},'dig')end end
 -- Capture the fully spawned, neutral actors once. Later replacements,
 -- attacks, window resizes and view switches must never trigger a reframe.
 if not scene.autoZoomChosen and not scene.autoZoomManual and scene.zoomPreference==1
  and V.mod.options:get('gen3TerrariumAutoZoom')~=false and not scene.cinematic
  and require('src.core.game3.battle.ui').waitingForCommand()then
  local complete=true
  for side in pairs(scene.feet)do
   if scene.actorVisible[side]and(scene.actorFold[side]or 1)<.999 then complete=false end
  end
  for _,motion in pairs(record.spawnMotion or{})do if not motion.done then complete=false end end
  if complete then
   local target=AutoFrame.choose(presentation.bounds,scene.actorVisible)
   if target then
    scene.autoZoomChosen=true;scene.autoZoomFrom=scene.zoom or 1
    scene.autoZoomTarget=target;scene.autoZoomAge=0;scene.autoZoomChoice=target
   end
  end
 end
 local atmosphere={ambient={1,1,1},lights={}}
 if V.mod.options:get('gen3Lights')~=false then presentation:lights(record,atmosphere)else presentation.battleLightCount=0 end
 local positions,colors={},{}
 for i=1,4 do local l=atmosphere.lights[i];positions[i]=l and{l.x,l.y,l.z,math.abs(l.radius)}or{0,0,0,1};colors[i]=l and{l.color[1],l.color[2],l.color[3],l.power}or{0,0,0,0}end
 S.shader:send('lightCount',#atmosphere.lights);S.shader:send('lightPosition',unpack(positions));S.shader:send('lightColor',unpack(colors))
 love.graphics.setCanvas({S.canvas,depthstencil=S.depth});love.graphics.origin();love.graphics.setScissor();love.graphics.clear(0,0,0,0,0,1)
 love.graphics.setDepthMode('less',true);love.graphics.setMeshCullMode('none');love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.setShader(S.shader)
 local base,lid,charge,scale=S.pose(scene)
 local panelPoses=scene.panelPoses or{};scene.panelPoses=panelPoses
 for _,p in ipairs(scene.stage and scene.stage.panels or S.panels)do
  local transform,progress=S.panelPose(scene,p,base,lid)
  local row=panelPoses[p]or{};panelPoses[p]=row;row.transform,row.progress=transform,progress
 end
 local platform=scene.stage and scene.stage.platform
 local pd=platform and platform.def
 S.shader:send('stageDock',scene.stage and scene.stage.dock and 1 or 0)
 S.shader:send('stagePlatform',pd and{pd.x,pd.z,pd.radius,pd.height}or{0,0,0,0})
 S.shader:send('vp','row',scene.vp);S.shader:send('eye',scene.eye);S.shader:send('battleSpritePass',0);S.shader:send('battleDepthTest',0);S.shader:send('popupSpriteFold',0);S.shader:send('shadowPass',0);S.shader:send('seaMode',scene.stage and scene.stage.basin and 1 or 0);S.shader:send('flow',scene.waterTime);S.shader:send('charge',charge)
 if scene.time>.5 then
  draw(S.bottom,S.images.shell,base)
  draw(S.top,S.images.shell,lid)
  local sea=scene.stage and scene.stage.sea
  draw(S.inside,sea and S.images.pale or nil,lid,0,sea and{.29,.67,.81,1}or{.17,.16,.15,1})
  for _,m in ipairs(sea and S.seaMirrors or S.mirrors)do draw(m,nil,lid,2)end
  draw(S.rim,nil,model(base,0,0,0,-math.pi/2),0,{.2,.18,.17,1})
  draw(S.band,nil,base,0,{.16,.15,.14,1})
  draw(S.collar,S.images.pale,base,0,{.42,.35,.25,1})
  draw(S.rim,nil,model(lid,0,0,0,-math.pi/2),0,{.2,.18,.17,1})
  if scene.stage and scene.stage.basin then draw(S.seaFloor,scene.stage.floor,base)
  else draw(scene.stage and scene.stage.floorMesh or S.floor,scene.stage and scene.stage.floor or S.images.floor,model(base,0,-2.25,0,-math.pi/2),scene.stage and(scene.stage.floorLava and 15 or scene.stage.floorFrost and 16 or scene.stage.floorFlow and 14)or 0)end
  if scene.stage and scene.stage.dock then
   draw(scene.stage.dock.top,scene.stage.dock.texture,base)
   draw(scene.stage.dock.side,S.images.pale,base,0,{.67,.54,.37,1})
  end
  if platform then
   if platform.wood then
    local wood=platform.wood;local frame=model(base,pd.x,0,pd.z)
    draw(wood.faces,platform.texture,frame);draw(wood.posts,platform.texture,frame)
    if wood.braces then draw(wood.braces,platform.texture,frame)end
    draw(wood.edges,S.images.pale,frame,0,{.76,.64,.44,1})
   else draw(platform.side,S.images.pale,model(base,pd.x,0,pd.z),0,pd.sideTint or{.86,.79,.62,1})end
   if platform.ledges then
    draw(platform.ledges,S.images.pale,model(base,pd.x,0,pd.z),0,{.69,.79,.76,1})
    draw(platform.seams,S.images.pale,model(base,pd.x,0,pd.z),0,{.86,.82,.69,1})
   end
   draw(platform.top,platform.texture,model(base,pd.x,pd.height,pd.z,-math.pi/2),pd.frost and 16 or 0)
  end
  if V.mod.options:get('gen3Shadows')~=false then
   S.shader:send('shadowPass',1);love.graphics.setDepthMode('lequal',false)
   -- Three nearby samples soften short cut-paper shadows, with a common
   -- light from front-left. The circular floor clips their outer extent.
   for _,off in ipairs({{0,0},{.65,.4},{-.65,-.4}})do
    S.shader:send('shadowOffset',off)
    for _,p in ipairs(scene.stage and scene.stage.panels or S.panels)do local d=p.def
     local transform=panelPoses[p].transform
     if d.z>=1 and not d.ambientCard and transform then
      draw(p.front,panelTexture(scene,p),transform,0,{1,1,1,.09})
     end
    end
    presentation:shadowCasters(record,function(mesh,tex)draw(mesh,tex,base,0,{1,1,1,.09})end)
   end
   S.shader:send('shadowPass',0);love.graphics.setDepthMode('less',true)
  end
  local button=model(base,0,-12.9,math.sqrt(S.R*S.R-12.9*12.9)+.36,.126)
  draw(S.buttonHalo,nil,button,0,{.16,.15,.14,1});draw(S.buttonFace,S.images.paper,model(button,0,0,.75))
  if (scene.idlePulse or 0)>.002 then
   local pulse=scene.idlePulse
   draw(S.buttonFace,S.images.paper,model(button,0,0,1.3),0,{.93-.82*pulse,.90-.38*pulse,.83+.17*pulse,1})
  end
  for _,p in ipairs(scene.stage and scene.stage.panels or S.panels)do
   local d=p.def;local pose=panelPoses[p];local transform,progress=pose.transform,pose.progress
   if transform then
   if p.supports then draw(p.supports,S.images.pale,model(base,ResponsiveLayout.panelX(scene,d),-1.35,d.z*30,-math.acos(progress)),0,{.72,.65,.50,1})end
   if p.hanging then hangingThreads(scene,p,transform,lid)end
   draw(p.back,d.cutout and panelTexture(scene,p)or S.images.pale,transform,d.cutout and not d.doubleSidedArt and 5 or 0,d.doubleSidedArt and{1,1,1,1}or{.84,.8,.72,1})
   local effect=d.ripple or d.glow
   if effect then S.shader:send('paperEffectArea',effect);S.shader:send('paperPulse',AmbientMotion.pulse(scene))end
   if d.haunt or d.runes or d.signal then S.shader:send('paperPulse',AmbientMotion.pulse(scene))end
   draw(p.front,panelTexture(scene,p),transform,d.warmSignal and 20 or d.psychic and 21 or d.mutedWater and 19 or d.rain and 17 or d.metal and 18 or d.lava and 15 or d.frost and 16 or d.runes and 13 or d.haunt and 12 or d.ripple and 6 or d.glow and 7 or d.lamps and 8 or d.flowing and 9 or d.signal and 10 or d.warm and 11 or d.water and 3 or 0,d.paperTint)
   if p.edge then draw(p.edge,nil,transform,0,{.79,.73,.61,1})end
   end
  end
  if scene.stage and scene.stage.basin then
   love.graphics.setDepthMode('lequal',false)
   for i=1,7 do
    local t=(scene.waterTime*.12+i*.137)%1;local x=(i%2==0 and -1 or 1)*(43+i*2)
    draw(S.bubble,nil,M.mul(model(base,x+math.sin(t*6+i),-38+t*35,-28+i*3),M.scale(.3+t*.4,.4+t*.4,1)),0,{.66,.91,.93,math.sin(t*math.pi)*.30})
   end
   love.graphics.setDepthMode('less',true)
  end
  ambientDetails(scene,base)
  digGround(scene,presentation,record,base)
  if scene.stage and scene.stage.basin then
   if not S.waterCopy then S.waterCopy=love.graphics.newCanvas(w,h,{dpiscale=1});S.waterCopy:setFilter('linear','linear')end
   love.graphics.push('all');love.graphics.setCanvas(S.waterCopy);love.graphics.origin();love.graphics.setShader();love.graphics.setDepthMode()
   love.graphics.setBlendMode('replace');love.graphics.setColor(1,1,1,1);love.graphics.draw(S.canvas);love.graphics.pop()
   S.shader:send('waterScene',S.waterCopy)
   love.graphics.setDepthMode('lequal',false)
   draw(S.waterSurface,nil,model(base,0,-1.8,0,-math.pi/2),4,{1,1,1,ease((scene.time-2.1)/1.3)})
   love.graphics.setDepthMode('less',true)
  end
  if charge>0 then
   love.graphics.setBlendMode('add','alphamultiply');love.graphics.setDepthMode('lequal',false)
   draw(S.band,nil,M.mul(base,M.scale(1.004,.25,1.004)),0,{.25,.72,1,charge})
   draw(S.buttonRing,nil,model(button,0,0,1.2),0,{.3,.82,1,charge})
   draw(S.buttonFace,nil,model(button,0,0,1.4),0,{.2,.65,1,charge*.65})
   love.graphics.setBlendMode('alpha','alphamultiply')
  end
 end
 S.shader:send('model','row',M.identity());S.shader:send('material',0)
 if depthAt~=#depthRows then depthChanged=true;for i=#depthRows,depthAt+1,-1 do depthRows[i]=nil end end
 if depthChanged then scene.depthRevision=(scene.depthRevision or 0)+1 end
 presentation:drawLayers(record,S.shader,scene.vp,S.depth,w,h,atmosphere,{count=#atmosphere.lights})
 if scene.cinematic then
  love.graphics.setCanvas(S.canvas);love.graphics.origin();love.graphics.setShader();love.graphics.setDepthMode();love.graphics.setScissor();love.graphics.setColor(1,1,1,1)
  love.graphics.scale(w/240,h/160)
  seamLight(scene,base,lid)
  if not scene.nativeIntroVisible then
   for _,side in ipairs(Slots.actorKeys)do if scene.actorVisible[side]then presentation:blit(side)end end
   throwBall(scene,presentation,record)
  end
  if scene.entry=='battle'and scene.elapsed<scene.timing.arrival then
   -- Continue the field's black fade into the opening paper stage. A second
   -- white screen flash conflicts with MAP/terrarium's stationary entrance.
   local opacity=1-ease(scene.elapsed/scene.timing.arrival)
   love.graphics.setBlendMode('alpha','alphamultiply');love.graphics.setColor(0,0,0,opacity);love.graphics.rectangle('fill',0,0,240,160)
  end
 end
 local stageCount=0;for _ in pairs(S.stages or{})do stageCount=stageCount+1 end
 S.stats={stageCount=stageCount,artStatus=scene.artStatus,artKey=scene.artKey,habitat=scene.habitat,map=scene.map,mode='terrarium',edition=scene.edition,entry=scene.entry,time=scene.time,scale=scale,charge=charge,cinematic=scene.cinematic,sounds=scene.soundCount,meshes=#S.meshes,renderWidth=w,renderHeight=h,zoom=scene.zoom,autoZoom=scene.autoZoomChoice,autoZoomSettled=scene.autoZoomSettled}
 return S.canvas
end
function S.release()
 clearDecoded();componentCache={}
 idleSound.release()
 for _,m in ipairs(S.meshes or{})do m:release()end
 for _,img in pairs(S.images or{})do img:release()end
 for _,key in ipairs({'shader','white','canvas','depth','rays','waterCopy'})do if S[key]then S[key]:release();S[key]=nil end end
 S.stageClock=nil;S.meshes,S.images,S.panels,S.stats,S.stages=nil,nil,nil,nil,nil
end
return S
