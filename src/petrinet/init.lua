local Coromake = require "coroutine.make"
local Et       = require "etlua"

local Mt       = {}
local Petrinet = setmetatable ({}, Mt)

Petrinet.Place      = {}
Petrinet.Transition = {}
Petrinet.Arc        = {}

Petrinet           .__index = Petrinet
Petrinet.Place     .__index = Petrinet.Place
Petrinet.Transition.__index = Petrinet.Transition
Petrinet.Arc       .__index = Petrinet.Arc

function Mt.__call ()
  return setmetatable ({}, Petrinet)
end

function Petrinet.place (_, t)
  return setmetatable ({
    name    = t.name    or "<no name>",
    x       = t.x       or 0,
    y       = t.y       or 0,
    marking = t.marking or 0,
  }, Petrinet.Place)
end

function Petrinet.Place.__tostring (place)
  return Et.render ([[<%- name -%> (<%- marking -%>)]], place)
end

function Petrinet.Place.__sub (place, valuation)
  return setmetatable ({
    type      = "pre",
    place     = place,
    valuation = valuation,
  }, Petrinet.Arc)
end

function Petrinet.Place.__add (place, valuation)
  return setmetatable ({
    type      = "post",
    place     = place,
    valuation = valuation,
  }, Petrinet.Arc)
end

function Petrinet.transition (_, t)
  local result = setmetatable ({
    name    = t.name    or "<no name>",
    x       = t.x       or 0,
    y       = t.y       or 0,
  }, Petrinet.Transition)
  for _, arc in ipairs (t) do
    arc.transition     = result
    result [#result+1] = arc
  end
  return result
end

function Petrinet.Transition.__tostring (place)
  return Et.render ([[<%- name -%>]], place)
end

function Petrinet.Transition.pre (transition)
  local coroutine = Coromake ()
  return coroutine.wrap (function ()
    for _, arc in ipairs (transition) do
      if getmetatable (arc) == Petrinet.Arc and arc.type == "pre" then
        coroutine.yield (arc)
      end
    end
  end)
end

function Petrinet.Transition.post (transition)
  local coroutine = Coromake ()
  return coroutine.wrap (function ()
    for _, arc in ipairs (transition) do
      if getmetatable (arc) == Petrinet.Arc and arc.type == "post" then
        coroutine.yield (arc)
      end
    end
  end)
end

function Petrinet.places (petrinet)
  local coroutine = Coromake ()
  return coroutine.wrap (function ()
    for name, place in pairs (petrinet) do
      if getmetatable (place) == Petrinet.Place then
        coroutine.yield (name, place)
      end
    end
  end)
end

function Petrinet.transitions (petrinet)
  local coroutine = Coromake ()
  return coroutine.wrap (function ()
    for name, transition in pairs (petrinet) do
      if getmetatable (transition) == Petrinet.Transition then
        coroutine.yield (name, transition)
      end
    end
  end)
end

return Petrinet
