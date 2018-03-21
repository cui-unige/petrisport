local Coromake = require "coroutine.make"
local Et       = require "etlua"
local Lom      = require "lxp.lom"

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

local function childs (tag, xml)
  local coroutine = Coromake ()
  return coroutine.wrap (function ()
    for _, child in pairs (xml or {}) do
      if type (child) == "table" and child.tag == tag then
        coroutine.yield (child)
      end
    end
  end)
end

function Petrinet.pnml (filename)
  local file     = assert (io.open (filename, "r"))
  local contents = file:read "*a"
  file:close ()
  local xml = Lom.parse (contents)
  assert (xml.tag == "pnml")
  local result = Petrinet {}
  local net  = childs ("net" , xml) ()
  local page = childs ("page", net) ()
  for place in childs ("place", page) do
    local name     = childs ("name", place) ()
    local text     = childs ("text", name) ()
    local graphics = childs ("graphics", place) ()
    local position = childs ("position", graphics) ()
    local initial  = childs ("initialMarking", place) ()
    local tokens   = childs ("text", initial) ()
    result [place.attr.id] = result:place {
      name    = text [1],
      marking = tokens and tonumber (tokens [1]) or 0,
      x       = position and  tonumber (position.attr.x) / 10,
      y       = position and -tonumber (position.attr.y) / 10,
    }
  end
  for transition in childs ("transition", page) do
    local name     = childs ("name", transition) ()
    local text     = childs ("text", name) ()
    local graphics = childs ("graphics", transition) ()
    local position = childs ("position", graphics) ()
    result [transition.attr.id] = result:transition {
      name    = text [1],
      x       = position and  tonumber (position.attr.x) / 10,
      y       = position and -tonumber (position.attr.y) / 10,
    }
  end
  for arc in childs ("arc", page) do
    local inscription = childs ("name", arc) ()
    local text        = childs ("text", inscription) ()
    local source      = arc.attr.source
    local target      = arc.attr.target
    if getmetatable (result [source]) == Petrinet.Transition then
      local place      = result [target]
      local transition = result [source]
      local post       = place + (text and tonumber (text) or 1)
      post.transition = transition
      transition [#transition+1] = post
    elseif getmetatable (result [target]) == Petrinet.Transition then
      local place      = result [source]
      local transition = result [target]
      local pre        = place - (text and tonumber (text) or 1)
      pre.transition = transition
      transition [#transition+1] = pre
    else
      assert (false)
    end
  end
  return result
end

return Petrinet
