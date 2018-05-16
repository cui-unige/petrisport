#! /usr/bin/env lua

package.path = "./src/?.lua;./src/?/init.lua;".. package.path

local Arguments = require "argparse"
local Colors    = require 'ansicolors'
local Et        = require "etlua"
local Http      = require "socket.http"
local Https     = require "ssl.https"
local Lfs       = require "lfs"
local Logging   = require "logging"
local Ltn12     = require "ltn12"
local Magic     = require "magic"
local Petrinet  = require "petrinet"
local Analysis  = require "petrinet.analysis"
local State     = require "petrinet.state"

local zip_mime = {
  ["application/x-gzip" ] = true,
  ["application/x-bzip" ] = true,
  ["application/x-bzip2"] = true,
  ["application/x-tar"  ] = true,
}

local logger = Logging.new (function (_, level, message)
  if     level == Logging.DEBUG then
    print (Colors ("%{white blackbg}DEBUG:%{reset} " .. message))
  elseif level == Logging.INFO  then
    print (Colors ("%{green blackbg}INFO :%{reset} " .. message))
  elseif level == Logging.WARN  then
    print (Colors ("%{yellow bright blackbg}WARN :%{reset} " .. message))
  elseif level == Logging.ERROR then
    print (Colors ("%{red bright blackbg}ERROR:%{reset} " .. message))
  elseif level == Logging.FATAL then
    print (Colors ("%{red bright underline blackbg}FATAL:%{reset} " .. message))
  else
    assert (false, level)
  end
  return true
end)
-- logger:setLevel (Logging.INFO)

local parser = Arguments () {
  name        = "petri-sport",
  description = "",
}
parser:argument "petrinet" {
  description = "Petri net file or URL to load",
  convert     = function (x)
    local created = nil
    if x:match "^https?://" then
      logger:info ("Downloading model from " .. x .. "...")
      local http      = x:match "^http://" and Http or Https
      local result    = {}
      local _, status = http.request {
        url      = x,
        method   = "GET",
        -- redirect = true,
        sink     = Ltn12.sink.table (result),
      }
      print (status)
      assert (status == 200)
      local filename = os.tmpname ()
      logger:info ("Storing model in " .. filename .. "...")
      local file     = io.open (filename, "w")
      file:write (table.concat (result))
      file:close ()
      x       = filename
      created = filename
    end
    local magic = Magic.open (Magic.MIME_TYPE, Magic.NO_CHECK_COMPRESS)
    assert (magic:load () == 0)
    while true do
      local result
      local mode = Lfs.attributes (x, "mode")
      if  mode == "file"
      and (x:match "%.lua$" or magic:file (x) == "text/plain") then
        logger:info ("Loading lua model from " .. x .. "...")
        result = assert (loadfile (x, "r"))
      elseif mode == "file"
      and (x:match "%.pnml$" or magic:file (x) == "application/xml") then
        logger:info ("Loading PNML model from " .. x .. "...")
        result = Petrinet.pnml (x)
      elseif mode == "file"
      and (x:match "%.tgz" or zip_mime [magic:file (x)]) then
        local temporary = os.tmpname ()
        logger:info ("Extracting archive from " .. x .. " to " .. temporary .. "...")
        os.remove (temporary)
        Lfs.mkdir (temporary)
        assert (os.execute (Et.render ([[
          tar xf "<%- filename %>" \
              -C "<%- directory %>" \
              --strip-components=1
        ]], {
          directory = temporary,
          filename = x,
        })))
        x = temporary
      elseif mode == "directory" then
        x = x .. "/model.pnml"
      elseif not mode then
        logger:info ("Loading lua module " .. x .. "...")
        result = require (x)
      else
        logger:error ("Unknown model format for " .. x .. "...")
        os.exit (1)
      end
      if result then
        if created then
          os.remove (created)
        end
        return result
      end
    end
  end,
}
parser:option "--free" {
  description = "number of free tokens",
  convert     = tonumber,
  default     = nil,
}
parser:flag "--deadlocks" {
  description = "show deadlocks",
  default     = false,
}

local arguments = parser:parse ()

do
  local state = State {
    petrinet = arguments.petrinet,
    free     = arguments.free or 0,
  }
  local dot      = state:to_dot ()
  local filename = os.tmpname ()
  local file     = io.open (filename, "w")
  file:write (dot)
  file:close ()
  os.execute (Et.render ([[
    neato -n -Tpdf <%- filename %> -o output.pdf
  ]], {
    filename = filename,
  }))
  os.remove (filename)
  logger:info ("Model has been output in 'output.pdf'.")
end

local analysis  = Analysis {
  petrinet = arguments.petrinet,
}
for result in analysis (arguments.free) do
  print (Et.render ([[
- free tokens: <%- result.free %>
  choice:
    min  : <%- result.choice.min %>
    max  : <%- result.choice.max %>
    mean : <%- math.ceil (result.choice.mean*100)/100 %>
    ratio: <%- math.ceil (result.choice.ratio*100) %>%
  parallel:
    min  : <%- result.parallel.min %>
    max  : <%- result.parallel.max %>
    mean : <%- math.ceil (result.parallel.mean*100)/100 %>
    ratio: <%- math.ceil (result.parallel.ratio*100) %>%
  # of states     : <%- #result.states %>
  # of deadlocks  : <%- #result.deadlocks %>
  # of deadlocking: <%- #result.deadlocking %>
  % of deadlocking: <%- math.ceil (#result.deadlocking * 100 / #result.states) %>%
<% if arguments.deadlocks then -%>
<% for i, deadlock in ipairs (result.deadlocks) do -%>
  deadlock #<%- i %>:
    state : <%- deadlock.state %>
    path  : <%- deadlock.path %>
    length: <%- math.ceil (#deadlock.path / 2) %>
<% end -%>
<% end -%>]], {
    arguments = arguments,
    result    = result,
  }))
end
