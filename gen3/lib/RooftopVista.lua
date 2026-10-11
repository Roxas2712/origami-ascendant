-- Distant context for accessible FireRed roofs. Native city artwork is read
-- from the imported atlas once; no map switch, collision or event is changed.
local V=...
local R={cache={}}
local profiles={
 FR_CELADON_CITY_DEPARTMENT_STORE_ROOF={city='FR_CELADON_CITY',pair='building__rom_082d4e6c',width=20,height=14},
 FR_TRAINER_TOWER_ROOF={coast=true,pair='building__rom_082d5094',width=18,height=16},
 FR_CELADON_CITY_CONDOMINIUMS_ROOF={city='FR_CELADON_CITY',condo=true,pair='building__rom_082d4f8c',width=14,height=24},
}
function R.profile(def)
 if V.require('DioramaConfig').rooftopVista.enabled==false then return end
 local p=def and profiles[def.id or def.name];local L=def and def.midLayout
 if p and L and (def.renderPair or def.pair)==p.pair and L.width==p.width and L.height==p.height then return p end
end

-- This roof retains the existing furniture/deck pass. Only its non-walkable
-- native facade rows are folded down, with identical tile UVs on each storey.
function R.extendCondo(out,def,ts,ox,oz)
 local p=R.profile(def);local L=def and def.midLayout
 if not(p and p.condo and L.width==14 and L.height==24 and (def.renderPair or def.pair)=='building__rom_082d4f8c')then return end
 local G=V.require('WorldGeometry');local result={};ox=(ox or 0)*16;oz=(oz or 0)*16
 for i=1,#out,6 do
  local facade,sky=true,true
  for j=i,i+5 do local v=out[j];local z=v[3]-oz
   facade=facade and v[2]==0 and z>=304 and z<=368
   sky=sky and v[2]==0 and(z>=368 or z<=16)
  end
  if facade then
   for floor=0,3 do for j=i,i+5 do local v=out[j];local a={};for k,n in ipairs(v)do a[k]=n end
    a[2]=-(v[3]-oz-304)-floor*64;a[3]=oz+304;a[6]=G.HANGING_FACADE;result[#result+1]=a
   end end
  elseif not sky then for j=i,i+5 do result[#result+1]=out[j]end end
 end
 for i=#out,1,-1 do out[i]=nil end;for i,v in ipairs(result)do out[i]=v end
 for _,x in ipairs{0,224}do for z=16,288,16 do for floor=0,3 do for row=0,3 do
  local y=-floor*64-row*16;local m=L:midAt(1,19+row)
  G.quad(out,{ox+x,y,oz+z},{ox+x,y,oz+z+16},{ox+x,y-16,oz+z+16},{ox+x,y-16,oz+z},G.uv(ts,m),G.HANGING_FACADE)
 end end end end
end

function R.prepare(def,game)
 local p=R.profile(def);if not p or R.cache[p]then return end
 local art={};R.cache[p]=art
 if not p.city then return end
 local Map=require('src.core.game3.map');local d=game.data.maps[p.city]
 if not d then return end
 Map.ensureMidLayout(game,p.city,d);d=V.require('NativeTilesetIdentity').resolve(d)
 local ts=V.require('WorldAdapter').Native.get(d.pair);if not ts then return end
 local BM=V.require('BuildingMesh');local L=d.midLayout;local Shapes=V.data('Shapes')
 local im=love.image.newImageData(L.width*16,L.height*16)
 -- Reuse the window texture: RG describe exposed ground/roof and foliage;
 -- alpha still owns glass. This is prepared once, not rebuilt each frame.
 local mask=love.image.newImageData(L.width*16,L.height*16)
 for ty=0,L.height-1 do for tx=0,L.width-1 do
  local cell=L:cellAt(tx,ty);local prop=Shapes.prop(d,cell);local mid=L:midAt(tx,ty)
  local plant=Shapes.tree(cell.mid,d)or prop=='shrub'or prop=='flower'or prop=='grass'
  local ground=not Shapes.water(cell)and not Shapes.solid(cell)and not prop and not plant
  for y=ty*16,ty*16+15 do for x=tx*16,tx*16+15 do
   local r,g,b,a=BM.pixel(ts,mid,x%16,y%16)
   im:setPixel(x,y,r,g,b,a)
   mask:setPixel(x,y,ground and 1 or 0,plant and 1 or 0,0,0)
  end end
 end end
 art.city=love.graphics.newImage(im);art.city:setFilter('linear','linear');im:release()
 for _,b in ipairs(V.require('WorldGeometry').buildings(d))do
  local sp,params=BM.sprite(b,L,ts,true);local _,glass=V.require('LocalLights').windows(sp,params)
  for k,inside in pairs(sp.inside)do if inside or glass[k]then
   local row=math.floor(k/sp.W)
   local x=b.x0*16+k%sp.W;local y=math.max(0,b.y0-1)*16+row
   local roof=row<params.roofRows and not glass[k]and not sp.roofGlass[k]
   if x>=0 and y>=0 and x<L.width*16 and y<L.height*16 then mask:setPixel(x,y,roof and 1 or 0,0,0,glass[k]and 1 or 0)end
  end end
  -- A glass pixel may sit outside the native silhouette (authored overrides).
  for k in pairs(glass)do
   local x=b.x0*16+k%sp.W;local y=math.max(0,b.y0-1)*16+math.floor(k/sp.W)
   if x>=0 and y>=0 and x<L.width*16 and y<L.height*16 then mask:setPixel(x,y,0,0,0,1)end
  end
 end
 art.windows=love.graphics.newImage(mask);art.windows:setFilter('linear','linear');mask:release()

end
function R.snow()
 local cfg=V.require('DioramaConfig')
 local cover=cfg.weather.enabled and(V.require('Weather').visual.snow or 0)*cfg.weather.snow.cover or 0
 return cover,V.require('SeasonalFoliage').setting:get()~='original'and cover or 0
end
-- The sky and distant city follow the same easing front as the foreground.
-- Reading the requested weather directly caused a one-frame sky change.
function R.atmosphere(def,time,weather)
 local C=V.require('CloudDaylight')
 local mood=V.require('WeatherMood').sample({id=def.id or def.name,def=def})
 if mood then
  return C.cover(time,weather,C.setting:get(),mood.cloud),mood.tint,.70+.30*mood.sky
 end
 return ({rain=.8,storm=1,fog=.95,snow=.85})[weather]or C.cover(time,'clear','living'),{1,1,1},1
end
local sky=[[
uniform float night;
uniform float cloud;
uniform float clock;
uniform float coastal;
uniform vec3 weatherTint;
uniform float skyFill;
uniform float snow;
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 sc){
 vec3 top=mix(vec3(.32,.57,.77),vec3(.025,.039,.085),night);
 vec3 horizon=mix(vec3(.80,.84,.78),vec3(.12,.16,.24),night);
 vec3 col=mix(top,horizon,smoothstep(0.0,.53,uv.y));
 float bank=sin(uv.x*9.0+clock*.006)*.025+sin(uv.x*21.0-clock*.003)*.012;
 float cloudBand=smoothstep(.08,.15,uv.y-bank)*(1.0-smoothstep(.23,.35,uv.y-bank));
 col=mix(col,mix(vec3(.80,.84,.86),vec3(.15,.18,.26),night),cloudBand*cloud*.5);
 float land=sin(uv.x*11.0)*.013+sin(uv.x*29.0)*.007;
 vec3 ground=mix(vec3(.44,.53,.49),vec3(.065,.10,.13),night);
 vec3 snowLand=mix(vec3(.72,.79,.83),vec3(.12,.17,.24),night);
 ground=mix(ground,snowLand,snow);
 if(coastal>.5)ground=mix(vec3(.30,.54,.65),vec3(.045,.10,.18),night);
 col=mix(col,ground,smoothstep(.38+land,.40+land,uv.y));
 if(coastal>.5){
  float island=(1.0-smoothstep(.0,.27,abs(uv.x-.18)))*(1.0-smoothstep(.395,.47,uv.y));
  vec3 islandLand=mix(vec3(.42,.51,.47),vec3(.075,.11,.14),night);
  col=mix(col,mix(islandLand,snowLand,snow),island*step(.4,uv.y));
  float ripple=sin(uv.y*480.0+sin(uv.x*15.0)+clock*.22)*.009;
  col+=ripple*smoothstep(.46,.70,uv.y)*(1.0-night*.7);
 }
 return vec4(col*weatherTint*skyFill,1.0)*c;
}
]]
local distant=[[
uniform float night;
uniform vec2 parallax;
uniform Image windows;
uniform vec3 weatherTint;
uniform float skyFill;
uniform float snow;
uniform float leafSnow;
vec4 effect(vec4 c,Image tex,vec2 uv,vec2 sc){
 float depth=clamp((uv.y-.33)/.67,0.0,1.0);
 vec2 q=vec2(.5+(uv.x-.5)*mix(1.35,.72,depth),depth)+parallax;
 vec4 p=Texel(tex,clamp(q,vec2(.001),vec2(.999)));
 vec4 surface=Texel(windows,clamp(q,vec2(.001),vec2(.999)));
 if(snow>0.0){
  float detail=dot(p.rgb,vec3(.2126,.7152,.0722));
  vec3 snowGround=vec3(.80,.87,.94)*(.72+.28*detail);
  float leaf=smoothstep(.015,.09,p.g-max(p.r,p.b));
  float deposit=(.38+.62*smoothstep(.16,.65,detail))*clamp(leafSnow*1.3,0.0,1.0);
  p.rgb=mix(p.rgb,snowGround,surface.r*clamp(snow,0.0,1.0)*.85);
  p.rgb=mix(p.rgb,vec3(.86,.91,.97)*(.55+.45*detail),surface.g*leaf*deposit);
 }
 vec3 haze=mix(vec3(.61,.69,.69),vec3(.075,.12,.18),night);
 vec3 lit=p.rgb*mix(vec3(.82,.88,.87),vec3(.17,.22,.32),night);
 lit=mix(lit,vec3(.75,.60,.30),surface.a*night);
 float fade=mix(.82,.40,depth);
 float bounds=smoothstep(0.0,.06,q.x)*(1.0-smoothstep(.94,1.0,q.x));
 float alpha=smoothstep(.0,.16,depth)*bounds;
 return vec4(mix(lit,haze,fade)*weatherTint*skyFill,alpha)*c;
}
]]
function R.draw(def,w,h,px,pz,time,weather)
 local p=R.profile(def);if not p then return end
 local g=love.graphics;local n=V.require('DayNight').windowLight()
 if not R.sky then R.sky=V.require('ShaderCompiler').newShader(sky);R.distant=V.require('ShaderCompiler').newShader(distant)end
 local cloud,tint,fill=R.atmosphere(def,time,weather)
 local snow,leafSnow=R.snow()
 g.push('all');g.origin();g.setDepthMode();g.setShader(R.sky);g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1)
 R.sky:send('night',n);R.sky:send('cloud',cloud);R.sky:send('clock',time);R.sky:send('coastal',p.coast and 1 or 0)
 R.sky:send('weatherTint',tint);R.sky:send('skyFill',fill)
 R.sky:send('snow',snow)
 -- A normalized quad supplies UV coordinates to the sky, independent of DPI.
 if not R.pixel then local im=love.image.newImageData(1,1);im:setPixel(0,0,1,1,1,1);R.pixel=g.newImage(im);im:release()end
 g.draw(R.pixel,0,0,0,w,h)
 local art=R.cache[p]
 if p.city and art and art.city then
  g.setBlendMode('alpha','alphamultiply');g.setShader(R.distant)
  R.distant:send('night',n);R.distant:send('windows',art.windows);R.distant:send('parallax',{(px-160)*.00003,(pz-100)*.00002})
  R.distant:send('weatherTint',tint);R.distant:send('skyFill',fill)
  R.distant:send('snow',snow);R.distant:send('leafSnow',leafSnow)
  g.setColor(1,1,1,1);g.draw(art.city,0,0,0,w/art.city:getWidth(),h/art.city:getHeight())
 end
 g.pop()
end
function R.release()
 for _,art in pairs(R.cache)do if art.city then art.city:release();art.windows:release()end end;R.cache={}
 for _,k in ipairs{'sky','distant','pixel'}do if R[k]then R[k]:release();R[k]=nil end end
end
return R
