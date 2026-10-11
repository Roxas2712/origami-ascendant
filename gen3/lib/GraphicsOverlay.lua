-- F7 live graphics controls with Origami's folded-paper inspector.
-- Every row persists as a normal mod option (ModSetting) so the choice
-- survives restarts; existing quality/effect switches are written through
-- to the same options the ASCENDANT menu uses, so both views agree.
local V=...
local ModSetting=V.require('ModSetting')
local O={open=false,cursor=1}

local function opt(key,label,values,labels,default)return ModSetting.new(key,label,values,labels,default)end
local function angle(key,label,default)
 local values={24,36,50}
 return opt(key,label,values,{'24 DEG','36 DEG','50 DEG'},default):normalizeWith(function(value)
  local n=tonumber(value)
  if not n or n~=n then return default end
  local best,distance=default,math.huge
  for _,v in ipairs(values)do
   local d=math.abs(n-v)
   if d<distance then best,distance=v,d end
  end
  return best
 end)
end
local rows={
 {id='tilt',label='TILT ANGLE',s=angle('gen3OvTilt','TILT ANGLE',50)},
 {id='battle_tilt',label='BATTLE ANGLE',s=angle('gen3BattleTilt','BATTLE ANGLE',24)},
 {id='terrain',label='TERRAIN POP',s=opt('gen3OvTerrain','TERRAIN POP',{'off','normal','tall'},{'OFF','NORMAL','TALL'},'normal')},
 {id='post',label='POST FX',s=opt('gen3OvPost','POST FX',{'off','bloom','full'},{'OFF','BLOOM','FULL'},'full')},
 {id='bloom',label='BLOOM STRENGTH',s=opt('gen3OvBloom','BLOOM STRENGTH',{.04,.08,.16,.32},{'5','10','20','40'},.08)},
 {id='tilt_shift',label='TILT SHIFT',s=opt('gen3OvTiltShift','TILT SHIFT',{'off','subtle','strong'},{'OFF','SUBTLE','STRONG'},'strong')},
 {id='shadows',label='SHADOWS',s=opt('gen3OvShadows','SHADOWS',{true,false},{'ON','OFF'},true)},
 {id='clouds',label='CLOUDS',s=opt('gen3OvClouds','CLOUDS',{true,false},{'ON','OFF'},true)},
 {id='lighting',label='LIGHTING',s=nil},
 {id='cloudlight',label='WOLKENLICHT',s=V.require('CloudDaylight').setting},
 {id='windows',label='FENSTERLEBEN',s=V.require('WindowVariation').setting},
 {id='seasons',label='JAHRESZEITEN',s=V.require('SeasonalFoliage').setting},
 {id='atmosphere',label='ATMOSPHERE',s=opt('gen3OvAtmosphere','ATMOSPHERE',{true,false},{'ON','OFF'},true)},
 {id='texture',label='DYNAMIC TEXTURE',s=opt('gen3OvTexture','DYNAMIC TEXTURE',{true,false},{'ON','OFF'},true)},
}
-- LIGHTING drives the existing day/night row: CYCLE runs the saved-time clock.
local lightValues={'native','dawn','day','golden','dusk','night'}
local lightLabels={'CYCLE','MORNING','DAY','EVENING','DUSK','NIGHT'}

local base
local function snapshot(c)
 if base then return end
 base={cocNear=c.post.coc.near,cocFar=c.post.coc.far,elev=c.camera.elevationDegrees,top=c.post.blurStrength,bottom=c.post.bottomBlurStrength,edge=c.post.edgeBlurStrength,
  ledge=c.terrain.ledgeHeight,cliff=c.terrain.cliffHeight,wall=c.terrain.caveWallHeight,
  heights={}}
 for k,v in pairs(c.trees.pairStyle or {})do base.heights['p'..k]=v.heightScale end
 base.heights.default=c.trees.defaultStyle and c.trees.defaultStyle.heightScale
 base.heights.forest=c.trees.forestStyle and c.trees.forestStyle.heightScale
end

-- Field and map battles keep independent saved angles. Geometry and the
-- fitted battle matrix use the selected combat angle together.
function O.indoorLocked(def)
 if not def then
  local game=V.require('EffectSettings').game
  if game then local id;id,def=V.require('WorldAdapter').current(game)end
 end
 return def and tonumber(def.mapType)~=4 and not V.data('Shapes').outdoors(def)or false
end
function O.effectiveAngle(def)
 local combat=require('src.core.game3.battle').isActive()or require('src.core.game3.battle_transition').isActive()
 if combat then return O.battleAngle()end
 return O.indoorLocked(def)and 50 or rows[1].s:get()or 50
end
function O.available(key)
 local combat=require('src.core.game3.battle').isActive()or require('src.core.game3.battle_transition').isActive()
 if key=='gen3FieldCamera'then return false end
 if key=='gen3OvTilt'then return not combat and not O.indoorLocked() end
 if key=='gen3BattleTilt'then return combat and V.require('battle/BattleViews').preference()=='paper' end
 return true
end
function O.cycleFieldAngle(game)
 if not O.available('gen3OvTilt')then return false end
 rows[1].s:cycle(game,1)
 O.apply()
 return true
end
local function selectable(index)
 local setting=rows[index].s
 return O.available(setting and setting.key)
end
local function cursorStep(dir)
 repeat O.cursor=(O.cursor-1+dir)%#rows+1 until selectable(O.cursor)
end
local function normalizeCursor()if not selectable(O.cursor)then cursorStep(1)end end
local hiddenAngle={tilt=true,field_camera=true};local hiddenBattleAngle={battle_tilt=true};local hiddenBoth={tilt=true,battle_tilt=true,field_camera=true}
function O.battleAngle()return rows[2].s:get()or 24 end
local lastGeometry,normalizedFor
-- Runs every frame after EffectSettings.apply, which rewrites the shared
-- switches from options. Only derived values are set here.
function O.apply()
 local game=V.require('EffectSettings').game
 V.require('FieldCamera').apply(game)
 if game and normalizedFor~=game then
  for i=1,2 do
   local setting=rows[i].s
   local stored=V.mod.options:get(setting.key)
   if stored~=nil and stored~=setting:get()then setting:setValue(setting:get(),game,true)end
  end
  normalizedFor=game
 end
 local c=V.require('DioramaConfig');snapshot(c)
 local function get(id)for _,r in ipairs(rows)do if r.id==id then return r.s and r.s:get()end end end
 c.camera.elevationDegrees=O.effectiveAngle()
 local post=get('post')
 c.post.enabled=post~='off'
 if post=='bloom' then c.post.depthOfField=false;c.post.vignette=false end
 c.post.bloomStrength=get('bloom') or .08
 local ts=get('tilt_shift')
 if ts=='off' then c.post.depthOfField=false end
 local k=ts=='subtle' and .5 or 1
 local effects=V.require('EffectSettings')
 c.post.coc.near=(effects.focusNear or base.cocNear)*k;c.post.coc.far=(effects.focusFar or base.cocFar)*k
 c.post.blurStrength=base.top*k;c.post.bottomBlurStrength=base.bottom*k;c.post.edgeBlurStrength=base.edge*k
 if get('shadows')==false then c.shadows.enabled=false end
 c.clouds.enabled=get('clouds')~=false
 c.forest.enabled=get('atmosphere')~=false
 if c.dynamicTexture then c.dynamicTexture.enabled=get('texture')~=false end
 local terrain=get('terrain')
 local tall=terrain=='tall' and 1.5 or 1
 if terrain=='off' then c.billboards.enabled=false;c.terrain.enabled=false;c.grass.enabled=false end
 c.terrain.ledgeHeight=base.ledge*tall;c.terrain.cliffHeight=base.cliff*tall;c.terrain.caveWallHeight=base.wall*tall
 local treeK=terrain=='tall' and 1.15 or 1
 for key,v in pairs(c.trees.pairStyle or {})do v.heightScale=base.heights['p'..key]*treeK end
 if c.trees.defaultStyle then c.trees.defaultStyle.heightScale=base.heights.default*treeK end
 if c.trees.forestStyle then c.trees.forestStyle.heightScale=base.heights.forest*treeK end
 -- Geometry is cached; rebuild only when a geometry-affecting row changes.
 -- Renderer selects a retained angle-specific scene. Only terrain edits
 -- change all angle variants and require a complete invalidation.
 local geometry=tostring(terrain)
 if lastGeometry and lastGeometry~=geometry then
  V.require('Trees').release();V.require('Renderer').invalidate()
 end
 lastGeometry=geometry
end

local function lighting()return V.require('DayNight').setting end
local function valueLabel(r)
 if r.id=='lighting' then
  local v=lighting():get()
  for i,x in ipairs(lightValues)do if x==v then return lightLabels[i]end end
  return 'CYCLE'
 end
 local s=r.s;local i=s:read();return s.labels[i]or'?'
end

local function step(r,dir,game)
 if not O.available(r.s and r.s.key)then return end
 if r.id=='lighting' then
  local v=lighting():get();local i=1
  for n,x in ipairs(lightValues)do if x==v then i=n end end
  i=((i-1+dir)%#lightValues)+1
  lighting():setValue(lightValues[i],game)
  return
 end
 local s=r.s;local n=#s.values;local i=s:read()
 s:setIndex(((i-1+dir)%n)+1,game)
end

function O.toggle(pad)O.open=not O.open;O.padHint=pad and true or false end

-- Returns true when the key was consumed.
function O.key(game,event)
 if event.key=='f7' then
  if event.phase=='pressed' then O.toggle()end
  return true
 end
 if not O.open then return false end
 if event.phase~='pressed' then return true end
 normalizeCursor()
 local k=event.key
 if k=='up' then cursorStep(-1)
 elseif k=='down' then cursorStep(1)
 elseif k=='left' then step(rows[O.cursor],-1,game)
 elseif k=='right' or k=='return' or k=='z' or k=='space' then step(rows[O.cursor],1,game)
 elseif k=='escape' or k=='x' or k=='backspace' then O.open=false end
 return true
end

function O.draw()
 if not O.open then return end
 normalizeCursor()
 local hidden=O.available('gen3OvTilt')and hiddenBattleAngle or O.available('gen3BattleTilt')and hiddenAngle or hiddenBoth
 V.require('GraphicsPanel').draw(rows,O.cursor,valueLabel,O.padHint,hidden)
end

O.rows=rows
return O
