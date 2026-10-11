-- Cooperative native geometry budget, pumped by NativeBuildQueue. GPU
-- uploads remain atomic; phase timings expose operations exceeding a slice.
-- Calls outside the owned coroutine are no-ops, preserving synchronous tools.

local B = { n = 0 }

local V = ...
local function clock()return (V and V.clock or (love and love.timer and love.timer.getTime) or os.clock)()end

local deadline = math.huge
local buildCo = nil
local phase = "idle"
local activeSeconds, sliceStarted = 0, nil

-- Enter/leave a pumped slice. `co` is the coroutine being resumed, so
-- tick() can tell the build apart from any other coroutine the engine
-- happens to be running (drivers are coroutines too).
function B.begin(co, seconds)
  buildCo = co
  sliceStarted = clock()
  deadline = sliceStarted + seconds
end

function B.finish()
  if sliceStarted then activeSeconds = activeSeconds + clock() - sliceStarted end
  sliceStarted = nil
  buildCo = nil
  deadline = math.huge
end

function B.ownsCurrent()
  return buildCo ~= nil and coroutine.running() == buildCo
end

-- Elapsed time spent inside resumed build slices, excluding the frames while
-- the coroutine is suspended. This measures CPU-side work, not GPU duration.
function B.workTime()
  return activeSeconds + (sliceStarted and clock() - sliceStarted or 0)
end

-- Read-only profiling seam used by the release diagnostics.  It does not
-- affect scheduling; producers name their current coarse phase so an atomic
-- operation that overruns the cooperative deadline can be identified from a
-- live log instead of guessed from total map time.
function B.phase(name)
  if name ~= nil then
    phase = tostring(name)
    local trace=V and V.loaded and V.loaded.TransitionTrace
    if trace and B.ownsCurrent()then trace.step('geometry '..phase)end
  end
  return phase
end

function B.expired()
  return clock() > deadline
end

-- Cheap enough to sprinkle through inner loops: one modulo most calls,
-- a clock read every 32nd.
function B.tick()
  local n = B.n + 1
  B.n = n
  if n % 32 ~= 0 then return end
  if buildCo and coroutine.running() == buildCo and clock() > deadline then
    coroutine.yield("budget")
  end
end

-- Like tick() but consults the clock every call -- for coarse loops
-- whose single iteration already costs milliseconds (mesh upload
-- slices), where tick()'s 1-in-32 sampling would never fire.
function B.check()
  if buildCo and coroutine.running() == buildCo and clock() > deadline then
    coroutine.yield("budget")
  end
end

return B
