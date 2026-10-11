-- Rendering-only compatibility seam for gen1recomp 0.3.74.
-- Derived from src/core/game3/battle/ui.lua by BOIS CLUB GAMES, LLC (2026).
-- License: gen3/compat/ENGINE-LICENSE.MD (GPLv3 with additional terms).
-- Source SHA256: 3a9b46421ed524bf5ab5e2d1fa573f196acfbc458cc26aea4693de4458960d2e
-- Generated dependency closure: native draw helpers only; no input, commands,
-- battle clock, state initialization, save handling or rules are replaced.
-- OASC adds presentation callbacks; native Ui state is passed by reference.
local Ui=...
local Choice = require("src.ui.game3.choice")

local Moves = require("src.core.game3.battle.moves")

local Display = require("src.core.game3.display")

local FrlgFont = require("src.ui.game3.frlg_font")

local BattleChrome = require("src.ui.game3.battle_chrome")

local BattleBg = require("src.core.game3.battle.bg")

local Healthbox = require("src.core.game3.battle.healthbox")

local Pokemon = require("src.core.game3.pokemon")

local Window = require("src.ui.game3.window")

local Types = require("src.core.game3.battle.types")

local BallOpen = require("src.core.game3.battle.ball_open")

local Strings = require("src.core.Strings")

local RomText = require("src.core.game3.rom_text")

local BattleText = require("src.core.game3.battle.battle_text")

local SummaryChrome = require("src.ui.game3.summary_chrome")

local Anim = require("src.core.game3.battle.anim")

local PicCoords = require("src.core.game3.battle.pic_coords")

local TrainerPic = require("src.core.game3.trainer_pic")

local LevelUpStreaks = require("src.core.game3.battle.level_up_streaks")

local bit = require("bit")

local function stat_window_phase()
  local Battle = package.loaded["src.core.game3.battle.init"]
  if not (Battle and Battle.statWindowPhase) then return true end
  return Battle.statWindowPhase()
end

local ENEMY_MON = { x = 176, y = 40 }

local PLAYER_MON = { x = 72, y = 80 }

local SPECIES_CASTFORM = 385

local CASTFORM_FRONT_Y = { [0] = 17, 9, 9, 8 }

local CASTFORM_ELEV = { [0] = 13, 14, 13, 13 }

local CASTFORM_BACK_Y = { [0] = 0, 0, 0, 0 }

local function live_battler(side)
  local Battle = package.loaded["src.core.game3.battle"]
  local st = Battle and Battle._st
  local Anim = package.loaded["src.core.game3.battle.anim"]
  local b
  if type(side) == "number" then
    b = st and ((side == 0 and st.player) or (side == 1 and st.enemy) or (st.battlers and st.battlers[side]))
  else
    b = st and st[side]
  end
  if Anim and Anim.shownBattler then b = Anim.shownBattler(side, b) end
  return b, st
end

local function castform_form(side, battler)
  local Anim = package.loaded["src.core.game3.battle.anim"]
  local pres = Anim and Anim._present and Anim._present[side]
  if not (pres and battler and pres.castformForm ~= nil) then return 0 end
  if pres.castformMon ~= nil and pres.castformMon ~= battler.mon then return 0 end
  local f = (tonumber(pres.castformForm) or 0) % 128
  if f < 0 or f > 3 then return 0 end
  return f
end

local function shows_ghost(side, st)
  if side ~= "enemy" or not (st and st.ghostBattle) then return false end
  local Anim = package.loaded["src.core.game3.battle.anim"]
  local pres = Anim and Anim._present and Anim._present.enemy
  return not (pres and pres.ghostUnveiled)
end

local function is_double(st)
  st = st or Ui._st
  return type(st) == "table" and st.double == true
end

local function battler_sprite_center(side, species, base, form, ghost)
  local p=Ui.presentation
  if p and p.center then local x,y=p.center(side,species,form,ghost);if x~=nil then return x,y end end
  local ui = require("src.core.game3.profile").forSession().ui
  local rs = ui and ui.battleSpriteLayout == "rs"
  if type(side) == "number" then
    local id = side
    side = (id % 2 == 0) and "player" or "enemy"
    local _, st = live_battler(id)
    base = base or (PicCoords and PicCoords.battlerCoords and PicCoords.battlerCoords(is_double(st), id))
    if not rs and is_double(st) and side == "player" and PicCoords and species then
      local sp = tonumber(species) or 0
      local yo = (PicCoords.back and PicCoords.back[sp]) or 0
      if sp == SPECIES_CASTFORM then yo = CASTFORM_BACK_Y[form or 0] or 0 end
      -- pokefirered/src/battle_anim_mons.c:252
      local y = math.min(base.y + yo + 8, 160 - 64 + 8)
      return base.x, y - 4
    end
  end
  local cx, cy = base.x, (side == "player" and not rs) and (base.y - 4) or base.y
  if not PicCoords or not species then return cx, cy end
  local sp = tonumber(species) or 0
  if ghost == nil or (form == nil and sp == SPECIES_CASTFORM) then
    local b, st = live_battler(side)
    if ghost == nil then ghost = shows_ghost(side, st) end
    if form == nil and sp == SPECIES_CASTFORM then form = castform_form(side, b) end
  end
  if side == "player" then
    local yo = (PicCoords.back and PicCoords.back[sp]) or 0
    if sp == SPECIES_CASTFORM then yo = CASTFORM_BACK_Y[form or 0] or 0 end
    -- pokeruby/src/rom_8077ABC.c:305
    cy = base.y + yo + (rs and 0 or 4)
  elseif ghost then
    -- pokefirered/src/battle_anim_mons.c:297
    cy = base.y
  else
    local yo = (PicCoords.front and PicCoords.front[sp]) or 0
    local elev = (PicCoords.elev and PicCoords.elev[sp]) or 0
    if sp == SPECIES_CASTFORM then
      yo = CASTFORM_FRONT_Y[form or 0] or yo
      elev = CASTFORM_ELEV[form or 0] or elev
    end
    cy = base.y + yo - elev
  end
  return cx, cy
end

local function pic_args(battler, sp)
  local mon = battler and battler.mon
  local personality = mon and mon.personality
  local tf = battler and battler.expTransform
  if tf and tonumber(tf.species) == tonumber(sp) and tf.personality ~= nil then
    personality = tf.personality
  end
  return Pokemon.picSpecies(sp, personality), Pokemon.isShiny(mon), personality
end

local function active_battler(st)
  st = st or Ui._st
  if not st then return nil end
  local id = Ui._active or 0
  if id == 0 then return st.player end
  return st.battlers and st.battlers[id]
end

local function band(a, b)
  local bit = require("bit")
  return bit.band(tonumber(a) or 0, tonumber(b) or 0)
end

local function absent(st, id)
  if not st then return true end
  if st.absent and st.absent[id] then return true end
  local b = (id == 0 and st.player) or (id == 1 and st.enemy) or (st.battlers and st.battlers[id])
  return b == nil
end

local function draw_menu_text(text, x, y, opts)
  opts = opts or {}
  FrlgFont.draw(tostring(text or ""), x, y, {
    small = opts.small ~= nil and opts.small or false,
    colors = opts.colors or FrlgFont.COLOR.NORMAL,
  })
end

local function pp_text_colors(currentPp, maxPp)
  local manifest = SummaryChrome.manifest and SummaryChrome.manifest()
  local rows = manifest and manifest.moveTextColors
  local row = rows and rows[Ui.ppColorIndex(currentPp, maxPp)]
  if not row then return FrlgFont.COLOR.NORMAL end
  local function rgb(c)
    return { (c[1] or 0) / 255, (c[2] or 0) / 255, (c[3] or 0) / 255, 1 }
  end
  return { fg = rgb(row.fg), shadow = rgb(row.shadow), bg = FrlgFont.STDPAL[0] }
end

local function draw_prompt_text(text, x, y)
  FrlgFont.draw(tostring(text or ""), x, y, {
    colors = FrlgFont.COLOR.WHITE,
  })
end

local GRAY_SHADER_SRC = [[
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec4 c = Texel(tex, tc) * color;
  vec3 c5 = floor(c.rgb * 31.0 + 0.5);
  float g = floor((c5.r + c5.g + c5.b) / 3.0);
  return vec4(vec3(g / 31.0), c.a);
}
]]

local grayShader = nil

local function set_gray_shader()
  if grayShader == nil then
    local ok, sh = pcall(love.graphics.newShader, GRAY_SHADER_SRC)
    grayShader = ok and sh or false
  end
  if not grayShader then return false end
  love.graphics.setShader(grayShader)
  return true
end

local STAT_MASK_SRC = [[
extern Image maskTex;
extern vec2 origin;
extern vec2 size;
extern vec2 scroll;
extern float flip;
extern float eva;
extern float darken;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec4 m = Texel(tex, tc);
  if (m.a < 0.01) discard;
  vec2 t = tc;
  if (flip > 0.5) t.x = 1.0 - t.x;
  vec2 pos = floor(origin + t * size);
  vec4 k = Texel(maskTex, (pos + scroll + vec2(0.5)) / 256.0);
  if (k.a < 0.01) discard;
  if (darken > 0.5) return vec4(0.0, 0.0, 0.0, eva);
  return vec4(k.rgb, eva);
}
]]

local statMaskShader = nil

local function draw_stat_mask(pres, img, cx, cy, sx, sy)
  local sm = pres and pres.statMask
  if not (sm and (tonumber(sm.eva) or 0) > 0) then return end
  local Anim = require("src.core.game3.battle.anim")
  local vm = Anim.vm and Anim.vm()
  if not (vm and vm.active) then return end
  local mask = Anim.statMaskImage(sm.tilemap, sm.pal)
  if not mask then return end
  if statMaskShader == nil then
    local ok, sh = pcall(love.graphics.newShader, STAT_MASK_SRC)
    statMaskShader = ok and sh or false
  end
  if not statMaskShader then return end
  local iw, ih = img:getDimensions()
  local w, h = iw * math.abs(sx), ih * math.abs(sy)
  local ok = pcall(function()
    statMaskShader:send("maskTex", mask)
    statMaskShader:send("origin", { cx - 32 * math.abs(sx), cy - 32 * math.abs(sy) })
    statMaskShader:send("size", { w, h })
    statMaskShader:send("scroll", { tonumber(sm.x) or 0, tonumber(sm.y) or 0 })
    statMaskShader:send("flip", sx < 0 and 1 or 0)
    statMaskShader:send("eva", math.min(1, (tonumber(sm.eva) or 0) / 16))
    statMaskShader:send("darken", 0)
  end)
  if not ok then return end
  local eva = math.min(16, tonumber(sm.eva) or 0)
  local evb = sm.evb and math.min(16, tonumber(sm.evb) or 0) or (16 - eva)
  love.graphics.setShader(statMaskShader)
  love.graphics.setColor(1, 1, 1, 1)
  if eva + evb ~= 16 then
    -- pokefirered/src/battle_anim_utility_funcs.c:306
    pcall(function()
      statMaskShader:send("darken", 1)
      statMaskShader:send("eva", 1 - evb / 16)
    end)
    love.graphics.draw(img, cx, cy, 0, sx, sy, 32, 32)
    pcall(function()
      statMaskShader:send("darken", 0)
      statMaskShader:send("eva", eva / 16)
    end)
    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.draw(img, cx, cy, 0, sx, sy, 32, 32)
    love.graphics.setBlendMode("alpha", "alphamultiply")
  else
    love.graphics.draw(img, cx, cy, 0, sx, sy, 32, 32)
  end
  love.graphics.setShader()
end

local MOSAIC_SRC = [[
extern vec2 texSize;
extern float block;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec2 px = floor(tc * texSize / block) * block;
  return Texel(tex, (px + vec2(0.5)) / texSize) * color;
}
]]

local mosaicShader = nil

local function set_mosaic_shader(img, level)
  if mosaicShader == nil then
    local ok, sh = pcall(love.graphics.newShader, MOSAIC_SRC)
    mosaicShader = ok and sh or false
  end
  if not mosaicShader then return false end
  local iw, ih = img:getDimensions()
  local ok = pcall(function()
    mosaicShader:send("texSize", { iw, ih })
    mosaicShader:send("block", (tonumber(level) or 0) + 1)
  end)
  if not ok then return false end
  love.graphics.setShader(mosaicShader)
  return true
end

local AFFINE_SRC = [[
extern float m;
extern vec3 off;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec4 c = Texel(tex, tc) * color;
  return vec4(clamp(c.rgb * m + off, 0.0, 1.0), c.a);
}
]]

local affineShader = nil

local function set_affine_shader(st)
  if type(st) ~= "table" then return false end
  if affineShader == nil then
    local ok, sh = pcall(love.graphics.newShader, AFFINE_SRC)
    affineShader = ok and sh or false
  end
  if not affineShader then return false end
  local ok = pcall(function()
    affineShader:send("m", tonumber(st.m) or 1)
    affineShader:send("off", { tonumber(st.r) or 0, tonumber(st.g) or 0, tonumber(st.b) or 0 })
  end)
  if not ok then return false end
  love.graphics.setShader(affineShader)
  return true
end

local rowQuads = {}

local function row_quad(iw, ih, r)
  local key = iw * 100000 + ih * 100 + r
  local q = rowQuads[key]
  if not q then
    q = love.graphics.newQuad(0, r, iw, 1, iw, ih)
    rowQuads[key] = q
  end
  return q
end

local function bg_blend_params(bb)
  if type(bb) ~= "table" then return nil end
  local coeff = tonumber(bb.coeff) or 0
  if coeff <= 0 then return nil end
  local c = bb.color
  if type(c) == "number" then
    return coeff, c % 32, math.floor(c / 32) % 32, math.floor(c / 1024) % 32
  elseif type(c) == "table" then
    return coeff, (c[1] or 0) * 31, (c[2] or 0) * 31, (c[3] or 0) * 31
  end
  return coeff, 0, 0, 0
end

local function draw_mon_sprite(battler, base, back, id)
  local p=Ui.presentation
  if p and p.drawBattler and p.drawBattler(back and "player" or "enemy",battler,id)then return end
  if not battler then return end
  local side = back and "player" or "enemy"
  local key = id or side
  local pres = Anim.present(key)
  if pres and (pres.visible == false or pres.blinkHidden or pres.battlerInvisible or pres.invisible) then return end
  if id and Ui.targetHidden(id) then return end
  battler = Anim.shownBattler(key, battler) or battler

  local sp = battler.species
  if not sp and battler.mon and Pokemon.speciesOf then
    sp = Pokemon.speciesOf(battler.mon)
  elseif not sp and battler.mon then
    sp = battler.mon.species or battler.mon.speciesId
  end
  local tf = nil
  if battler.expTransform then
    tf = pres and pres.transformSpecies
    if not tf and not (pres and pres.pendingTransform) then tf = battler.expTransform.species end
  end
  if tf then sp = tf end
  local ghost = shows_ghost(side, Ui._st)
  local form = (tonumber(sp) == SPECIES_CASTFORM) and castform_form(side, battler) or 0
  local cx, cy = battler_sprite_center(id or side, sp, base, form, ghost)
  if pres then
    cx = cx + (pres.ox or 0)
    cy = cy + (pres.oy or 0)
  end
  cy = cy + Ui.bounceOffset("mon", id or (back and 0 or 1))
  local scale = (pres and pres.scale) or 1
  local darken = (pres and pres.darken) or 0
  local entry
  local dollImg = pres and pres.substitute and Anim.substituteImage(key)
  if dollImg then
    -- pokefirered/src/battle_gfx_sfx_util.c:794
    entry = { image = dollImg }
    cx = base.x + (pres.ox or 0)
    cy = (pres.substituteY or Anim.substituteY(key)) + (pres.oy or 0)
  end
  if not entry and ghost and Pokemon.ghostPic then
    entry = Pokemon.ghostPic()
  end
  local picSp, shiny, personality = pic_args(battler, sp)
  if not entry and back and Pokemon.backPic then
    if Ui.presentation and Ui.presentation.frontSprites then entry=Pokemon.frontPic(picSp,form,shiny,personality)
    else entry = Pokemon.backPic(picSp, form, shiny)end
  end
  if not entry then
    entry = Pokemon.frontPic and Pokemon.frontPic(picSp, form, shiny, personality)
  end
  if (not back or Ui.presentation and Ui.presentation.frontSprites) and not ghost and not dollImg and pres and (tonumber(pres.monFrame) or 0) ~= 0 then
    -- pokeemerald/src/sprite.c:917
    entry = require("src.core.game3.mon_anim").framePic(picSp, pres.monFrame, shiny) or entry
  end
  if entry and entry.image then
    local a = (pres and pres.alpha) or 1
    local flash = pres and (pres.flash or 0) or 0
    local shade = 1 - darken * (1 - 8 / 255)
    if flash > 0 then
      love.graphics.setColor(1, 1, 1, a * (0.4 + 0.6 * ((flash % 2 == 0) and 1 or 0.3)))
    else
      love.graphics.setColor(shade, shade, shade, a)
    end
    local hFlip = (pres and pres.hFlip) and true or false
    if p and p.frontSprites and back and not dollImg then hFlip=not hFlip end
    if p and p.scale then scale=scale*p.scale(side,sp,form,id)end
    local sx = (hFlip and -1 or 1) * scale * ((pres and pres.sx) or 1)
    local sy = scale * ((pres and pres.sy) or 1)
    local rot = (pres and pres.rotation) or 0
    if p and p.poseCenter then
      local x,y=p.poseCenter(side,entry.image,cx,cy,rot,sx,sy,pres,battler,id)
      if x~=nil then cx,cy=x,y end
    end
    local blended
    if id then
      blended = BallOpen.setBlendShader(BallOpen.monBlend(id))
      if not blended and id < 2 then blended = BallOpen.setBlendShader(BallOpen.monBlend(side)) end
    else
      blended = BallOpen.setBlendShader(BallOpen.monBlend(side))
    end
    if not blended and pres then
      if pres.palAffine then
        blended = set_affine_shader(pres.palAffine)
      elseif (tonumber(pres.mosaic) or 0) > 0 then
        blended = set_mosaic_shader(entry.image, pres.mosaic)
      elseif pres.grayscale then
        blended = set_gray_shader()
      elseif (tonumber(pres.blendCoeff) or 0) > 0 then
        local c = pres.blendColor or { 1, 1, 1 }
        blended = BallOpen.setBlendShader(pres.blendCoeff * 16, (c[1] or 0) * 31, (c[2] or 0) * 31, (c[3] or 0) * 31)
      end
    end
    if not blended and tf and not dollImg then
      -- pokefirered/src/battle_gfx_sfx_util.c:747
      blended = BallOpen.setBlendShader(6, 31, 31, 31)
    end
    if not blended and id then
      local pc = Ui.previewCoeff(id)
      -- pokefirered/src/battle_controller_player.c:2987
      if pc > 0 then blended = BallOpen.setBlendShader(pc, 31, 31, 31) end
    end
    if pres and type(pres.hShift) == "table" and rot == 0 and sy == 1 then
      local img = entry.image
      local iw, ih = img:getDimensions()
      local top = math.floor(cy - 32 + 0.5)
      for r = 0, ih - 1 do
        local q = row_quad(iw, ih, r)
        local dx = tonumber(pres.hShift[top + r]) or 0
        love.graphics.draw(img, q, cx + dx, top + r, 0, sx, 1, 32, 0)
      end
    else
      love.graphics.draw(entry.image, cx, cy, rot, sx, sy, 32, 32)
    end
    if blended then love.graphics.setShader() end
    if pres and pres.statMask and not dollImg then draw_stat_mask(pres, entry.image, cx, cy, sx, sy) end
  else
    -- Placeholder silhouette so lunge/shake is visible before full pic extract.
    local a = (pres and pres.alpha) or 1
    local flash = pres and (pres.flash or 0) or 0
    if flash > 0 and flash % 2 == 0 then
      love.graphics.setColor(1, 1, 1, a)
    elseif back then
      love.graphics.setColor(0.35, 0.55, 0.95, a)
    else
      love.graphics.setColor(0.95, 0.45, 0.35, a)
    end
    local hw = 24 * scale
    local rot = (pres and pres.rotation) or 0
    local sx = (pres and pres.sx) or 1
    local sy = (pres and pres.sy) or 1
    if rot ~= 0 or sx ~= 1 or sy ~= 1 then
      love.graphics.push()
      love.graphics.translate(cx, cy)
      love.graphics.rotate(rot)
      love.graphics.scale(sx, sy)
      love.graphics.rectangle("fill", -hw, -hw, hw * 2, hw * 2)
      love.graphics.setColor(1, 1, 1, a * 0.9)
      love.graphics.rectangle("line", -hw, -hw, hw * 2, hw * 2)
      love.graphics.pop()
    else
      love.graphics.rectangle("fill", cx - hw, cy - hw, hw * 2, hw * 2)
      love.graphics.setColor(1, 1, 1, a * 0.9)
      love.graphics.rectangle("line", cx - hw, cy - hw, hw * 2, hw * 2)
    end
  end
end

local function menu_labels(key)
  Ui._menuLabels = Ui._menuLabels or {}
  if Ui._menuLabels[key] then return Ui._menuLabels[key] end
  local labels, buf = {}, {}
  local function flush()
    if #buf > 0 then
      local label = table.concat(buf)
      labels[#labels + 1] = Strings(label, key)
      buf = {}
    end
  end
  for _, seg in ipairs(RomText.ir(key)) do
    if seg.t == "text" then
      buf[#buf + 1] = seg.s
    elseif seg.t == "tag" and seg.tag then
      -- pokeemerald/src/battle_message.c:1276
      buf[#buf + 1] = seg.tag
    elseif seg.t == "nl" or (seg.t == "ext" and seg.cmd == 19) then
      flush()
    end
  end
  flush()
  Ui._menuLabels[key] = labels
  return labels
end

local function action_prompt(st, ab)
  local mode = (st and st.safari and "safari") or (st and st.oldManTutorial and "oldman")
    or (st and st.kinds and st.kinds.tutorial == "wally" and "wally") or "pkmn"
  local mon = ab and ab.mon
  local cached = Ui._promptFor
  if cached and cached.st == st and cached.mode == mode and cached.mon == mon and Ui._promptText then
    return Ui._promptText
  end
  local text
  if mode == "safari" then
    -- pokefirered/src/battle_controller_safari.c:446
    text = BattleText.get(require("src.core.game3.battle.profile").of(st).strings.safariPrompt,
      { playerName = st.playerName })
  elseif mode == "oldman" then
    -- pokefirered/src/battle_controller_oak_old_man.c:1825
    text = BattleText.get("gText_WhatWillOldManDo")
  elseif mode == "wally" then
    -- pokeemerald/src/battle_controller_wally.c:1214
    text = BattleText.get("gText_WhatWillWallyDo")
  else
    -- pokefirered/src/battle_controller_player.c:2422
    text = BattleText.get("gText_WhatWillPkmnDo", { active = ab, trainer = st and not st.wild })
  end
  Ui._promptFor = { st = st, mode = mode, mon = mon }
  Ui._promptText = text
  return text
end

local function battle_font()
  local P = require("src.core.game3.profile").forSession(Ui._session)
  return require(P.font.module)
end

local function c5to8(x)
  return (x * 8 + math.floor(x / 4)) / 255
end

local function bgr555_rgba(v)
  v = tonumber(v) or 0
  return { c5to8(v % 32), c5to8(math.floor(v / 32) % 32), c5to8(math.floor(v / 1024) % 32), 1 }
end

local function rse_window_colors(fgIdx, shadowIdx)
  local pal = BattleChrome.manifest().windowTextPal or {}
  return {
    fg = bgr555_rgba(pal[(fgIdx or 13) + 1]),
    shadow = bgr555_rgba(pal[(shadowIdx or 15) + 1]),
    bg = { 0, 0, 0, 0 },
  }
end

local _defaultWinColors, _defaultWinPal = nil, nil

local function rse_default_colors()
  local pal = BattleChrome.manifest().windowTextPal or nil
  if not _defaultWinColors or pal ~= _defaultWinPal then
    _defaultWinColors = rse_window_colors()
    _defaultWinPal = pal
  end
  return _defaultWinColors
end

local function rse_pp_colors(pp, maxPp)
  local pp2 = BattleChrome.manifest().ppTextPal or {}
  local state = Ui.ppColorState(pp, maxPp)
  local c = rse_window_colors(13, 15)
  c.fg = bgr555_rgba(pp2[state * 2 + 1])
  c.shadow = bgr555_rgba(pp2[state * 2 + 2])
  return c
end

local function rse_text(win, text, dx, opts)
  local x, y, _, narrow = BattleChrome.textOrigin(win)
  opts = opts or {}
  local F = battle_font()
  local useNarrow = opts.narrow == nil and narrow or opts.narrow
  F.draw(tostring(text or ""), x + (dx or 0), y, {
    font = useNarrow and "narrow" or nil,
    colors = opts.colors or rse_default_colors(),
  })
end

local function rs_menu_colors()
  return { fg = bgr555_rgba(0x2529), shadow = bgr555_rgba(0x675a), bg = { 0, 0, 0, 0 } }
end

local function draw_action_menu_rs(st)
  local ab = st and (is_double(st) and active_battler(st) or st.player)
  local labels = menu_labels((st and st.safari) and "gText_SafariZoneMenu" or "gText_BattleMenu")
  local F, colors = battle_font(), rs_menu_colors()
  F.draw(tostring(action_prompt(st, ab) or ""), 16, 120, { colors = BattleChrome.textboxColors(1, 8) })
  local c = Ui._menuIndex - 1
  require("src.ui.game3.rs.menu_cursor").draw(144 + 46 * (c % 2), 120 + 16 * math.floor(c / 2), 42)
  for i = 1, 4 do
    local cc, rr = (i - 1) % 2, math.floor((i - 1) / 2)
    F.draw(tostring(labels[i] or ""), 144 + 46 * cc, 120 + 16 * rr, { colors = colors })
  end
end

local function draw_action_menu_rse(st)
  local W = BattleChrome.WIN
  local ab = st and (is_double(st) and active_battler(st) or st.player)
  local labels = menu_labels((st and st.safari) and "gText_SafariZoneMenu" or "gText_BattleMenu")
  local px, py = BattleChrome.textOrigin(W.ACTION_PROMPT)
  battle_font().draw(tostring(action_prompt(st, ab) or ""), px, py, { colors = BattleChrome.textboxColors(1, 6) })
  local mx, my = BattleChrome.textOrigin(W.ACTION_MENU)
  local c = Ui._menuIndex - 1
  local col, row = c % 2, math.floor(c / 2)
  Window.cursorPx(8 * (7 * col + 16), my + 16 * row, { colors = rse_default_colors() })
  for i = 1, 4 do
    local cc, rr = (i - 1) % 2, math.floor((i - 1) / 2)
    battle_font().draw(tostring(labels[i] or ""), mx + 56 * cc, my + 16 * rr, { colors = rse_default_colors() })
  end
end

local function swap_cursor_colors(variant, base)
  local clear = { 0, 0, 0, 0 }
  if variant == 27 then return { fg = base.fg, shadow = clear, bg = base.bg } end
  return { fg = base.shadow, shadow = clear, bg = base.bg }
end

local function draw_move_cursors(pos_of, base)
  local cur = Ui._moveIndex - 1
  local sw = Ui._swap
  local p = pos_of(cur)
  if not sw or sw.cursor == cur then
    Window.cursorPx(p[1], p[2], { colors = base })
    return
  end
  Window.cursorPx(p[1], p[2], { colors = swap_cursor_colors(29, base) })
  local q = pos_of(sw.cursor)
  Window.cursorPx(q[1], q[2], { colors = swap_cursor_colors(27, base) })
end

local function draw_move_menu_rs(st)
  local ab = st and (is_double(st) and active_battler(st) or st.player)
  local mon = ab and ab.mon
  local F, colors = battle_font(), rs_menu_colors()
  local cursor = Ui._swap and Ui._swap.cursor or Ui._moveIndex - 1
  require("src.ui.game3.rs.menu_cursor").draw(8 + 80 * (cursor % 2), 120 + 16 * math.floor(cursor / 2), 72)
  for i = 1, 4 do
    local mv = mon and mon.moves and mon.moves[i]
    local label = mv and mv ~= 0 and mv ~= "" and Moves.displayName(mv) or "-"
    local labelColors = colors
    -- pokeruby/src/battle_controller_player.c:597
    if Ui._swap and i == Ui._moveIndex then
      labelColors = { fg = bgr555_rgba(0x7fe0), shadow = colors.shadow, bg = colors.bg }
    end
    F.draw(label, 8 + 80 * ((i - 1) % 2), 120 + 16 * math.floor((i - 1) / 2), { colors = labelColors })
  end
  if Ui._swap then
    F.draw(RomText.plain("gText_BattleSwitchWhich"), 184, 120, { colors = colors })
    return
  end
  local slot = Ui._moveIndex
  local mv = mon and mon.moves and mon.moves[slot]
  if mv and mv ~= 0 and mv ~= "" then
    local def = Moves.get(mv)
    local pp = mon.pp and mon.pp[slot] or 0
    local maxPp = mon.maxPp and mon.maxPp[slot] or (def and def.pp) or pp
    F.draw(RomText.plain("gText_MoveInterfacePP"), 184, 120, { colors = colors })
    F.draw(string.char(0xfc, 0x11, 2, 0xfc, 0x14, 6) .. string.format("%2d/%2d", pp, maxPp),
      200, 120, { colors = colors })
    F.draw(Types.name(Ui.moveTypeOf(mon, slot, def)), 184, 136, { colors = colors })
  end
end

local function draw_move_menu_rse(st)
  local W = BattleChrome.WIN
  local ab = st and (is_double(st) and active_battler(st) or st.player)
  local mon = ab and ab.mon
  local _, cy = BattleChrome.textOrigin(W.MOVE_NAME_1)
  draw_move_cursors(function(c)
    return { 8 * (9 * (c % 2) + 1), cy + 16 * math.floor(c / 2) }
  end, rse_default_colors())
  for i = 1, 4 do
    local mv = mon and mon.moves and mon.moves[i]
    local label = "-"
    if mv and mv ~= 0 and mv ~= "" then label = Moves.displayName(mv) end
    rse_text(W.MOVE_NAME_1 + i - 1, label)
  end
  if Ui._swap then
    rse_text(W.SWITCH_PROMPT, RomText.plain("gText_BattleSwitchWhich"))
    return
  end
  local slot = Ui._moveIndex
  local mv = mon and mon.moves and mon.moves[slot]
  if mv and mv ~= 0 and mv ~= "" then
    local def = Moves.get(mv)
    local pp = mon.pp and mon.pp[slot] or 0
    local maxPp = mon.maxPp and mon.maxPp[slot] or (def and def.pp) or pp
    -- pokeemerald/src/battle_controller_player.c:1473
    rse_text(W.PP, RomText.plain("gText_MoveInterfacePP"), 0, { colors = rse_pp_colors(pp, maxPp) })
    -- pokeemerald/src/battle_controller_player.c:1479
    rse_text(W.PP_REMAINING, string.format("%2d/%2d", pp, maxPp), 0, { colors = rse_pp_colors(pp, maxPp) })
    -- pokeemerald/src/battle_controller_player.c:1496
    local typeLabel = RomText.plain("gText_MoveInterfaceType")
    rse_text(W.MOVE_TYPE, typeLabel)
    local F = battle_font()
    local tw = F.measure(typeLabel, { font = "narrow" })
    rse_text(W.MOVE_TYPE, Types.name(Ui.moveTypeOf(mon, slot, def)), tw, { narrow = false })
  end
end

local function draw_action_menu(st)
  local L = BattleChrome.layout()
  if L == "rs" then return draw_action_menu_rs(st) end
  if L == "emerald" then return draw_action_menu_rse(st) end
  -- B_WIN_ACTION_PROMPT @ (1,15) after scroll → px (8,120); printer (2,2) → (10,122)
  -- B_WIN_ACTION_MENU @ (17,15) → (136,120); printer (0,2) → (136,122)
  -- ActionSelectionCreateCursorAt: tile (16+7*col, 35+row) → after scroll (128,120);
  -- cursor is a 1×2 BG pip whose ink lines up with printer y=2 text → draw at text Y.
  local ab = st and (is_double(st) and active_battler(st) or st.player)
  local labels = menu_labels((st and st.safari) and "gText_SafariZoneMenu" or "gText_BattleMenu")
  draw_prompt_text(action_prompt(st, ab), 10, 122)
  local positions = {
    { 136, 122 }, { 192, 122 },
    { 136, 138 }, { 192, 138 },
  }
  local c = Ui._menuIndex - 1
  local cursorPos = {
    { 128, 122 }, { 184, 122 },
    { 128, 138 }, { 184, 138 },
  }
  local cp = cursorPos[c + 1] or cursorPos[1]
  Window.cursorPx(cp[1], cp[2], { colors = FrlgFont.COLOR.NORMAL })
  for i, pos in ipairs(positions) do
    draw_menu_text(labels[i], pos[1], pos[2], { small = false, colors = FrlgFont.COLOR.NORMAL })
  end
end

local function draw_move_menu(st)
  local L = BattleChrome.layout()
  if L == "rs" then return draw_move_menu_rs(st) end
  if L == "emerald" then return draw_move_menu_rse(st) end
  local ab = st and (is_double(st) and active_battler(st) or st.player)
  local mon = ab and ab.mon
  local positions = {
    { 16, 122 }, { 88, 122 },
    { 16, 138 }, { 88, 138 },
  }
  local cursorPos = {
    { 8, 122 }, { 80, 122 },
    { 8, 138 }, { 80, 138 },
  }
  draw_move_cursors(function(c) return cursorPos[c + 1] or cursorPos[1] end, FrlgFont.COLOR.NORMAL)
  for i = 1, 4 do
    local mv = mon and mon.moves and mon.moves[i]
    -- pokefirered/src/data/text/move_names.h:2
    local label = "-"
    if mv and mv ~= 0 and mv ~= "" then
      label = Moves.displayName(mv)
    end
    draw_menu_text(label, positions[i][1], positions[i][2], { small = true, colors = FrlgFont.COLOR.NORMAL })
  end
  if Ui._swap then
    draw_menu_text(RomText.plain("gText_BattleSwitchWhich"), 168, 122,
      { small = false, colors = FrlgFont.COLOR.NORMAL })
    return
  end
  local slot = Ui._moveIndex
  local mv = mon and mon.moves and mon.moves[slot]
  if mv and mv ~= 0 and mv ~= "" then
    local def = Moves.get(mv)
    local pp = mon.pp and mon.pp[slot] or 0
    local maxPp = mon.maxPp and mon.maxPp[slot] or (def and def.pp) or pp
    local ppColors = pp_text_colors(pp, maxPp)
    -- pokefirered/src/battle_controller_player.c:1387
    draw_menu_text(RomText.plain("gText_MoveInterfacePP"), 168, 122,
      { small = true, colors = FrlgFont.COLOR.NORMAL })
    -- pokefirered/src/battle_controller_player.c:1402
    draw_menu_text(string.format("%2d/%2d", pp, maxPp), 202, 122, { small = false, colors = ppColors })
    -- pokefirered/src/battle_controller_player.c:1413
    draw_menu_text(RomText.plain("gText_MoveInterfaceType") .. Types.name(Ui.moveTypeOf(mon, slot, def)), 168, 138,
      { small = true, colors = FrlgFont.COLOR.NORMAL })
  end
end

local function draw_enemy_trainer(stage)
  local p=Ui.presentation
  if p and p.drawTrainer and p.drawTrainer("enemy",stage)then return end
  if not stage or not stage.trainer then return end
  local TrainerPic = require("src.core.game3.trainer_pic")
  local te = stage.trainer.enemy
  if te and te.visible then
    -- pokefirered/src/battle_controller_link_opponent.c:1133
    local pics = { { te.pic2, te.x2 }, { te.picId, te.x or 176 } }
    for _, row in ipairs(pics) do
      local picId, x = row[1], row[2]
      if picId ~= nil and x ~= nil then
        local entry = TrainerPic.front(picId)
        if entry and entry.image then
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.draw(entry.image, x + (te.ox or 0) - 32, 40 + (te.oy or 0) - 32)
        end
      end
    end
  end
end

local function draw_player_trainer(stage)
  local p=Ui.presentation
  if p and p.drawTrainer and p.drawTrainer("player",stage)then return end
  if not stage or not stage.trainer then return end
  local TrainerPic = require("src.core.game3.trainer_pic")
  local tp = stage.trainer.player
  if tp and tp.visible then
    -- pokefirered/src/battle_controller_link_partner.c:1093
    local backs = { { tp.gender2, tp.x2 }, { tp.gender or 0, tp.x or 80 } }
    for _, row in ipairs(backs) do
      local gender, x = row[1], row[2]
      local entry = (gender ~= nil and x ~= nil) and TrainerPic.back(gender) or nil
      if entry and entry.image then
        local maxFrame = math.max(0, (entry.frames or 5) - 1)
        local frame = math.max(0, math.min(maxFrame, tonumber(tp.frame) or 0))
        local key = "back_" .. tostring(gender) .. "_" .. tostring(frame)
        Ui._trainerQuads = Ui._trainerQuads or {}
        if not Ui._trainerQuads[key] then
          local imgH = entry.h or (entry.frames and entry.frames * 64) or 320
          Ui._trainerQuads[key] = love.graphics.newQuad(0, frame * 64, 64, 64, entry.w or 64, imgH)
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
          entry.image, Ui._trainerQuads[key],
          x + (tp.ox or 0) - 32, 80 + (tp.oy or 0) - 32)
      end
    end
  end
end

local function draw_ball_entry(ball)
  if not ball or not ball.visible then return end
  local bx = (ball.x or 0) + (ball.ox or 0)
  local by = (ball.y or 0) + (ball.oy or 0)
  local scale=tonumber(ball.scale)or 1
  local p=Ui.presentation
  if p and p.ballPosition then local x,y,z=p.ballPosition(ball);if x~=nil then bx,by,scale=x,y,z or 1 end end
  local rot = tonumber(ball.rot) or 0
  local frame = math.max(0, math.min(2, tonumber(ball.frame) or 0))
  local darken = tonumber(ball.darken) or 0
  local flash = tonumber(ball.flash) or 0
  local shade = math.max(0, math.min(1, 1 - darken * (1 - 8 / 255)))

  local alpha = tonumber(ball.alpha) or 1
  if flash > 0 and flash % 2 == 0 then
    love.graphics.setColor(1, 1, 1, alpha)
  else
    love.graphics.setColor(shade, shade, shade, alpha)
  end

  local img, quad = Ui.ballQuad(ball.ballId, frame)
  if img then
    local blend = ball.blend
    local blended = blend and BallOpen.setBlendShader(blend.coeff, blend.r, blend.g, blend.b)
    love.graphics.draw(img, quad, bx, by, rot, scale, scale, 8, 8)
    if blended then love.graphics.setShader() end
  end

  love.graphics.setColor(1, 1, 1, 1)
end

local function draw_intro_ball(stage)
  if not stage then return end
  draw_ball_entry(stage.ball)
  local balls = stage.balls
  if type(balls) == "table" then
    for id = 0, 3 do
      local e = rawget(balls, id)
      if e and e ~= stage.ball then draw_ball_entry(e) end
    end
  end
end

local function battler_at(st, id)
  if id == 0 then return st.player end
  if id == 1 then return st.enemy end
  return st.battlers and st.battlers[id]
end

local function draw_double_mons(st, stage, Anim, screenFxActive)
  local order = (Anim.monDrawOrder and Anim.monDrawOrder(st)) or PicCoords.DRAW_ORDER
  local band = Anim.particleBand
  local function particles(k)
    local lo, hi
    if band then lo, hi = band(k, st) end
    if not lo then
      lo = (k == 0) and 0 or (k * 100 + 1)
      hi = (k >= #order) and 999 or (k * 100 + 99)
    end
    Anim.drawParticles(lo, hi)
  end
  draw_enemy_trainer(stage)
  particles(0)
  for k, id in ipairs(order) do
    if id % 2 == 0 and k > 1 and order[k - 1] % 2 == 1 then
      draw_player_trainer(stage)
    end
    if not (st.absent and st.absent[id]) then
      local b = battler_at(st, id)
      local base = (Anim.coords and Anim.coords(st, id)) or PicCoords.battlerCoords(true, id)
      draw_mon_sprite(b, base, id % 2 == 0, id)
    end
    if screenFxActive then Anim.beginScreenEffect() end
    particles(k)
  end
end

local function draw_double_healthboxes(st, Anim)
  for id = 3, 0, -1 do
    local b = battler_at(st, id)
    if b and not (st.absent and st.absent[id]) then
      Healthbox.draw(id, Anim.shownBattler(id, b), { st = st, oy = Ui.bounceOffset("hb", id) })
    end
  end
end

local function draw_party_bars(stage)
  if not stage or not stage.partyBar then return end
  local m = BattleChrome.manifest and BattleChrome.manifest() or {}
  local enemy = stage.partyBar.enemy
  if enemy and enemy.visible then
    local pos = m.partyBarOpponent or { x = 104, y = 40 }
    BattleChrome.drawPartyBar(enemy.x or pos.x, enemy.y or pos.y, enemy.balls, enemy.ox, true, enemy)
  end
  local player = stage.partyBar.player
  if player and player.visible then
    local pos = m.partyBarPlayer or { x = 136, y = 96 }
    BattleChrome.drawPartyBar(pos.x, pos.y, player.balls, player.ox, false, player)
  end
end

local function draw(w, h)
  if not (love and love.graphics) then return end
  w = w or Display.W
  h = h or Display.H

  local caught = Ui._caughtDexScene
  if caught then
    -- pokeemerald/src/battle_script_commands.c:10133
    local Fx = require("src.core.game3.gba_fx")
    Fx.draw(function()
      BattleChrome.drawPostDexBg(BattleBg.sheetKey())
      BattleChrome.drawPanel("none")
    end, caught.pal:fx(0))
    local spr = caught.sprite
    Fx.draw(function()
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(spr.img, spr.x + (spr.x2 or 0), spr.y + (spr.y2 or 0), 0, 1, spr.scaleY or 1, 32, 32)
    end, caught.pal:fx(16))
    if Choice and Choice.active and Choice.draw then Choice.draw() end
    return
  end

  local st = Ui._st
  local stage = Anim.stage and Anim.stage()

  local enemyOx = 0
  local playerOx = 0
  if stage and stage.bgSlide then
    enemyOx = stage.bgSlide.enemyOx or 0
    playerOx = stage.bgSlide.playerOx or 0
  end
  -- pokefirered/src/battle_intro.c:139
  local bgOx = 0
  if (enemyOx ~= 0 or playerOx ~= 0) and stage and stage.slide then
    bgOx = math.floor((tonumber(stage.slide) or 0) * 154 * 6 + 0.5)
  end

  local bgDim = (stage and stage.bgDim) or 0
  if bgDim > 0 then
    local s = math.max(0, 1 - bgDim * 0.65)
    love.graphics.setColor(s, s, s, 1)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end

  local screenFxActive = Anim.beginScreenEffect and Anim.beginScreenEffect()

  -- pokefirered/src/battle_anim_special.c:1888
  local bgBlended = not screenFxActive and BallOpen.setBlendShader(BallOpen.bgCoeff(), 31, 31, 31)
  if not bgBlended and not screenFxActive and Anim._bgPalAffine then
    bgBlended = set_affine_shader(Anim._bgPalAffine)
  end
  if not bgBlended and not screenFxActive then
    local bc, br, bg_, bb = bg_blend_params(Anim._bgBlend)
    if bc then bgBlended = BallOpen.setBlendShader(bc, br, bg_, bb) end
  end
  local bg3 = Anim._bg3Scroll
  if bg3 == nil then
    local vm = Anim.vm and Anim.vm()
    bg3 = vm and vm.active and vm.bg3 or nil
  end
  local bg3x = (type(bg3) == "table" and tonumber(bg3.x)) or 0
  local bg3y = (type(bg3) == "table" and tonumber(bg3.y)) or 0
  if bg3x ~= 0 or bg3y ~= 0 then
    love.graphics.push()
    love.graphics.translate(-bg3x, -bg3y)
  end
  if not BattleBg.draw(nil, enemyOx, playerOx, bgOx) then
    love.graphics.setColor(0.92, 0.94, 0.96, 1)
    love.graphics.rectangle("fill", 0, 0, w, 112)
  end
  if bg3x ~= 0 or bg3y ~= 0 then
    love.graphics.pop()
  end
  if bgBlended then love.graphics.setShader() end
  if screenFxActive then Anim.beginScreenEffect() end
  love.graphics.setColor(1, 1, 1, 1)

  -- pret-ish 5-layer z:
  -- 1. Behind Enemy & Background FX (Z: 0 .. 99)
  -- 2. Enemy Mon (Z: 100)
  -- 3. In front of Enemy / Behind Player / Mid-field (Z: 101 .. 199)
  -- 4. Player Mon (Z: 200)
  -- 5. In front of Player & Global Foreground (Z: 201 .. 999)
  local dbl = st and is_double(st)
  if Anim.beginParticleFrame then Anim.beginParticleFrame() end
  if dbl then
    draw_double_mons(st, stage, Anim, screenFxActive)
  else
  draw_enemy_trainer(stage)
  Anim.drawParticles(0, 99)
  if st then
    draw_mon_sprite(st.enemy, ENEMY_MON, false)
  end
  if screenFxActive then Anim.beginScreenEffect() end
  Anim.drawParticles(101, 199)
  -- pokefirered/src/battle_anim_mons.c:1908
  draw_player_trainer(stage)
  -- pokefirered/src/battle_main.c:2565
  if st and not st.safari then
    draw_mon_sprite(st.player, PLAYER_MON, true)
  end
  if screenFxActive then Anim.beginScreenEffect() end
  Anim.drawParticles(201, 999)
  end
  if Anim.endParticleFrame then Anim.endParticleFrame() end
  local entry = stage and stage.entry
  if entry then
    -- pokeemerald/src/battle_bg.c:1198
    BattleChrome.drawEntry(entry.key, entry.x, entry.y, entry.alpha)
  end
  LevelUpStreaks.draw(st)
  draw_intro_ball(stage)
  -- pokefirered/src/pokeball.c:770
  BallOpen.draw()
  if screenFxActive then Anim.endScreenEffect() end
  local hud=Ui.presentation
  if hud and hud.beginHud then hud.beginHud()end
  if dbl then
    draw_double_healthboxes(st, Anim)
  elseif st then
    Healthbox.draw("enemy", Anim.shownBattler("enemy", st.enemy), { oy = Ui.bounceOffset("hb", 1) })
    Healthbox.draw("player", Anim.shownBattler("player", st.player), { oy = Ui.bounceOffset("hb", 0) })
  end
  draw_party_bars(stage)

  local panelMode = "none"
  if Ui._mode == "menu" then
    panelMode = "menu"
  elseif Ui._mode == "moves" or Ui._mode == "target" then
    panelMode = "moves"
  end
  BattleChrome.drawPanel(panelMode)
  Ui.drawMenuFrames(panelMode)

  if Ui._mode == "menu" then
    draw_action_menu(st)
  elseif Ui._mode == "moves" or Ui._mode == "target" then
    draw_move_menu(st)
  end

  -- pokefirered/src/battle_controller_oak_old_man.c:759
  local oakDim = Ui.voiceoverDim()
  if oakDim > 0 then
    love.graphics.setColor(0, 0, 0, oakDim)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1, 1)
    -- pokefirered/src/battle_controller_pokedude.c:2607
    if st and not dbl and Ui.litHealthboxShown() then
      Healthbox.draw("player", Anim.shownBattler("player", st.player), { oy = Ui.bounceOffset("hb", 0) })
    end
  end

  -- pokeemerald/src/battle_main.c:631
  local win0 = stage and stage.win0
  if win0 then
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, w, win0[1])
    love.graphics.rectangle("fill", 0, win0[2], w, h - win0[2])
    love.graphics.setColor(1, 1, 1, 1)
  end

  local BagMenu = package.loaded["src.ui.game3.bag_menu"]
  if not BagMenu then
    local ok, M = pcall(require, "src.ui.game3.bag_menu")
    if ok then BagMenu = M end
  end
  if BagMenu and BagMenu.isOpen and BagMenu.isOpen() and BagMenu.draw then
    require("src.ui.game3.screens").draw("bag", BagMenu)
  end

  if Choice and Choice.active and Choice.draw then
    Choice.draw()
  end

  local PartyMenu = package.loaded["src.ui.game3.party_menu"]
  if not PartyMenu then
    local ok, M = pcall(require, "src.ui.game3.party_menu")
    if ok then PartyMenu = M end
  end
  if PartyMenu and PartyMenu.isOpen and PartyMenu.isOpen() and PartyMenu.draw then
    PartyMenu.draw()
  end

  local Pokedex = package.loaded["src.ui.game3.pokedex"]
  if Pokedex and Pokedex.isOpen and Pokedex.isOpen() and Pokedex.draw then
    Pokedex.draw()
  end
  local RseDex = package.loaded["src.ui.game3.rse.pokedex"]
  if RseDex and RseDex.active and RseDex.active() then RseDex.Host.draw() end

  local StatGrowth = package.loaded["src.ui.game3.stat_growth"]
  if StatGrowth and StatGrowth.isOpen and StatGrowth.isOpen() and StatGrowth.draw
      and stat_window_phase() then
    StatGrowth.draw()
  end

  if hud and hud.endHud then hud.endHud()end
  love.graphics.setColor(1, 1, 1, 1)
end
return {draw=draw,drawBattler=draw_mon_sprite,drawBall=draw_ball_entry}
