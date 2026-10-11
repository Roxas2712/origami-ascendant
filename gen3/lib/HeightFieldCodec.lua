-- Sparse height rows as float64 pairs. Geometry uses fractional coordinates
-- and heights: float32 would subtly change actor/contact/cutaway placement.
-- Bounded chunks avoid one recursive codec dispatch per key and value.
local H={}
local MAX_BYTES,MAX_ROWS,MAX_CELLS=128*1024*1024,1000000,2000000
local CHUNK=128
local formats={}
for n=1,CHUNK do formats[n]='<'..string.rep('dd',n)end
local function finite(v)
 return type(v)=='number'and v==v and math.abs(v)<math.huge
end
local function keys(t)
 assert(type(t)=='table','height row table')
 local out={};for k in pairs(t)do assert(finite(k),'height coordinate');out[#out+1]=k end
 table.sort(out);return out
end
function H.encode(field)
 local rows=keys(field);assert(#rows<=MAX_ROWS,'height row limit')
 local parts={'HGT1',love.data.pack('string','<I4',#rows)}
 local cells,size=0,8
 for _,z in ipairs(rows)do
  local row=field[z];local columns=keys(row)
  cells=cells+#columns;size=size+12+#columns*16
  assert(cells<=MAX_CELLS and size<=MAX_BYTES,'height size limit')
  parts[#parts+1]=love.data.pack('string','<dI4',z,#columns)
  for start=1,#columns,CHUNK do
   local values={};local count=math.min(CHUNK,#columns-start+1)
   for i=start,start+count-1 do
    local x=columns[i];local h=row[x];assert(finite(h),'height value')
    values[#values+1]=x;values[#values+1]=h
   end
   parts[#parts+1]=love.data.pack('string',formats[count],unpack(values))
  end
 end
 return table.concat(parts)
end
function H.decode(raw,checkpoint)
 assert(type(raw)=='string'and #raw>=8 and #raw<=MAX_BYTES and raw:sub(1,4)=='HGT1','height envelope')
 local rows,at=love.data.unpack('<I4',raw,5)
 assert(rows<=MAX_ROWS and rows<=math.floor((#raw-8)/12),'height row count')
 local out,cells={},0
 for _=1,rows do
  assert(at+11<=#raw,'truncated height row')
  local z,count;z,count,at=love.data.unpack('<dI4',raw,at)
  assert(finite(z)and out[z]==nil,'height row coordinate')
  cells=cells+count
  assert(cells<=MAX_CELLS and count<=math.floor((#raw-at+1)/16),'height cell count')
  local row={};out[z]=row
  for start=1,count,CHUNK do
   local n=math.min(CHUNK,count-start+1)
   local values={love.data.unpack(formats[n],raw,at)};at=values[n*2+1]
   for i=1,n*2,2 do
    local x,h=values[i],values[i+1]
    assert(finite(x)and finite(h)and row[x]==nil,'height cell value')
    row[x]=h
   end
   if checkpoint then checkpoint()end
  end
 end
 assert(at==#raw+1,'trailing height bytes')
 return out
end
return H
