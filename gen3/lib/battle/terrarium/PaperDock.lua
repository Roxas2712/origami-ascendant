-- Thin printed cardboard planks and folded supports beneath a fixed deck.
-- The top/actor plane is owned by EmeraldScene; this is decoration below it.
local P={}
function P.build(def)
 local faces,edges,posts,braces={},{},{},{}
 local function v(x,y,z,u,w,shade)return{x,y,z,u or 0,w or 0,shade or 1}end
 local function quad(out,a,b,c,d)for _,p in ipairs({a,b,c,a,c,d})do out[#out+1]=p end end
 -- Sample one original timber plank rather than compressing the full floor.
 local function board(out,a,b,c,d,shade)
  local uv={{230/1254,490/1254},{690/1254,490/1254},{690/1254,548/1254},{230/1254,548/1254}}
  local q={};for i,p in ipairs({a,b,c,d})do q[i]=v(p[1],p[2],p[3],uv[i][1],uv[i][2],shade)end
  quad(out,q[1],q[2],q[3],q[4])
 end
 local top=def.height-.08;local low=def.height-5.3;local radius=def.radius
 for i=0,23 do
  local a,b=i*math.pi/12+.002,(i+1)*math.pi/12-.002
  local function p(r,t,y)return{math.cos(t)*r,y,math.sin(t)*r}end
  board(faces,p(radius,a,top),p(radius,b,top),p(radius,b,low),p(radius,a,low),.84+(i%3)*.045)
  -- Exposed cardboard thickness at the top and at both cut ends of a plank.
  for _,q in ipairs({{p(radius,a,top),p(radius-.85,a,top),p(radius-.85,b,top),p(radius,b,top)},
   {p(radius,a,top),p(radius,a,low),p(radius-.85,a,low),p(radius-.85,a,top)},
   {p(radius,b,top),p(radius-.85,b,top),p(radius-.85,b,low),p(radius,b,low)}})do
   quad(edges,v(unpack(q[1])),v(unpack(q[2])),v(unpack(q[3])),v(unpack(q[4])))
  end
 end
 local supports={};local deep=(def.bottom or -2.25)<-10
 for i=0,5 do
  local a=math.pi/6+i*math.pi/3;local x,z=math.cos(a)*49,math.sin(a)*49
  local worldRadius=math.sqrt((x+(def.x or 0))^2+(z+(def.z or 0))^2)
  -- Embed all four feet in the curved seabed; no floating post bottoms.
  local bottom=deep and(-46+43*(worldRadius/100.85)^3-3)or -3.5
  supports[#supports+1]={x=x,z=z,bottom=bottom,top=top}
  local w=2.8
  for _,side in ipairs({{{x-w,z-w},{x+w,z-w}},{{x+w,z-w},{x+w,z+w}},{{x+w,z+w},{x-w,z+w}},{{x-w,z+w},{x-w,z-w}}})do
   local a,b=side[1],side[2]
   board(posts,{a[1],top,a[2]},{a[1],bottom,a[2]},{b[1],bottom,b[2]},{b[1],top,b[2]},.76)
  end
 end
 if deep then
  -- Two flat paper X braces in the front frame, above the seabed.
  local function brace(x0,y0,x1,y1,z)
   local dx,dy=x1-x0,y1-y0;local len=math.sqrt(dx*dx+dy*dy);local nx,ny=-dy/len*1.5,dx/len*1.5
   local a,b,c,d={x0+nx,y0+ny,z},{x1+nx,y1+ny,z},{x1-nx,y1-ny,z},{x0-nx,y0-ny,z}
   board(braces,a,b,c,d,.81)
   local e,f={a[1],a[2],z-.75},{b[1],b[2],z-.75}
   quad(edges,v(unpack(a)),v(unpack(b)),v(unpack(f)),v(unpack(e)))
  end
  brace(-42.44,-26,42.44,low,24.5)
  brace(42.44,-26,-42.44,low,23.5)
 end
 return{faces=faces,edges=edges,posts=posts,braces=braces,supports=supports,plankCount=24,top=top,bottom=low}
end
return P
