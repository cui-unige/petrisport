local Coromake     = require "coroutine.make"
local Reachability = require "petrinet.reachability"

local Mt       = {}
local Analysis = setmetatable ({}, Mt)
local Path     = {}

Analysis.__index = Analysis
Path    .__index = Path

function Mt.__call (_, t)
  local result = setmetatable ({
    petrinet = t.petrinet,
  }, Analysis)
  return result
end

local Utility = {}

function Utility.distances (initial, _)
  initial.distance = 0
  local todo = {
    [0] = { [initial] = true },
  }
  for i = 0, math.huge do
    todo [i+1] = todo [i+1] or {}
    for state in pairs (todo [i] or {}) do
      for transition, successor in pairs (state.successors) do
        successor.distance = math.min (successor.distance or math.huge, state.distance+1)
        if successor.distance == state.distance+1 then
          successor.predecessor = {
            transition = transition,
            state      = state,
          }
          todo [i+1] [successor] = true
        end
      end
    end
    if not next (todo [i+1]) then
      return true
    end
  end
end

function Utility.choice (_, states)
  local more    = 0
  local sum     = 0
  local minimum = math.huge
  local maximum = -math.huge
  for _, state in ipairs (states) do
    local count = 0
    for _ in pairs (state.successors) do
      count = count + 1
      sum   = sum   + 1
    end
    minimum = math.min (minimum, count)
    maximum = math.max (maximum, count)
    more    = more + (count > 1 and 1 or 0)
  end
  return {
    ratio = more / #states,
    min   = minimum,
    max   = maximum,
    mean  = sum / #states,
  }
end

function Utility.parallel (_, states)
  local more      = 0
  local sum       = 0
  local minimum   = math.huge
  local maximum   = -math.huge
  for _, state in ipairs (states) do
    local has_parallel = false
    local count = 0
    local total = 0
    for ts in state:parallel () do
      minimum = math.min (minimum, #ts)
      maximum = math.max (maximum, #ts)
      count = count + 1
      total = total + #ts
      if #ts > 1 then
        has_parallel = true
      end
    end
    more = more + (has_parallel and 1 or 0)
    sum  = sum  + total / count
  end
  return {
    ratio = more / #states,
    min   = minimum,
    max   = maximum,
    mean  = sum / #states,
  }
end

function Utility.deadlocks (_, states)
  local coroutine = Coromake ()
  return coroutine.wrap (function ()
    for _, state in ipairs (states) do
      if not next (state.successors) then
        coroutine.yield (state)
      end
    end
  end)
end

function Utility.path (initial, _, to)
  local result  = { to }
  while result [1] ~= initial do
    local state = result [1]
    table.insert (result, 1, state.predecessor.transition)
    table.insert (result, 1, state.predecessor.state)
  end
  return setmetatable (result, Path)
end

function Utility.deadlocking (_, states)
  repeat
    local changed = false
    for _, state in ipairs (states) do
      local before = state.deadlocking or false
      if not next (state.successors) then
        state.deadlocking = true
      end
      local all_deadlock = true
      for _, successor in pairs (state.successors) do
        if not successor.deadlocking then
          all_deadlock = false
          break
        end
      end
      state.deadlocking = all_deadlock
      changed = changed
             or state.deadlocking ~= before
    end
  until not changed
  local coroutine = Coromake ()
  return coroutine.wrap (function ()
    for _, state in ipairs (states) do
      if state.deadlocking then
        coroutine.yield (state)
      end
    end
  end)
end

function Analysis.__call (analysis, free)
  local coroutine = Coromake ()
  return coroutine.wrap (function ()
    for f = 0, free or math.huge do
      local reachability = Reachability {
        petrinet  = analysis.petrinet,
        free      = f,
        traversal = Reachability.depth_first,
      }
      local initial, states = reachability (analysis.petrinet)
      -- compute distances:
      Utility.distances (initial, states)
      -- compute the choices:
      local choice = Utility.choice (initial, states)
      -- compute the parallels:
      local parallel = Utility.parallel (initial, states)
      -- compute deadlocks:
      local deadlocks = {}
      for deadlock in Utility.deadlocks (initial, states) do
        deadlocks [#deadlocks+1] = {
          state = deadlock,
          path  = Utility.path (initial, states, deadlock),
        }
      end
      table.sort (deadlocks, function (l, r)
        return #l.path < #r.path
      end)
      local deadlocking = {}
      for state in Utility.deadlocking (initial, states) do
        deadlocking [#deadlocking+1] = state
      end
      coroutine.yield {
        free        = f,
        initial     = initial,
        states      = states,
        choice      = choice,
        parallel    = parallel,
        deadlocks   = deadlocks,
        deadlocking = deadlocking,
      }
    end
  end)
end

function Path.__tostring (path)
  local result = {}
  for i = 2, #path, 2 do
    result [#result+1] = path [i].name
  end
  return table.concat (result, " -> ")
end

-- function Utility.copy (t)
--   local result = {}
--   for k, v in pairs (t) do
--     result [k] = v
--   end
--   return result
-- end
--
-- function Analysis.paths (analysis, t)
--   analysis:distance ()
--   t = t or {}
--   local coroutine = Coromake ()
--   local todo = {
--     { path = { analysis.initial }, seen = {} }
--   }
--   return coroutine.wrap (function ()
--     while todo [1] do
--       local path = todo [1].path
--       local seen = todo [1].seen
--       table.remove (todo, 1)
--       local state = path [#path]
--       if state == t.to then
--         coroutine.yield (setmetatable (path, Path))
--       end
--       if state.distance < (t.to and t.to.distance or math.huge) then
--         for transition, successor in pairs (state.successors) do
--           if not seen [successor] then
--             local path_c = copy (path)
--             local seen_c = copy (seen)
--             path_c [#path_c+1] = transition
--             path_c [#path_c+1] = successor
--             seen_c [state    ] = true
--             todo [#todo+1] = {
--               path = path_c,
--               seen = seen_c,
--             }
--           end
--         end
--       end
--     end
--   end)
-- end

return Analysis
