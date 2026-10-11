-- Native FireRed glyphs behind the shared VASC menu's font interface.
local Native=require("src.ui.game3.frlg_font")
local F={}
function F.split(text)
 local out={}
 for at,ch in tostring(text or ""):gmatch("()([%z\1-\127\194-\244][\128-\191]*)")do
  out[#out+1]={from=at,to=at+#ch-1,code=Native.glyphId(ch)}
 end
 return out
end
function F.advanceOf(code)return Native.advance(code,{small=true}) end
function F.spansFitting(spans,width)
 local used=0
 for i,s in ipairs(spans)do used=used+F.advanceOf(s.code);if used>width then return i-1 end end
 return #spans
end
function F.drawCode(code,x,y)
 local r,g,b,a=love.graphics.getColor()
 Native.drawGlyph(code,x,y,{small=true,colors={fg={r,g,b,a},shadow={0,0,0,0}}})
end
function F.draw(text,x,y)
 for _,s in ipairs(F.split(text))do F.drawCode(s.code,x,y);x=x+F.advanceOf(s.code) end
end
return F
