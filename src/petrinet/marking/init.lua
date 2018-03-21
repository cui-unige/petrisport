local Et       = require "etlua"
local Petrinet = require "petrinet"
local Mt       = {}
local Marking  = setmetatable ({}, Mt)

Marking.__index = Marking

function Mt.__call (_, t)
  if getmetatable (t) == Petrinet then
    local petrinet = t
    local result = setmetatable ({}, Marking)
    for _, place in petrinet:places () do
      result [place] = place.marking
    end
    return result
  else
    return setmetatable (t, Marking)
  end
end

function Marking.__eq (lhs, rhs)
  assert (getmetatable (lhs) == Marking)
  assert (getmetatable (rhs) == Marking)
  for place, marking in pairs (lhs) do
    if rhs [place] ~= marking then
      return false
    end
  end
  for place, marking in pairs (rhs) do
    if lhs [place] ~= marking then
      return false
    end
  end
  return true
end

function Marking.__le (lhs, rhs)
  for place, marking in pairs (lhs) do
    if (rhs [place] or 0) < marking then
      return false
    end
  end
  return true
end

function Marking.__lt (lhs, rhs)
  for place, marking in pairs (lhs) do
    if (rhs [place] or 0) < marking then
      return false
    end
  end
  return lhs ~= rhs
end

function Marking.__add (lhs, rhs)
  local result = setmetatable ({}, Marking)
  for place, marking in pairs (lhs) do
    result [place] = marking
  end
  for place, marking in pairs (rhs) do
    result [place] = (result [place] or 0) + marking
  end
  return result
end

function Marking.__sub (lhs, rhs)
  local result = setmetatable ({}, Marking)
  for place, marking in pairs (lhs) do
    result [place] = marking
  end
  for place, marking in pairs (rhs) do
    result [place] = (result [place] or 0) - marking
  end
  return result
end

function Marking.__tostring (marking)
  local places = {}
  for place in pairs (marking) do
    places [#places+1] = place
  end
  table.sort (places, function (l, r)
    return l.name < r.name
  end)
  return Et.render ([[<% for _, place in ipairs (places) do %> <%- place.name %> = <%- marking [place] %> <% end %>]], {
    places  = places,
    marking = marking,
  })
end

return Marking
