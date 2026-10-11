-- The rocket, gantries and dish are upright native artwork. Folding them
-- into a roof plane would lay the rocket down; retain one complete silhouette.
local V=...
local M={}
local panes={}
for _,x in ipairs({9,25,41,97,113,129})do for _,y in ipairs({153,169})do panes[#panes+1]={x,y,x+5,y+5}end end
for _,y in ipairs({147,163,179,195})do
 panes[#panes+1]={68,y,75,y};panes[#panes+1]={67,y+1,76,y+1};panes[#panes+1]={66,y+2,77,y+2}
 panes[#panes+1]={65,y+3,78,math.min(y+9,199)}
 if y<195 then panes[#panes+1]={66,y+10,77,y+10}end
end
for _,r in ipairs({{59,206,62,206},{64,206,70,206},{73,206,79,206},{81,206,85,206},
 {58,207,62,217},{64,207,70,217},{73,207,79,217},{81,207,86,217}})do panes[#panes+1]=r end
function M.buildings(d)
 local c=V.require('DioramaConfig').spaceCenterArchitecture
 if not c.enabled or d.id~='EM_MOSSDEEP_CITY'or d.pair~='general__mossdeep'then return{}end
 return{{x0=60,x1=68,y0=3,y1=15,doorX=64,doorY=15,ground=1,
  hoennLandmark=true,lightScale=c.lightScale,eaveRow=0,cutAllBackdrop=true,panes=panes,
  paperValues={wallScale=c.wallScale,roofScale=0}}}
end
return M
