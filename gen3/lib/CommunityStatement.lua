-- Startup pages in physical screen space. No world/save is loaded by this modal.
local V=...
local M={pages=V.data('CommunityStatement')}
M.setting=V.require('ModSetting').new('gen3StatementOnStartup','Community statement at startup',{true,false},{'ON','OFF'},true)
function M.open(game,done)
 M.active={game=game,page=1,scroll=0,focus=1,done=done,held={}}
 if game.input then game.input:reset()end
end
function M.close()
 local a=M.active;M.active=nil
 if a and a.game.input then a.game.input:reset()end
end
function M.choose(index)
 local a=M.active;if not a then return end
 if a.page<#M.pages then a.page=a.page+1;a.scroll=0;a.focus=1;return end
 M.setting:setValue(index==1,a.game)
 local done=a.done;M.close();if done then done()end
end
local function fonts(size)
 M.fonts=M.fonts or{}
 if not M.fonts[size]then M.fonts[size]=love.graphics.newFont(size)end
 return M.fonts[size]
end
function M.layout()
 local a=assert(M.active);local W,H=love.graphics.getDimensions()
 local margin=math.max(12,math.min(32,W*.03));local width=W-margin*2;local x=(W-width)/2
 local f=fonts(W<600 and 18 or 20);local title=fonts(W<600 and 22 or 28);local small=fonts(14)
 local pad=math.max(14,math.min(28,width*.035));local textW=width-pad*2-16
 local _,titleLines=title:getWrap(M.pages[a.page].title,textW)
 local bodyY=margin+40+#titleLines*title:getHeight()+20
 local final=a.page==#M.pages;local stacked=final and W<640
 local footerH=stacked and 154 or 96;local bodyH=math.max(40,H-margin-footerH-bodyY)
 local paragraphs={};local contentH=0;local lineH=math.ceil(f:getHeight()*1.35)
 for _,p in ipairs(M.pages[a.page].paragraphs)do
  local _,lines=f:getWrap(p,textW)
  paragraphs[#paragraphs+1]={text=p,y=contentH,lines=lines}
  contentH=contentH+#lines*lineH+f:getHeight()
 end
 local maxScroll=math.max(0,contentH-f:getHeight()-bodyH)
 a.scroll=math.max(0,math.min(a.scroll,maxScroll))
 local buttons={};local labels=final and{'Keep showing at startup','Hide on future starts'}or{'Next'}
 local bw=stacked and textW or (#labels==1 and math.min(230,textW)or(textW-12)/2)
 for i,label in ipairs(labels)do
  buttons[i]={x=x+pad+(stacked and 0 or(i-1)*(bw+12)),y=bodyY+bodyH+36+(stacked and(i-1)*58 or 0),w=bw,h=50,label=label}
 end
 return {W=W,H=H,x=x,y=margin,w=width,h=H-margin*2,pad=pad,bodyX=x+pad,bodyY=bodyY,bodyH=bodyH,textW=textW,
  font=f,title=title,small=small,lineH=lineH,paragraphs=paragraphs,maxScroll=maxScroll,buttons=buttons}
end
function M.scroll(dy)local a=M.active;if a then local t=M.layout();a.scroll=math.max(0,math.min(t.maxScroll,a.scroll+dy))end end
function M.key(key,phase,isrepeat)
 local a=M.active;if not a then return false end
 if phase=='released'then a.held[key]=nil;return true end
 if phase~='pressed'then return true end
 if key=='up'or key=='down'or key=='pageup'or key=='pagedown'then
  M.scroll((key=='up'and -48)or(key=='down'and 48)or(key=='pageup'and -M.layout().bodyH*.85)or M.layout().bodyH*.85);return true
 end
 if a.held[key]or isrepeat then return true end;a.held[key]=true
 if key=='left'or key=='right'or key=='tab'then a.focus=a.page==#M.pages and(3-a.focus)or 1
 elseif key=='return'or key=='space'or key=='z'or key=='a'or key=='start'then M.choose(a.focus)
 elseif key=='home'then a.scroll=0
 elseif key=='end'then a.scroll=M.layout().maxScroll
 end
 return true
end
local function hit(b,x,y)return x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h end
function M.pointer(phase,id,x,y)
 local a=M.active;if not a then return false end
 if phase=='pressed'then a.pointer={id=id,x=x,y=y,lastY=y};return true end
 local p=a.pointer;if not p or p.id~=id then return true end
 if phase=='moved'then
  if math.abs(y-p.y)>8 then p.drag=true end
  if p.drag then M.scroll(p.lastY-y)end;p.lastY=y
 elseif phase=='released'then
  a.pointer=nil
  if not p.drag then for i,b in ipairs(M.layout().buttons)do if hit(b,x,y)and hit(b,p.x,p.y)then M.choose(i);break end end end
 end
 return true
end
function M.draw()
 local a=M.active;if not a then return end
 local g=love.graphics;local t=M.layout();local c=V.require('EditionAccent').ui()
 g.push('all');g.setCanvas();g.origin();g.setShader();g.setScissor();g.setDepthMode();g.setStencilTest();g.setColorMask(true,true,true,true);g.setBlendMode('alpha')
 g.setColor(c.back);g.rectangle('fill',0,0,t.W,t.H);g.setColor(c.back2);g.rectangle('fill',t.x,t.y,t.w,t.h,12,12)
 g.setColor(c.line);g.rectangle('line',t.x+.5,t.y+.5,t.w-1,t.h-1,12,12)
 g.setFont(t.small);g.setColor(c.muted);g.print('ORIGAMI ASCENDANT · Community statement',t.bodyX,t.y+14)
 g.setFont(t.title);g.setColor(c.text);g.printf(M.pages[a.page].title,t.bodyX,t.y+40,t.textW)
 g.setScissor(t.bodyX,t.bodyY,t.textW,t.bodyH);g.setFont(t.font)
 for _,p in ipairs(t.paragraphs)do for i,line in ipairs(p.lines)do g.print(line,t.bodyX,t.bodyY+p.y+(i-1)*t.lineH-a.scroll)end end
 g.setScissor();g.setFont(t.small);g.setColor(c.muted)
 g.print(string.format('Page %d / %d',a.page,#M.pages),t.bodyX,t.bodyY+t.bodyH+12)
 if t.maxScroll>0 then
  g.printf('Scroll: Up / Down · wheel · swipe',t.bodyX,t.bodyY+t.bodyH+12,t.textW,'right')
  local barH=math.max(22,t.bodyH*t.bodyH/(t.maxScroll+t.bodyH));local by=t.bodyY+(t.bodyH-barH)*a.scroll/t.maxScroll
  g.setColor(c.soft);g.rectangle('fill',t.bodyX+t.textW+8,t.bodyY,4,t.bodyH)
  g.setColor(c.accent);g.rectangle('fill',t.bodyX+t.textW+8,by,4,barH)
 end
 for i,b in ipairs(t.buttons)do
  g.setColor(i==a.focus and c.selected or c.glass);g.rectangle('fill',b.x,b.y,b.w,b.h,6,6)
  g.setColor(i==a.focus and c.focus or c.muted);g.rectangle('line',b.x+.5,b.y+.5,b.w-1,b.h-1,6,6)
  g.setFont(t.font);local _,lines=t.font:getWrap(b.label,b.w-16)
  g.printf(b.label,b.x+8,b.y+(b.h-#lines*t.font:getHeight())/2,b.w-16,'center')
 end
 g.pop()
end
return M
