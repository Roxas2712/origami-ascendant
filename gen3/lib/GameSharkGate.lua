-- Optional GameShark menu access. Session-only; no cheats or saved data change.
local V=...
local G={}
local states=setmetatable({},{__mode='k'})
local order={'up','down','left','right'}
local function state(game)
 local s=states[game];if not s then s={progress=0};states[game]=s end;return s
end
function G.unlocked(game)return game and states[game]and states[game].unlocked==true or false end
function G.reset(game)states[game]=nil end
function G.press(game,key)
 local s=state(game);if s.unlocked then return end
 if key==order[s.progress%4+1]then s.progress=s.progress+1
 else s.progress=key=='up'and 1 or 0 end
 if s.progress==12 then s.unlocked=true;return true end
end
function G.install(mod,owns)
 mod.hooks:wrap('input.step',function(nextFn,game,dt)
  if owns(game)and not G.unlocked(game)then
   local s=state(game)
   local ready=game.phase=='field'and not require('src.ui.game3.stack').busy()
    and not require('src.core.game3.battle').isActive()
   if ready then
    -- Read logical press edges without consuming them: keyboard, pad and touch
    -- all feed this queue. Holding a direction is not another tap.
    for _,key in ipairs(game.input and game.input.pressQueue or{})do G.press(game,key)end
   else s.progress=0 end
  end
  return nextFn(game,dt)
 end,1000)
 mod.hooks:wrap('ui.start_menu.items',function(nextFn,game,items)
  local rows=nextFn(game,items)or items
  if owns(game)and not G.unlocked(game)and type(rows)=='table'then
   for i=#rows,1,-1 do
    local id=tostring(rows[i].id or''):lower()
    if id=='gameshark'then table.remove(rows,i)end
   end
  end
  return rows
 end,1000) -- Outside GameShark's priority-500 hook; filter its finished rows.
end
return G
