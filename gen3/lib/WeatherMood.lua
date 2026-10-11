-- Render-only weather fronts. AUTO is reproducible from the saved regional
-- clock; manual selections ease toward their new atmosphere without rerolls.
local V=...
local M={}
local profiles={
 clear={cloud=0,sky=1,agitation=1,tint={1,1,1}},
 rain={cloud=.80,sky=.24,agitation=1.3,shadow=.45,tint={.86,.90,.95}},
 storm={cloud=.97,sky=.10,agitation=1.7,shadow=.45,tint={.72,.79,.87}},
 snow={cloud=.72,sky=.45,agitation=1,tint={.91,.96,1.02}},
 fog={cloud=.92,sky=.35,agitation=1,tint={.92,.97,.98}},
 heat={cloud=.08,sky=1,agitation=1,tint={1.02,1,.94}},
 ash={cloud=.62,sky=.45,agitation=1.1,tint={.95,.91,.87}},
 sand={cloud=.72,sky=.30,agitation=1.4,tint={.98,.88,.73}},
}
local function smooth(x)x=math.max(0,math.min(1,x));return x*x*(3-2*x)end
local function blend(a,b,t)
 local out={tint={}}
 for _,k in ipairs{'cloud','sky','agitation'}do out[k]=a[k]+(b[k]-a[k])*t end
 out.shadow=(a.shadow or 1)+((b.shadow or 1)-(a.shadow or 1))*t
 for i=1,3 do out.tint[i]=a.tint[i]+(b.tint[i]-a.tint[i])*t end
 return out
end
local function wet(m)return m=='rain'or m=='storm'or m=='snow'or m=='ash'or m=='sand'end
-- Consumers of precipitation must use the visible front, not the requested
-- next mode. Otherwise dry ground shines and snow settles before drops/flakes.
function M.precipitation(mode,state)
 return state and state.precipMode or mode,state and state.amount or(wet(mode)and 1 or 0)
end
function M.rainAmount(mode,state)
 local visible,amount=M.precipitation(mode,state)
 return (visible=='rain'or visible=='storm')and amount or 0
end
function M.front(clock,period,resolve)
 local phase=clock%period;local mode=resolve(clock)
 local prev,nextMode=resolve(clock-phase-.01),resolve(clock-phase+period+.01)
 local a,b,t=profiles[mode]or profiles.clear,profiles[mode]or profiles.clear,0
 -- The approaching front changes sky fill before precipitation begins.
 -- The same interpolation straddles the boundary, without a brightness cut.
 if phase<30 then a=profiles[prev]or profiles.clear;t=smooth((phase+30)/60)
 elseif phase>period-30 then b=profiles[nextMode]or profiles.clear;t=smooth((phase-period+30)/60)end
 local out=blend(a,b,t)
 out.precipMode=mode;out.amount=wet(mode)and 1 or 0
 if prev~=mode then out.amount=out.amount*smooth(phase/18)end
 if nextMode~=mode then out.amount=out.amount*smooth((period-phase)/18)end
 return out
end
function M.update(dt,map,target)
 local W=V.require('Weather')
 local C=V.require('CloudDaylight')
 if not C.supports(map and(map.def or map))or not W.isOutdoor(map)or C.setting:get()=='original' then M.state=nil;return end
 if W.setting:get()=='auto'and W.modeAt(map,'native',W.clock)=='clear' then
  M.state=M.front(W.clock,W.AUTO_SECONDS,function(t)return W.modeAt(map,'auto',t)end)
  return
 end
 local desired=profiles[target]or profiles.clear
 if not M.state then M.state=blend(desired,desired,0);M.state.precipMode=target;M.state.amount=wet(target)and 1 or 0;return end
 local old=M.state;local state=blend(old,desired,1-math.exp(-math.max(0,dt)/6))
 state.precipMode=old.precipMode;state.amount=old.amount
 local amount=wet(target)and 1 or 0;local step=math.max(0,dt)/6
 if state.precipMode~=target then
  state.amount=math.max(0,state.amount-step)
  if state.amount==0 then state.precipMode=target end
 else state.amount=state.amount+math.max(-step,math.min(step,amount-state.amount))end
 M.state=state
end
function M.sample(map)
 local C=V.require('CloudDaylight')
 if C.supports(map and(map.def or map))and V.require('Weather').isOutdoor(map)and C.setting:get()~='original'then return M.state end
end
return M
