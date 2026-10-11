-- Rare, purely visual movement behind Lavender's dark tower panes.
-- Stateless schedule: never consumes the game's RNG or changes save data.
local V=...
local G={}
local function hash(n)return (math.sin(n*127.1+311.7)*43758.5453)%1 end
function G.sample(seconds,night,mapId)
 local c=V.require('DioramaConfig').ghostWindows
 if not c.enabled or mapId~='FR_LAVENDER_TOWN' or night<=0 then return {0,0,0,0} end
 local period=math.max(c.duration+c.delay+c.jitter+1,c.period)
 local block=math.floor(math.max(0,seconds)/period)
 local elapsed=seconds-block*period-c.delay-hash(block+1)*c.jitter
 local u=elapsed/c.duration
 if u<=0 or u>=1 then return {0,0,0,0} end
 local direction=hash(block+9)<.5 and 1 or -1
 local t=direction==1 and u or 1-u
 local row=c.rows[math.min(#c.rows,1+math.floor(hash(block+5)*#c.rows))]
 local track=c.tracks[1+math.floor(hash(block+17)*#c.tracks)]
 local x=track.left+(track.right-track.left)*t
 local y=row+(track.offset or 0)+(x-(track.origin or 0))*(track.slope or 0)
 local fade=math.min(1,u*6,(1-u)*6)
 return {x,y+math.sin(u*math.pi*2)*.6,c.opacity*night*fade,direction},track.name
end
-- The narrow, sloping side panes have a different native palette from
-- front glass. A separate mask channel must not make them emissive.
function G.sidePane(x,y,r,g,b)
 return ((x>=14 and x<=21) or (x>=90 and x<=97)) and y<46
  and math.abs(r-90/255)<.002 and math.abs(g-115/255)<.002 and math.abs(b-90/255)<.002
end
function G.bind(shader,seconds,night,mapId)
 local pass=G.sample(seconds,night,mapId);shader:send('ghostPass',pass)
 shader:send('ghostColor',V.require('DioramaConfig').ghostWindows.color)
end
G.fragment=[[
vec3 ghostBehindPane(vec3 lit,vec2 sourcePixel){
 // A small pixel silhouette, cropped by the original glass mask by caller.
 // No emissive term, bloom source, geometry or light emitter is introduced.
 vec2 q=floor(sourcePixel)+vec2(.5)-ghostPass.xy;
 float head=1.0-smoothstep(.8,1.15,length(q/vec2(2.0,2.2)));
 float body=(1.0-smoothstep(1.2,2.5,abs(q.x+sin(q.y*.8)*.45)))
   *step(0.0,q.y)*(1.0-smoothstep(3.0,6.0,q.y));
 return mix(lit,ghostColor,max(head,body)*ghostPass.z);
}
]]
return G
