-- A single settled composition from captured actor bounds. Never tracks attacks.
local A={}
local function clamp(x,a,b)return math.max(a,math.min(b,x))end
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function shift(z)return z>1 and(.125*(1-z)-.10*clamp((z-1)/1.5,0,1))*80 or -.16*(1-z)*80 end
function A.choose(bounds,visible)
 local l,t,r,b=240,160,0,0;local n=0;local ml,mr=240,0
 for side,box in pairs(bounds or{})do
  if visible and visible[side] and box then
   for i=1,4 do if not finite(box[i])then return nil end end
   if box[3]>box[1]and box[4]>box[2]then
    l,t,r,b=math.min(l,box[1]),math.min(t,box[2]),math.max(r,box[3]),math.max(b,box[4]);n=n+1
    if not side:find('Trainer',1,true)then ml,mr=math.min(ml,box[1]),math.max(mr,box[3])end
   end
  end
 end
 if n<2 or mr<=ml then return nil end
 -- Aim for a readable duel; trainers remain inside a conservative safe area.
 local wanted=clamp(152/(mr-ml),.82,1.35)
 local chosen=.82
 for i=0,106 do
  local z=.82+i*.005
  if z>wanted then break end
  local lo,hi=120+(l-120)*z,120+(r-120)*z
  local top,bottom=80+(t-80)*z+shift(z),80+(b-80)*z+shift(z)
  if lo>=9 and hi<=231 and top>=12 and bottom<=140 then chosen=z end
 end
 return chosen
end
function A.sample(from,target,age)
 local t=clamp((age or 0)/.45,0,1);t=t*t*(3-2*t)
 return from+(target-from)*t,t==1
end
return A
