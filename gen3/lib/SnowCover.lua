-- Persistent presentation state for visited outdoor maps. No wall-clock time,
-- native tiles or movement flags: a room visit hides snow, it does not erase it.
local V=...
local S={clock=0,maps={}}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function clamp(n)return math.max(0,math.min(1,n))end
local function cfg()return V.require('DioramaConfig').weather.snow end
local function decay(entry,now)
 return clamp(entry.amount-math.max(0,now-entry.time)/math.max(1,cfg().meltSeconds or 240))
end
function S.update(dt,id,outside,mode,precipitation)
 dt=finite(dt)and math.max(0,dt)or 0
 local before=S.clock;S.clock=before+dt
 if not outside or not id or id==''then return 0 end
 local e=S.maps[id];local amount=e and decay(e,before)or 0
 local falling=mode=='snow'and(finite(precipitation)and clamp(precipitation)or 1)or 0
 amount=clamp(amount+dt*(falling/math.max(.1,cfg().settleSeconds)-(1-falling)/math.max(1,cfg().meltSeconds or 240)))
 S.maps[id]=amount>0 and {amount=amount,time=S.clock}or nil
 return amount
end
-- Lazy regional simulation: evaluate weather only when a map is drawn.
-- Retain setting changes on one shared timeline, rather than per-map timers.
local regimes={}
function S.regional(dt,id,outside,weatherClock,selected,resolve)
 dt=finite(dt)and math.max(0,dt)or 0
 local before=S.clock;S.clock=before+dt
 local last=regimes[#regimes]
 if not last or last.selected~=selected then
  regimes[#regimes+1]={time=before,clock=weatherClock-dt,selected=selected}
 end
 local horizon=math.max(.1,cfg().settleSeconds)+math.max(1,cfg().meltSeconds or 240)
 while #regimes>1 and regimes[2].time<S.clock-horizon do table.remove(regimes,1)end
 if not outside or not id or id==''then return 0 end
 local entry=S.maps[id]
 local start=entry and entry.time or math.max(0,before-horizon)
 local amount=entry and entry.amount or 0
 -- At most the melt horizon is relevant for a previously unknown map.
 -- One-second weather samples bound work (~250), irrespective of map count.
 if before-start>horizon then start=before-horizon;amount=0 end
 local t=start
 while t<S.clock do
  local regime=regimes[1];local stop=math.min(S.clock,t+1)
  for i,r in ipairs(regimes)do
   if r.time<=t then regime=r elseif r.time<stop then stop=r.time;break end
  end
  local mode=regime and resolve(id,regime.selected,regime.clock+(t-regime.time)+(stop-t)*.5)or 'clear'
  local falling=mode=='snow'and 1 or 0
  amount=clamp(amount+(stop-t)*(falling/math.max(.1,cfg().settleSeconds)-(1-falling)/math.max(1,cfg().meltSeconds or 240)))
  t=stop
 end
 S.maps[id]={amount=amount,time=S.clock}
 return amount
end
function S.snapshot()
 local maps={}
 for id,e in pairs(S.maps)do local a=decay(e,S.clock);if a>0 then maps[id]=a end end
 -- Version 1 remains readable; the optional timeline preserves unseen
 -- snowfall across saves instead of baking only the currently visited map.
 local rows={};for id,e in pairs(S.maps)do rows[id]={amount=e.amount,time=e.time}end
 local history={};for i,r in ipairs(regimes)do history[i]={time=r.time,clock=r.clock,selected=r.selected}end
 return {version=1,maps=maps,clock=S.clock,entries=rows,regimes=history}
end
function S.restore(data)
 S.clock=0;S.maps={};regimes={}
 if type(data)~='table'or data.version~=1 or type(data.maps)~='table'then return end
 local n=0
 for id,a in pairs(data.maps)do
  if type(id)=='string'and #id<=160 and finite(a)and a>0 then
   S.maps[id]={amount=clamp(a),time=0};n=n+1;if n>=1024 then break end
  end
 end
 if finite(data.clock)and data.clock>=0 and type(data.entries)=='table'and type(data.regimes)=='table'then
  S.clock=data.clock;local restored={};local count=0
  for id,e in pairs(data.entries)do
   if type(id)=='string'and #id<=160 and type(e)=='table'and finite(e.amount)and finite(e.time)and e.time>=0 and e.time<=S.clock then
    restored[id]={amount=clamp(e.amount),time=e.time};count=count+1;if count>=1024 then break end
   end
  end
  S.maps=restored
  for i,r in ipairs(data.regimes)do
   if i>64 then break end
   if type(r)=='table'and finite(r.time)and finite(r.clock)and r.time>=0 and r.time<=S.clock and type(r.selected)=='string'and #r.selected<24 then
    if not regimes[#regimes]or r.time>=regimes[#regimes].time then regimes[#regimes+1]={time=r.time,clock=r.clock,selected=r.selected}end
   end
  end
 end
end
function S.store()
 local save=V.mod and V.mod.save
 if save and save.set then save:set('snowCoverV1',S.snapshot())end
end
function S.load()
 local save=V.mod and V.mod.save
 S.restore(save and save.get and save:get('snowCoverV1'))
end
return S
