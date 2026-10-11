-- This preview loads only the isolated FireRed runtime.
local mod=...
mod._origamiPackageVersion=mod.version or "1.0.0"
local exports=assert((loadstring or load)(assert(mod:read("gen3/main.lua")),"@OrigamiAscendant/gen3/main.lua"))(mod)
mod.exports.lib.require('AscendantEntry').install(mod.exports)
return exports
