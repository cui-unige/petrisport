local Coromake = require "coroutine.make"
local Et       = require "etlua"
local Petrinet = require "petrinet"
local Marking  = require "petrinet.marking"

local Mt    = {}
local State = setmetatable ({}, Mt)

State.__index = State

function Mt.__call (_, t)
  local result = setmetatable ({
    petrinet   = t.petrinet,
    free       = t.free,
    marking    = Marking (t.petrinet),
    successors = {},
  }, State)
  return result
end

function State.__call (state, transition)
  assert (getmetatable (state) == State)
  assert (getmetatable (transition) == Petrinet.Transition)
  if not transition:enabled_in (state) then
    return nil, "transition is not enabled"
  end
  local free  = 0
  local bound = 0
  local pre   = Marking {}
  for arc in transition:pre () do
    pre [arc.place] = arc.valuation
    bound = bound + arc.valuation
  end
  local post = Marking {}
  for arc in transition:post () do
    post [arc.place] = arc.valuation
    free = free + arc.valuation
  end
  assert (state.free - free + bound > 0)
  return setmetatable ({
    petrinet   = state.petrinet,
    free       = state.free - free + bound,
    marking    = state.marking - pre + post,
    successors = {},
  }, State)
end

function State.pre (state, transition)
  assert (getmetatable (state) == State)
  assert (getmetatable (transition) == Petrinet.Transition)
  if not transition:enabled_in (state) then
    return nil, "transition is not enabled"
  end
  local free  = 0
  local pre   = Marking {}
  for arc in transition:pre () do
    pre [arc.place] = arc.valuation
  end
  for arc in transition:post () do
    free = free + arc.valuation
  end
  return setmetatable ({
    petrinet   = state.petrinet,
    free       = state.free - free,
    marking    = state.marking - pre,
    successors = {},
  }, State)
end

function State.post (state, transition)
  assert (getmetatable (state) == State)
  assert (getmetatable (transition) == Petrinet.Transition)
  local bound = 0
  for arc in transition:pre () do
    bound = bound + arc.valuation
  end
  local post = Marking {}
  for arc in transition:post () do
    post [arc.place] = arc.valuation
  end
  return setmetatable ({
    petrinet   = state.petrinet,
    free       = state.free + bound,
    marking    = state.marking + post,
    successors = {},
  }, State)
end

function State.parallel (state)
  local coroutine = Coromake ()
  local function iterate (s, transitions, fired)
    local any = false
    for i, transition in ipairs (transitions) do
      if transition:enabled_in (s) then
        fired [transition] = true
        table.remove (transitions, i)
        iterate (s:pre (transition), transitions, fired)
        table.insert (transitions, i, transition)
        fired [transition] = nil
        any = true
      end
    end
    if not any then
      local result = {}
      for transition in pairs (fired) do
        result [#result+1] = transition
      end
      coroutine.yield (result)
    end
  end
  local transitions = {}
  for transition in state:enabled () do
    transitions [#transitions+1] = transition
  end
  return coroutine.wrap (function ()
    iterate (state, transitions, {})
  end)
end

function State.enabled (state)
  assert (getmetatable (state) == State)
  local coroutine = Coromake ()
  return coroutine.wrap (function ()
    for _, transition in state.petrinet:transitions () do
      if transition:enabled_in (state) then
        coroutine.yield (transition)
      end
    end
  end)
end

function Petrinet.Transition.enabled_in (transition, state)
  if getmetatable (state) ~= State then
    print ("enabled_in", transition, state)
    print (debug.traceback ())
  end
  assert (getmetatable (transition) == Petrinet.Transition)
  assert (getmetatable (state) == State)
  for arc in transition:pre () do
    if arc.valuation > state.marking [arc.place] then
      return false
    end
  end
  local free = 0
  for arc in transition:post () do
    free = free + arc.valuation
  end
  return state.free >= free
end

local function goes_to (current, final, path)
  if current == final then
    return true
  elseif path [current] then
    return false
  end
  local result   = false
  path [current] = true
  for _, child in pairs (current.successors) do
    result = result or goes_to (child, final, path)
  end
  path [current] = nil
  return result
end

function State.__eq (lhs, rhs)
  return lhs.petrinet == rhs.petrinet
     and lhs.free     == rhs.free
     and lhs.marking  == rhs.marking
end

function State.__le (lhs, rhs)
  return goes_to (lhs, rhs, {})
end

function State.__lt (lhs, rhs)
  return lhs ~= rhs and goes_to (lhs, rhs, {})
end

function State.__tostring (state)
  return Et.render ([[<%- tostring (marking) %> / <%- free %>]], state)
end

function State.to_dot (state)
  assert (getmetatable (state) == State)
  local identifier = 0
  -- Set identifiers to places:
  for key, place in state.petrinet:places () do
    if place.identifier then
      local _ = false
    elseif key:match "[a-zA-Z0-9_]+" then
      place.identifier = key
    else
      place.identifier = identifier
      identifier = identifier + 1
    end
  end
  -- Set identifiers to transitions:
  for key, transition in state.petrinet:transitions () do
    if transition.identifier then
      local _ = false
    elseif key:match "[a-zA-Z0-9_]+" then
      transition.identifier = key
    else
      transition.identifier = identifier
      identifier = identifier + 1
    end
  end
  -- Render dot output:
  return Et.render ([[
  digraph G {
    free [
      label     = "Free: <%- state.free %>",
      pos       = "-100,0!",
      shape     = "rectangle",
      style     = "filled",
      fillcolor = "palegoldenrod",
    ];
    <% for _, place in state.petrinet:places () do %>
      place_<%- place.identifier %> [
        label = "<%- place.name %> = <%- state.marking [place] %>",
        pos   = "<%- place.x * 100 %>,<%- place.y * 100 %>!",
        shape = "circle",
        <% if state.marking [place] > 0 then %>
        style     = "filled",
        fillcolor = "orchid",
        <% end %>
      ];
    <% end -%>
    <% for _, transition in state.petrinet:transitions () do %>
      transition_<%- transition.identifier %> [
        label     = "<%- transition.name %>",
        pos       = "<%- transition.x * 100 %>,<%- transition.y * 100 %>!",
        shape     = "rectangle",
        <% if transition:enabled_in (state) then %>
        style     = "filled",
        fillcolor = "springgreen",
        <% end %>
      ];
      <% for arc in transition:pre () do %>
      place_<%- arc.place.identifier %> -> transition_<%- arc.transition.identifier %> [
        <% if arc.valuation > 1 then %>
        label = "<%- arc.valuation %>",
        <% end %>
      ];
      <% end -%>
      <% for arc in transition:post () do %>
      transition_<%- arc.transition.identifier %> -> place_<%- arc.place.identifier %> [
        <% if arc.valuation > 1 then %>
        label = "<%- arc.valuation %>",
        <% end %>
      ];
      <% end -%>
    <% end %>
  }
  ]], {
    state = state,
  })
end

return State
