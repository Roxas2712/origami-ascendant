-- VASC Controls presentation adapted to the native Gen3 modal controller.
-- Same rounded row cards, value/detail lines and six-row paging as VascControls.
local V=...
local Q={}
local L=V.require('MenuLocale')
function Q.layout(screen)
 local w,h=love.graphics.getDimensions()
 local width=math.min(500,w-16)
 if screen.quickHome then
  local columns=w>=360 and 2 or 1;local rows=math.ceil(#screen.items/columns)
  local rowHeight=math.min(76,math.floor((h-124)/rows));local height=112+rows*rowHeight
  local x,y=w-width-8,math.max(4,(h-height)/2)
  local t={panel={x,y,width,height},page=0,pages=1,title=screen.quickTitle,rows={},close={x+width-64,y+8,56,48},home=true}
  local cell=(width-24)/columns
  for index=1,#screen.items do
   t.rows[#t.rows+1]={index=index,rect={x+12+(index-1)%columns*cell,y+94+math.floor((index-1)/columns)*rowHeight,cell-8,rowHeight-8}}
  end
  return t
 end
 local perPage=math.max(1,math.min(6,math.floor((h-182)/64)))
 local breaks={};local previous,count=false,0
 for index,item in ipairs(screen.items)do
  if item.group~=previous or count>=perPage then breaks[#breaks+1]={first=index,title=item.group};count=0;previous=item.group end
  count=count+1;breaks[#breaks].last=index
 end
 local page=1
 for i,b in ipairs(breaks)do if screen.index>=b.first and screen.index<=b.last then page=i;break end end
 local current=breaks[page]or {first=1,last=0}
 local height=math.min(perPage,#screen.items)*64+166;local x=w-width-8;local y=math.max(4,(h-height)/2)
 local t={panel={x,y,width,height},perPage=perPage,page=page-1,pages=#breaks,title=current.title,rows={},
  prevIndex=breaks[math.max(1,page-1)].first,nextIndex=breaks[math.min(#breaks,page+1)].first,
  close={x+width-64,y+8,56,48},back={x+12,y+height-56,100,48}}
 if #breaks>1 then t.prev={x+width-172,y+height-56,76,48};t.next={x+width-88,y+height-56,76,48}end
 for index=current.first,current.last do
  t.rows[#t.rows+1]={index=index,rect={x+12,y+94+(index-current.first)*64,width-24,58}}
 end
 return t
end
local titles={gen3LiveDisplay='FPS-HUD',gen3LiveFps='FPS / Framezeit',gen3LiveClock='Uhr',
 gen3LiveCpu='CPU-Zeit',gen3LiveGpu='Grafikspeicher',gen3Quality='Qualität',
 gen3Lights='Licht',gen3OvAtmosphere='Atmosphäre',gen3OvPost='Nachbearbeitung'}
local details={gen3LiveDisplay='Live-Anzeige ein- oder ausblenden.',gen3LiveFps='Echte Bildrate und mittlere Zeit pro Frame.',
 gen3LiveClock='Lokale Uhrzeit des Computers.',gen3LiveCpu='Prozesszeit pro Frame, keine CPU-Auslastung.',
 gen3LiveGpu='Texturen und Canvas in MiB, keine GPU-Auslastung.',gen3Quality='Gemeinsame Vorgabe für die Darstellung.',
 gen3Lights='Fenster, Türen und Lichtquellen in der Welt.',gen3OvAtmosphere='Lichtstrahlen und Dunst im Wald.',
 gen3OvPost='Bloom, Tiefenunschärfe und Vignette.'}
function Q.draw(screen)
 local g=love.graphics;local t=Q.layout(screen)
 local p=V.require('EditionAccent').ui();local edition=V.require('EditionAccent').resolve()
 Q.font=Q.font or g.newFont(14);Q.small=Q.small or g.newFont(12)
 g.push('all');g.origin();g.setCanvas();g.setShader();g.setScissor();g.setDepthMode();g.setStencilTest();g.setBlendMode('alpha')
 local function box(r,active)
  g.setColor(active and p.selected or p.glass);g.rectangle('fill',r[1],r[2],r[3],r[4],7,7)
  g.setColor(p.line);g.setLineWidth(1);g.rectangle('line',r[1]+.5,r[2]+.5,r[3]-1,r[4]-1,7,7)
 end
 local function label(text,x,y,font,color)g.setFont(font or Q.font);g.setColor(color or p.text);g.print(text,x,y)end
 -- Draw only the panel over the live field. A full-screen dimmer made the
 -- dark forest look as though the game had disappeared behind the menu.
 box(t.panel);local x,y=t.panel[1],t.panel[2]
 label(L.text('ORIGAMI · Quick settings · ','ORIGAMI · Schnellmenü · ')..L.text(edition.id=='firered'and 'FireRed'or edition.id=='leafgreen'and 'LeafGreen'or edition.label,edition.label),x+14,y+12)
 label(V.require('MenuHint').mobile(screen.game)and L.text('Tap a row to change · ×: close','Zeile antippen zum Ändern · ×: schließen')or L.text('Arrows: select · Enter / A: change · F3: close','Pfeile: wählen · Enter / A: ändern · F3: schließen'),x+14,y+38,Q.small,p.muted)
 label(t.title or'',x+14,y+66,Q.small,p.focus)
 box(t.close);label('×',t.close[1]+21,t.close[2]+12)
 for _,entry in ipairs(t.rows)do
  local r,item=entry.rect,screen.items[entry.index];box(r,screen.index==entry.index)
  label(L.text(item.label or'All settings',titles[item.key]or item.label or'Alle Einstellungen'),r[1]+10,r[2]+4)
  if not t.home then label(item.right or L.text('Open','Öffnen'),r[1]+10,r[2]+24,Q.small,p.focus)end
  local detail=L.text(item.help or'Open the full Origami settings.',details[item.key]or item.help or'Das vollständige Origami-Menü öffnen.')
  if item.key=='gen3BattleView'then
   -- The complete startup traceback is too wide for this row. Keep its
   -- actionable compatibility reason visible instead of hiding all help.
   local reason=detail:match('OASC presentation: ([^\n]+)')
   if reason then detail='OASC: '..reason end
  end
  if Q.small:getWidth(detail)<=r[3]-20 then label(detail,r[1]+10,r[2]+(t.home and 32 or 40),Q.small,p.muted)end
 end
 if t.back then box(t.back);label(L.text('‹ Back','‹ Zurück'),t.back[1]+12,t.back[2]+14,Q.small)end
 if t.prev then
  box(t.prev);box(t.next);label('‹',t.prev[1]+31,t.prev[2]+12);label('›',t.next[1]+31,t.next[2]+12)
  label((t.page+1)..' / '..t.pages,x+t.panel[3]/2-16,t.prev[2]+14)
 end
 g.pop()
 return t
end
return Q
