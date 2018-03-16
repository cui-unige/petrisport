local Reachability = require "petrinet.reachability"

local Mt       = {}
local Analysis = setmetatable ({}, Mt)

Analysis.__index = Analysis

function Mt.__call (_, t)
  local result = setmetatable ({
    petrinet = t.petrinet,
    free     = t.free,
  }, Analysis)
  local reachability = Reachability {
    petrinet  = t.petrinet,
    free      = 2,
    traversal = Reachability.depth_first,
  }
  result.initial, result.states = reachability (t.petrinet)
  return result
end

function Analysis.choice (analysis)
  local result = 0
  for _, state in ipairs (analysis.states) do
    local count = 0
    for _ in pairs (state.successors) do
      count = count + 1
    end
    if count > 1 then
      result = result + 1
    end
  end
  return result / #analysis.states
end

return Analysis
