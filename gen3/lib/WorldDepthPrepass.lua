-- Cheap opaque visibility before expensive paper/local-light shading. Uses the
-- identical assembled vertex and alpha/clipping code; no new scene target.
local V=...;local D={proxies=setmetatable({},{__mode='k'})}
function D.source(source)
 local marker='  if(occludedPlayerPass>0.0)'
 local first=source:find(marker,1,true);assert(first,'missing world alpha boundary')
 return V.require('SurfaceDerivatives').language(source:sub(1,first-1)..[[
  if(opacity<.999)discard;
  // Leave a few depth24 steps for the colour pass. It writes its original
  // depth with LESS, preserving first-wins coplanar faces and particle tests.
  gl_FragDepth=min(1.0,gl_FragCoord.z+4.0/16777216.0);
  return vec4(0.0);
}
#endif
]])
end
function D.clear()D.proxies=setmetatable({},{__mode='k'})end
function D.proxy(shader)
 local old=D.proxies[shader];if old then return old end
 local U=V.require('UniformState')
 local proxy={hasUniform=function(_,name)return U.has(shader,name)end,
  send=function(_,name,...)if U.has(shader,name)then U.send(shader,name,...)end end}
 D.proxies[shader]=proxy;return proxy
end
return D
