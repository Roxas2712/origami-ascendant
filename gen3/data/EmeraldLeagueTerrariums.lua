-- Nine authored alpha components per kit, assembled in actual depth layers.
-- Bounds are measured on the original PNG; no raster slicing or repainting.
local kits={
 dark={back={75,8,367,416},arch={445,4,811,420},pillars={868,23,1230,416},rail={20,535,420,749},mobile={427,429,824,791},crest={884,433,1193,800},podium={440,965,818,1135},front={845,889,1239,1155}},
 ghost={back={56,9,388,475},arch={417,13,837,470},pillars={878,7,1228,478},rail={10,552,428,775},mobile={446,503,816,795},crest={893,487,1218,847},podium={433,991,820,1205},front={845,920,1240,1207}},
 ice={back={41,25,391,462},arch={425,11,831,477},pillars={879,24,1229,476},rail={16,569,420,775},mobile={422,502,842,795},crest={902,490,1213,844},podium={451,1001,806,1146},front={847,895,1238,1202}},
 dragon={back={44,9,375,414},arch={414,0,843,419},pillars={883,0,1220,425},rail={21,540,403,740},mobile={425,448,833,789},crest={843,427,1243,819},podium={424,1015,831,1170},front={851,868,1245,1180}},
 champion={back={71,17,382,440},arch={427,9,830,445},pillars={865,12,1223,444},rail={10,566,441,783},mobile={451,480,820,812},crest={844,461,1240,838},podium={437,982,822,1148},front={829,928,1240,1193}},
}
local layouts={}
for kind,r in pairs(kits)do
 local out={};layouts[kind]=out
 local function card(part,width,x,y,z,begin,extra)
  local a=type(part)=='table'and part or r[part]
  local d={texture='league-'..kind..'-kit.png',imageWidth=1254,imageHeight=1254,cutout=true,
   points={{a[1],a[2]},{a[3],a[2]},{a[3],a[4]},{a[1],a[4]}},width=width,x=x,y=y,z=z,
   begin=begin,duration=.8,direction=z>1 and -1 or 1,foldOffset=(part~='front'and part~='podium')and math.max(0,(begin-3.12)*.18)or 0}
  for k,v in pairs(extra or{})do d[k]=v end
  if d.height then d.heightScale=d.height/((a[4]-a[2])*width*30/(a[3]-a[1]));d.height=nil end
  out[#out+1]=d;return d
 end
 card('back',4.9,0,-1.35,-2.45,3.12,{height=132,curve=7})
 card('arch',5.1,0,-1.35,-2.26,3.27,{height=139,curve=7})
 card('pillars',1.64,-1.88,-1.35,-1.83,3.40,{warm=kind=='ghost',flowing=kind=='champion'})
 card('pillars',1.64,1.88,-1.35,-1.78,3.49,{mirror=true,warm=kind=='ghost',flowing=kind=='champion'})
 card('rail',4.36,0,-1.35,-1.54,3.58,{warm=kind=='ghost',flowing=kind=='champion'})
 -- The mobile's printed cord stays fixed while individual paper pendants move.
 local mobile=r.mobile;local sx=3.35*30/(mobile[3]-mobile[1]);local sy=52/(mobile[4]-mobile[2])
 local function mobileSlice(rect,motion,index)
  local h=(rect[4]-rect[2])*sy
  local d=card(rect,(rect[3]-rect[1])*sx/30,((rect[1]+rect[3]-mobile[1]-mobile[3])/2)*sx/30,
   81+(mobile[4]-rect[4])*sy,-1.45,3.70,{height=h,foldBaseY=81,foldOffset=(3.70-3.12)*.18,
    eventMotion=motion,eventIndex=index,pivot=h,leaguePiece=motion or 'fixedCord',leagueHabitat='league:'..kind})
  if motion then
   local attachment=({ghost={503,631,762},champion={521,635,750},dragon={625}})[kind][index]
   d.hingeX=(attachment-(rect[1]+rect[3])/2)*sx
  end
  return d
 end
 if kind=='ghost'or kind=='champion'then
  local cuts=kind=='ghost'and{446,563,707,816}or{451,574,696,820}
  mobileSlice({mobile[1],mobile[2],mobile[3],605})
  for i=1,3 do mobileSlice({cuts[i],605,cuts[i+1],mobile[4]},'leaguePendant',i)end
 elseif kind=='dragon'then
  mobileSlice({425,448,586,789})
  mobileSlice({667,448,833,789})
  mobileSlice({586,448,667,550})
  mobileSlice({586,550,667,698},'leagueBell',1)
 else
  card('mobile',3.35,0,81,-1.45,3.70,{height=52,sway=kind~='ice',oscillate=kind=='ice'and .065 or nil,pivot=51})
 end
 local crest=card('crest',kind=='dragon'and 1.90 or 1.54,0,29,-1.26,3.82,
  {haunt=kind=='ghost',floatY=kind=='ghost'and .85 or nil,oscillate=kind=='ice'and .035 or nil,pivot=25})
 if kind=='dark'or kind=='ice'then
  local h=(r.crest[4]-r.crest[2])*crest.width*30/(r.crest[3]-r.crest[1])
  crest.pivot=kind=='dark'and h or h/2
  crest.eventMotion=kind=='dark'and'leagueMedallion'or'leagueSnowflake';crest.eventIndex=1
  crest.leaguePiece=crest.eventMotion;crest.leagueHabitat='league:'..kind
 end
 card('podium',1.12,-2.10,-1.35,.64,4.05)
 card('podium',1.12,2.12,-1.35,.20,4.15)
 for i,p in ipairs({{-2.57,-.08},{2.57,-.08},{-1.85,2.06},{1.95,1.98}})do
  card('front',i<3 and .89 or .82,p[1],-1.35,p[2],4.18+i*.045,
   {mirror=i%2==0,sway=kind~='ice',warm=kind=='ghost',wave=kind=='champion'and i*.8 or nil})
 end
end
return layouts
