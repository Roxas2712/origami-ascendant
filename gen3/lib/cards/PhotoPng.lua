-- Lossless RGBA8 PNG for one-shot photos. Filter 0 + fast zlib avoids the
-- multi-second adaptive filtering of the general image encoder at 4x size.
-- Format: https://www.w3.org/TR/png-3/ (IHDR, IDAT, IEND; PNG CRC-32).
local P={};local bit=require('bit');local bxor,band,rshift=bit.bxor,bit.band,bit.rshift
local crcTable={}
for i=0,255 do
 local c=i;for _=1,8 do c=band(c,1)==1 and bxor(rshift(c,1),0xEDB88320)or rshift(c,1)end
 crcTable[i]=c
end
local function u32(n)
 return string.char(band(rshift(n,24),255),band(rshift(n,16),255),band(rshift(n,8),255),band(n,255))
end
local function chunk(kind,data)
 local s=kind..data;local crc=-1
 for i=1,#s do crc=bxor(rshift(crc,8),crcTable[band(bxor(crc,s:byte(i)),255)])end
 return u32(#data)..s..u32(bit.bnot(crc))
end
function P.encode(data)
 assert(data:getFormat()=='rgba8','photo PNG requires rgba8')
 local w,h=data:getDimensions();local raw=data:getString();local stride=w*4;local rows={}
 for y=0,h-1 do rows[y+1]='\0'..raw:sub(y*stride+1,(y+1)*stride)end
 local compressed=love.data.compress('string','zlib',table.concat(rows),1)
 return '\137PNG\13\10\26\10'..chunk('IHDR',u32(w)..u32(h)..string.char(8,6,0,0,0))
  ..chunk('IDAT',compressed)..chunk('IEND','')
end
return P
