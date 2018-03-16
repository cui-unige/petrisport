local assert   = require "luassert"
local Et       = require "etlua"
local State    = require "petrinet.state"
local Marking  = require "petrinet.marking"
local petrinet = require "petrinet.example"

describe ("State", function ()

  it ("can be created", function ()
    local state = State {
      petrinet = petrinet,
      free     = 10,
    }
    assert.are.equal (getmetatable (state), State)
  end)

  it ("can return the enabled transitions", function ()
    local state = State {
      petrinet = petrinet,
      free     = 10,
    }
    local enabled = {}
    for transition in state:enabled () do
      enabled [transition] = true
    end
    assert.are.same (enabled, {
      [petrinet.t4] = true,
      [petrinet.t5] = true,
      [petrinet.t6] = true,
    })
  end)

  it ("uses free tokens in enabling transitions", function ()
    local state = State {
      petrinet = petrinet,
      free     = 1,
    }
    local enabled = {}
    for transition in state:enabled () do
      enabled [transition] = true
    end
    assert.are.same (enabled, {})
  end)

  it ("can fire a transition", function ()
    local state = State {
      petrinet = petrinet,
      free     = 10,
    }
    local s1 = state (petrinet.t4)
    local s2 = state (petrinet.t5)
    local s3 = state (petrinet.t6)
    assert.are.same (s1.marking, Marking {
      [petrinet.p0] = 0,
      [petrinet.p1] = 0,
      [petrinet.p2] = 0,
      [petrinet.p3] = 2,
      [petrinet.p4] = 0,
      [petrinet.p5] = 1,
    })
    assert.are.same (s2.marking, Marking {
      [petrinet.p0] = 0,
      [petrinet.p1] = 0,
      [petrinet.p2] = 0,
      [petrinet.p3] = 0,
      [petrinet.p4] = 2,
      [petrinet.p5] = 1,
    })
    assert.are.same (s3.marking, Marking {
      [petrinet.p0] = 1,
      [petrinet.p1] = 1,
      [petrinet.p2] = 0,
      [petrinet.p3] = 0,
      [petrinet.p4] = 0,
      [petrinet.p5] = 0,
    })
  end)

  it ("can export the example to dot", function ()
    local state = State {
      petrinet = petrinet,
      free     = 10,
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
  end)

end)
