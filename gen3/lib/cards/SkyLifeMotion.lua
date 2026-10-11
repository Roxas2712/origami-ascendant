-- Pure saved-clock trajectories. No global RNG, arrival timer or camera input.
local M={}
function M.hash(s)
 local h=17;for i=1,#s do h=(h*31+s:byte(i))%65521 end;return h
end
function M.random(seed,index)return ((seed*173+index*7919+index*index*37)%65521)/65521 end
function M.schedule(seed,minimum,maximum)
 local s={seed=seed,total=0,starts={}}
 for i=1,4 do s.total=s.total+minimum+math.floor(M.random(seed,i)*(maximum-minimum+1));s.starts[i]=s.total end
 return s
end
function M.event(s,time)
 time=math.max(0,time or 0);local cycle=math.floor(time/s.total);local phase=time-cycle*s.total
 for i=4,1,-1 do if phase>=s.starts[i]then return phase-s.starts[i],cycle*4+i end end
 if cycle==0 then return math.huge,0 end
 return phase,(cycle-1)*4+4
end
function M.new(id)
 local seed=M.hash(id or'');local p={seed=seed,birds=M.schedule(seed,60,180),meteors=M.schedule(seed+71,90,240),count=0,rows={}}
 for i=1,5 do p.rows[i]={0,60,0,0}end
 return p
end
function M.update(p,time,width,height)
 p.count=0;local age,event=M.event(p.birds,time)
 local distance=(width+128)/.948683298;local duration=math.min(28,math.max(10,distance/45))
 if age<0 or age>=duration then return end
 local t=age/duration;local z0=height*(.2+.6*M.random(p.seed,event+31))
 p.count=3+math.floor(M.random(p.seed,event+11)*3)
 for i=1,p.count do
  local wing=math.ceil((i-1)/2);local side=i%2==0 and -1 or 1
  local x=width+64-t*distance*.948683298+wing*7
  local z=z0+(1-t)*distance*.316227766-distance*.158113883+side*wing*8+math.sin(t*math.pi*2+i*.3)*6
  local r=p.rows[i];r[1],r[2],r[3],r[4]=x,60,z,math.floor(time*7+i*.2)%4
 end
end
function M.clearWeather(weather)
 return weather==nil or weather=='clear' or weather=='off' or weather=='none' or weather=='heat'
end
function M.meteor(p,time,hasSky,night,weather,cover)
 if not hasSky or night<=.8 or not M.clearWeather(weather)or(cover or 0)>.4 then return nil end
 local age,event=M.event(p.meteors,time)
 if age<0 or age>=.4 then return nil end
 return age/.4,M.random(p.seed,event+101),M.random(p.seed,event+149)
end
return M
