-- Only proven presentation-only settings are omitted. Unknown settings remain
-- in the key, including new geometry controls added by later work.
local G={version=0}
local presentations={}
-- Cards may add baked contact shadows or geometry. Keep their unknown settings
-- guarded until an individual card has a proven presentation-only contract.
local omitted={post=true,cycle=true,renderCache=true}
local fields={
 settings={definitions=true,presets=true,defaultPreset=true,renderScale=true,battleResolution=true,maxLights=true,fireflyBudget=true,shadowScale=true,shadowSoftness=true},
 -- PaperShadows and runtime firefly sprites use these after scene construction.
 shadows={enabled=true},
 fireflies={count=true},
 lighting={hemisphere=true,transmission=true},
 billboards={rim=true},
 atmosphere={aerial=true,godRays=true},
 -- Haunted mist is integrated from live depth after geometry is drawn.
 haunted={mistColor=true,mistLight=true,mistHeight=true,mistRibbonMix=true},
}
-- Explicit field-level contracts for runtime-only Card settings. A new/unknown
-- field still changes the geometry key. Ownership is removable with the Card;
-- no Card module is imported here and baked Cards need no registration.
function G.registerPresentation(owner,namespace,names)
 assert(type(owner)=='string'and owner~=''and type(namespace)=='string'and namespace~='')
 local old=presentations[namespace]
 assert(not old or old.owner==owner,'presentation namespace already owned: '..namespace)
 local ignore={}
 for _,name in ipairs(names)do assert(type(name)=='string'and name~='');ignore[name]=true end
 assert(next(ignore),'presentation fields required')
 presentations[namespace]={owner=owner,fields=ignore};G.version=G.version+1
end
function G.unregisterPresentation(owner)
 local changed=false
 for name,row in pairs(presentations)do if row.owner==owner then presentations[name]=nil;changed=true end end
 if changed then G.version=G.version+1 end
end
local function cards(value)
 local out={}
 for namespace,settings in pairs(value)do
  local contract=presentations[namespace]
  if contract and type(settings)=='table'then
   local row={};for key,v in pairs(settings)do if not contract.fields[key]then row[key]=v end end
   if next(row)then out[namespace]=row end
  else out[namespace]=settings end
 end
 return next(out)and out or nil
end
function G.project(config)
 local out={}
 for key,value in pairs(config)do
  if not omitted[key]then
   local ignore=fields[key]
   if key=='cards'and type(value)=='table'then out[key]=cards(value)
   elseif ignore and type(value)=='table'then
    local row={};for k,v in pairs(value)do if not ignore[k]then row[k]=v end end
    out[key]=row
   else out[key]=value end
  end
 end
 return out
end
return G
