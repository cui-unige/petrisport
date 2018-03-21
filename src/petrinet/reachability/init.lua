local State = require "petrinet.state"

local Mt    = {}
local Graph = setmetatable ({}, Mt)

Graph.__index = Graph

function Mt.__call (_, t)
  return setmetatable ({
    petrinet  = t.petrinet,
    free      = t.free,
    traversal = t.traversal or Graph.depth_first,
  }, Graph)
end

function Graph.depth_first (work)
  local result = work [#work]
  work [#work] = nil
  return result
end

function Graph.breadth_first (work)
  local result = work [1]
  table.remove (work, 1)
  return result
end

local States_mt = {}
local States    = setmetatable ({}, States_mt)

function States_mt.__call (_, petrinet)
  local places = {}
  for _, place in petrinet:places () do
    places [#places+1] = place
  end
  return setmetatable ({
    petrinet = petrinet,
    places   = places,
  }, States)
end

function States.__add (states, state)
  local current = states
  -- Free tokens:
  if not current [state.free] then
    current [state.free] = {}
  end
  current = states [state.free]
  -- Places:
  for _, place in ipairs (states.places) do
    if not current [state.marking [place]] then
      current [state.marking [place]] = {}
    end
    current = current [state.marking [place]]
  end
  if current.state then
    return current.state
  else
    current.state = state
    return nil
  end
end

function Graph.__call (graph)
  local initial = State {
    petrinet = graph.petrinet,
    free     = graph.free,
  }
  local unique = States (graph.petrinet)
  local _      = unique + initial
  local work   = { initial }
  local states = { initial }
  while #work ~= 0 do
    local state = graph.traversal (work)
    for transition in state:enabled () do
      local successor = state (transition)
      local existing  = unique + successor
      successor = existing or successor
      if not existing then
        states [#states+1] = successor
        work   [#work  +1] = successor
      end
      state.successors [transition] = successor
    end
  end
  return initial, states
end

return Graph
