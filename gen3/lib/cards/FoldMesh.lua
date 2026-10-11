-- Reused paper facets morph a full map sheet into seven recognizable models.
local M={}
local corners={{0,0},{1,0},{1,1},{0,0},{1,1},{0,1}}
function M.rows()
 local rows={};for i=1,144 do rows[i]={0,0,0,0,1,1,1,1}end;return rows
end
local function accordion(rows,width,height,amount)
 amount=math.max(0,math.min(1,amount));amount=amount*amount*(3-2*amount)
 local angle=amount*math.pi*.5;local shrink=math.max(.001,math.cos(angle));local rise=math.sin(angle)
 local n=0
 for y=0,3 do for x=0,5 do
  local shade=1-rise*(.18+((x+y)%2)*.2)
  for _,q in ipairs(corners)do
   n=n+1;local r=rows[n];local cx,cy=x+q[1],y+q[2]
   local z=((cx%2)+(cy%2)-1)*rise*.12
   r[1]=width*(.5+(cx/6-.5)*shrink/(1+z))
   r[2]=height*(.5+(cy/4-.5)*shrink/(1+z))
   r[3],r[4]=cx/6,cy/4
   r[5],r[6],r[7],r[8]=shade,shade,shade,1
  end
 end end
 return rows
end
-- Twelve boundary corners per paper model, each split into four shared
-- facets. UVs cover the original sheet exactly; the same 144 vertices unfold
-- the arriving map. Models use screen-independent proportions.
local forms={
 pokeball={{.50,.12},{.69,.17},{.83,.31},{.88,.50},{.83,.69},{.69,.83},{.50,.88},{.31,.83},{.17,.69},{.12,.50},{.17,.31},{.31,.17}},
 charmander={{.34,.18},{.48,.13},{.61,.20},{.67,.30},{.65,.43},{.57,.50},{.65,.59},{.74,.62},{.81,.47},{.85,.27},{.90,.18},{.96,.35},{.92,.49},{.90,.66},{.82,.78},{.65,.78},{.62,.88},{.47,.87},{.42,.79},{.34,.87},{.21,.86},{.24,.72},{.23,.57},{.30,.43}},
 squirtle={{.34,.19},{.47,.14},{.60,.19},{.66,.29},{.65,.42},{.57,.48},{.70,.45},{.80,.54},{.83,.68},{.89,.67},{.93,.59},{.98,.67},{.95,.77},{.84,.82},{.72,.78},{.68,.89},{.55,.88},{.48,.80},{.38,.88},{.24,.85},{.27,.74},{.18,.62},{.20,.55},{.29,.48}},
 heart={{.50,.28},{.66,.15},{.83,.18},{.92,.35},{.86,.52},{.70,.69},{.50,.88},{.30,.69},{.14,.52},{.08,.35},{.17,.18},{.34,.15}},
 pikachu={{.25,.10},{.39,.31},{.48,.28},{.58,.08},{.62,.30},{.73,.42},{.70,.55},{.61,.61},{.80,.55},{.93,.34},{.86,.63},{.94,.68},{.79,.73},{.72,.84},{.60,.89},{.51,.82},{.41,.89},{.28,.86},{.24,.71},{.12,.67},{.25,.58},{.17,.49},{.23,.36},{.25,.29}},
 eevee={{.14,.13},{.39,.29},{.50,.27},{.73,.12},{.69,.38},{.76,.48},{.64,.61},{.82,.56},{.94,.66},{.83,.80},{.67,.81},{.60,.90},{.42,.88},{.30,.77},{.19,.64},{.24,.45}},
 bulbasaur={{.22,.40},{.19,.25},{.34,.30},{.44,.36},{.59,.31},{.71,.14},{.84,.23},{.90,.37},{.86,.55},{.92,.72},{.84,.84},{.73,.81},{.53,.77},{.41,.85},{.24,.81},{.14,.66}}
}
M.forms={'charmander','squirtle','bulbasaur','heart','pikachu','eevee','pokeball'}
function M.choose(from,to,count)
 local hash=0;for ch in tostring(from):gmatch('.')do hash=(hash+ch:byte())%#M.forms end
return M.forms[((count or 1)+hash-1)%#M.forms+1]
end
local colors={pokeball={.97,.94,.88},heart={1,.22,.32},pikachu={1,.82,.12},eevee={.72,.43,.22},squirtle={.37,.78,.95},bulbasaur={.40,.81,.61},charmander={1,.49,.14}}
local pokeballRed={.92,.13,.17}
local boundary={}
for i=0,47 do
 local t=i/12;local edge=math.floor(t);local k=t-edge
 boundary[i+1]=edge==0 and{k,0}or edge==1 and{1,k}or edge==2 and{1-k,1}or{0,1-k}
end
function M.update(rows,w,h,amount,form)
 local points=forms[form];if not points then return accordion(rows,w,h,amount)end
 local a=math.max(0,math.min(1,amount));a=a*a*(3-2*a)
 local size=math.min(w,h)*.85;local n=0
 for i=0,47 do
  local subdivisions=48/#points
  local at=math.floor(i/subdivisions)+1;local k=(i%subdivisions)/subdivisions
  local at2=math.floor(((i+1)%48)/subdivisions)+1;local k2=((i+1)%subdivisions)/subdivisions
  local shade=1-a*(.10+(math.floor(i/subdivisions)%3)*.16)
  for corner=1,3 do
   n=n+1;local row=rows[n];local u,v,tx,ty
   if corner==1 then u,v,tx,ty=.5,.5,.50,form=='pokeball'and .5 or .55
   else
    local b=boundary[(i+corner-2)%48+1];u,v=b[1],b[2]
    local j,q=corner==2 and at or at2,corner==2 and k or k2
    local p0,p1=points[j],points[j%#points+1];tx,ty=p0[1]+(p1[1]-p0[1])*q,p0[2]+(p1[2]-p0[2])*q
   end
   -- Fold edges lift in alternate directions before meeting their crease.
   local lift=math.sin(a*math.pi)*math.sin((u+v)*math.pi*3)*size*.055
   row[1]=u*w*(1-a)+(w/2+(tx-.5)*size)*a
   row[2]=v*h*(1-a)+(h/2+(ty-.5)*size)*a+lift
   local c=colors[form]
   if form=='pokeball'and (i<12 or i>=36)then c=pokeballRed end
   row[3],row[4]=u,v;row[5],row[6],row[7],row[8]=shade*(1-a+a*c[1]),shade*(1-a+a*c[2]),shade*(1-a+a*c[3]),1
  end
 end
 return rows
end
-- Folded paper details fade in only near the completed pose. These are small
-- geometric facets; there is no extra texture or full-screen allocation.
function M.details(w,h,amount,form)
 local opacity=math.max(0,math.min(1,(amount-.78)/.22));if opacity==0 then return end
 local g=love.graphics;local size=math.min(w,h)*.85
 g.push('all');g.translate(w/2-size*.5,h/2-size*.5);g.scale(size)
 local function ink(r,b,c)g.setColor(r,b,c,opacity)end
 if form=='pokeball'then
  ink(.09,.10,.12);g.polygon('fill',.12,.48,.88,.48,.88,.53,.12,.53)
  local function ring(radius)
   local xy={};for i=0,11 do local angle=i*math.pi/6;xy[#xy+1]=.5+math.cos(angle)*radius;xy[#xy+1]=.5+math.sin(angle)*radius end
   g.polygon('fill',xy)
  end
  ring(.105);ink(.98,.96,.91);ring(.075);ink(.69,.70,.70);ring(.037)
 elseif form=='pikachu' then
  ink(.12,.10,.09);g.polygon('fill',.25,.10,.295,.17,.25,.22);g.polygon('fill',.58,.08,.60,.18,.535,.17)
  g.polygon('fill',.35,.44,.39,.44,.39,.48,.35,.48);g.polygon('fill',.54,.43,.58,.43,.58,.47,.54,.47)
  g.polygon('fill',.44,.52,.49,.52,.465,.55)
  ink(.96,.20,.12);g.polygon('fill',.29,.51,.35,.49,.38,.54,.33,.57);g.polygon('fill',.56,.51,.62,.49,.66,.54,.61,.57)
  ink(.66,.38,.10);g.polygon('fill',.67,.72,.73,.69,.77,.73,.70,.77)
 elseif form=='charmander' then
  ink(1,.88,.59);g.polygon('fill',.36,.57,.50,.54,.59,.63,.57,.78,.40,.79,.32,.69)
  ink(.10,.21,.22);g.polygon('fill',.35,.29,.39,.29,.40,.35,.35,.36);g.polygon('fill',.54,.29,.58,.28,.58,.35,.53,.35)
  ink(1,.97,.91);g.polygon('fill',.36,.29,.375,.29,.38,.32,.36,.32);g.polygon('fill',.55,.29,.565,.29,.565,.32,.55,.32)
  ink(.40,.17,.10);g.polygon('fill',.39,.40,.55,.39,.51,.43,.44,.44)
  ink(1,.18,.04);g.polygon('fill',.83,.44,.84,.32,.90,.18,.96,.35,.91,.46)
  ink(1,.92,.17);g.polygon('fill',.865,.42,.875,.32,.90,.28,.915,.37,.90,.43)
 elseif form=='squirtle' then
  ink(.50,.30,.13);g.polygon('fill',.59,.49,.70,.46,.80,.54,.83,.68,.72,.77,.58,.72)
  ink(.94,.84,.61);g.polygon('fill',.34,.55,.47,.51,.60,.59,.60,.74,.50,.81,.35,.76,.28,.65)
  ink(.66,.52,.29);g.setLineWidth(.008);g.line(.31,.64,.58,.64);g.line(.35,.74,.56,.74);g.line(.45,.54,.46,.78)
  ink(.20,.10,.12);g.polygon('fill',.34,.29,.39,.28,.40,.35,.35,.36);g.polygon('fill',.55,.28,.59,.28,.59,.35,.54,.35)
  ink(1,1,1);g.polygon('fill',.35,.29,.37,.29,.375,.32,.35,.32);g.polygon('fill',.56,.29,.58,.29,.58,.32,.56,.32)
  ink(.20,.30,.31);g.polygon('fill',.39,.41,.56,.40,.50,.44,.43,.44)
 elseif form=='bulbasaur' then
  ink(.17,.50,.19);g.polygon('fill',.59,.32,.71,.14,.84,.23,.90,.37,.86,.55,.66,.51)
  ink(.34,.66,.27);g.polygon('fill',.71,.14,.74,.36,.59,.32);g.polygon('fill',.84,.23,.74,.36,.86,.55)
  ink(.94,.31,.27);g.polygon('fill',.23,.43,.31,.44,.31,.53,.23,.51);g.polygon('fill',.43,.43,.51,.40,.52,.50,.44,.52)
  ink(1,.98,.87);g.polygon('fill',.245,.45,.265,.45,.265,.48,.245,.48);g.polygon('fill',.46,.44,.48,.43,.48,.46,.46,.47)
  ink(.12,.30,.25);g.polygon('fill',.29,.59,.45,.58,.40,.62,.34,.62)
  ink(.13,.48,.37);g.polygon('fill',.19,.61,.24,.56,.28,.62,.23,.67);g.polygon('fill',.39,.70,.45,.66,.49,.72,.43,.77);g.polygon('fill',.73,.63,.80,.58,.83,.66,.77,.71)
 elseif form=='eevee' then
  ink(.24,.12,.10);g.polygon('fill',.18,.19,.33,.32,.26,.40);g.polygon('fill',.68,.19,.62,.40,.55,.32)
  g.polygon('fill',.34,.43,.39,.43,.39,.48,.34,.48);g.polygon('fill',.54,.43,.59,.43,.59,.48,.54,.48)
  g.polygon('fill',.44,.53,.49,.53,.465,.56)
  ink(.98,.84,.58);g.polygon('fill',.25,.61,.38,.60,.46,.63,.57,.60,.65,.62,.60,.70,.54,.69,.49,.75,.42,.70,.35,.72)
  g.polygon('fill',.88,.63,.94,.66,.83,.80,.77,.75,.82,.71)
 end
 g.pop()
end
return M
