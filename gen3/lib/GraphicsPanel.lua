-- Origami's folded-paper inspector. Presentation only; the overlay owns input
-- and the existing settings retain their values and persistence.
local V=...
local P={}
local L=V.require('MenuLocale')
local englishNames={tilt='Angle',terrain='Terrain height',post='Post effects',bloom='Bloom',tilt_shift='Depth blur',shadows='Shadows',clouds='Clouds',lighting='Time of day',windows='Window variation',cloudlight='Cloud light',seasons='Seasons',atmosphere='Atmosphere',texture='Wind animation'}
local englishHints={tilt='View angle over the world.',terrain='Tree and terrain height.',post='Final image effects.',bloom='Glow around bright areas.',tilt_shift='Blur beyond the focus area.',shadows='Shadows beneath objects.',clouds='Moving cloud shadows.',lighting='Time and light mood.',windows='Original restores earlier light.',cloudlight='Sunshine and cloud cover.',seasons='Foliage colours. Original: off.',atmosphere='Forest shafts and haze.',texture='Gentle foliage movement.'}
local groups={{title='KAMERA',first=1,last=3},{title='BILD',first=4,last=6},{title='WELT',first=7,last=nil}}
englishNames.battle_tilt='Battle angle';englishHints.battle_tilt='Independent map battle camera.'
local names={battle_tilt='Kampfwinkel',tilt='Neigung',terrain='Raumtiefe',post='Bildeffekte',bloom='Leuchten',
 tilt_shift='Tiefenschaerfe',shadows='Schatten',clouds='Wolken',lighting='Tageslicht',windows='Fensterleben',cloudlight='Wolkenlicht',seasons='Jahreszeiten',
 atmosphere='Atmosphaere',texture='Wind & Bewegung'}
local words={OFF='AUS',ON='AN',NORMAL='NORMAL',TALL='HOCH',FULL='ALLE',BLOOM='LEUCHTEN',
 SUBTLE='SANFT',STRONG='STARK',CYCLE='VERLAUF',MORNING='MORGEN',DAY='TAG',EVENING='ABEND',DUSK='DAEMMERUNG',NIGHT='NACHT'}
local hints={battle_tilt='Eigene Kamera fuer Kartenkaempfe.',tilt='Blickwinkel auf die Spielwelt.',terrain='Hoehe von Baeumen und Gelaende.',
 post='Effekte auf das fertige Bild.',bloom='Staerke heller Lichtsaeume.',tilt_shift='Schaerfe vor und hinter der Figur.',
 shadows='Schatten unter Objekten.',clouds='Ziehende Wolkenschatten.',lighting='Tageszeit und Lichtstimmung.',windows='Original stellt altes Licht her.',cloudlight='Wechsel von Sonne und Wolken.',seasons='Pflanzenfarben. Original: aus.',
 atmosphere='Waldstrahlen und Dunst.',texture='Sanfte Bewegung im Gruen.'}
function P.draw(rows,cursor,valueLabel,padHint,hidden)
 local g=love.graphics;local F=V.require('MenuFont');local theme=V.require('EditionAccent').ui()
 local edition=V.require('EditionAccent').resolve()
 local W,H=g.getDimensions();local pw,ph=226,388+math.max(0,#rows-12)*21
 local scale=math.max(1,math.floor(math.min(W*.42/pw,(H-24)/ph)))
 local x,y=math.max(8,W-pw*scale-16),math.max(8,math.floor((H-ph*scale)/2))
 local function text(s,xx,yy,col)g.setColor(col or theme.text);F.draw(s,xx,yy)end
 local function width(s)local n=0;for _,c in ipairs(F.split(s))do n=n+F.advanceOf(c.code)end;return n end
 g.push('all');g.origin();g.setCanvas();g.setShader();g.setScissor();g.setDepthMode();g.setStencilTest();g.setBlendMode('alpha')
 g.translate(x,y);g.scale(scale)
 local shape={0,7,7,0,pw-16,0,pw,16,pw,ph-7,pw-7,ph,0,ph}
 g.push();g.translate(3,4);g.setColor(0,0,0,.24);g.polygon('fill',shape);g.pop()
 g.setColor(theme.glass);g.polygon('fill',shape)
 g.setColor(theme.line);g.setLineWidth(1/scale);g.polygon('line',shape)
 -- Folded top corner and offset seam give this panel its own silhouette.
 g.setColor(theme.soft);g.polygon('fill',pw-16,0,pw-16,16,pw,16)
 g.setColor(theme.line);g.line(pw-16,0,pw-16,16,pw,16)
 text('ORIGAMI / '..string.upper(L.text(edition.id=='firered'and 'FireRed'or edition.id=='leafgreen'and 'LeafGreen'or edition.label,edition.label)),12,9,theme.muted)
 text(L.text('IMAGE & ATMOSPHERE','BILD & ATMOSPHAERE'),12,23,theme.text)
 g.setColor(theme.accent);g.rectangle('fill',12,38,24,2)
 g.setColor(theme.soft);g.rectangle('fill',39,38,pw-51,1/scale)
 local yy=48
 for n,group in ipairs(groups)do
  text(string.format('0%d',n),12,yy,theme.focus)
  text(L.text(({ 'CAMERA','IMAGE','WORLD'})[n],group.title),31,yy,theme.muted)
  g.setColor(theme.soft);g.line(78,yy+4,pw-12,yy+4)
  yy=yy+14
  for i=group.first,group.last or #rows do
   local row=rows[i];local active=i==cursor
   if not(hidden and hidden[row.id])then
   if active then
    g.setColor(theme.selected);g.polygon('fill',7,yy, pw-7,yy,pw-7,yy+19,12,yy+19,7,yy+14)
    g.setColor(theme.accent);g.rectangle('fill',7,yy,2,19)
   end
   text(L.text(englishNames[row.id]or row.label,names[row.id]or row.label),14,yy+4,active and theme.text or theme.muted)
   local raw=valueLabel(row);local val=L.text(L.choice(raw),words[raw]or raw:gsub(' DEG',' GRAD'))
   local right=pw-18
   if raw=='ON' or raw=='OFF' then
    local on=raw=='ON';local tx=right-43
    g.setColor(on and theme.focus or theme.muted);g.rectangle('line',tx,yy+8,15,7)
    g.rectangle('fill',tx+(on and 9 or 2),yy+10,4,3)
    text(val,right-width(val),yy+4,on and theme.focus or theme.muted)
   else
    text(val,right-width(val),yy+4,active and theme.focus or theme.text)

   end
   if active then text('>',pw-12,yy+4,theme.focus)end
   yy=yy+21
   end
  end
 end
 g.setColor(theme.soft);g.line(12,ph-39,pw-12,ph-39)
 text(L.text(englishHints[rows[cursor].id]or'',hints[rows[cursor].id]or''),12,ph-32,theme.muted)
 text(L.text(padHint and 'D-PAD: VALUE   R+SELECT: CLOSE' or 'ARROWS: SELECT / VALUE  F7: CLOSE',padHint and 'STEUERKREUZ: WERT   R+SELECT: ZU' or 'PFEILE: WAHL / WERT    F7: ZU'),12,ph-18,theme.focus)
 g.pop()
end
return P
