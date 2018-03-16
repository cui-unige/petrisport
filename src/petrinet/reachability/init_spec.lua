local assert       = require "luassert"
local Reachability = require "petrinet.reachability"
local petrinet     = require "petrinet.example"

describe ("Reachability graph", function ()

  it ("can be created with an implicit traversal", function ()
    local reachability = Reachability {
      petrinet = petrinet,
      free     = 10,
    }
    assert.are.equal (getmetatable (reachability), Reachability)
    assert.are.equal (reachability.traversal, Reachability.depth_first)
  end)

  it ("can be created with an explicit traversal", function ()
    local reachability = Reachability {
      petrinet  = petrinet,
      free      = 10,
      traversal = Reachability.breadth_first,
    }
    assert.are.equal (getmetatable (reachability), Reachability)
    assert.are.equal (reachability.traversal, Reachability.breadth_first)
  end)

  it ("can compute the reachability graph of a Petri net (depth first)", function ()
    local reachability = Reachability {
      petrinet  = petrinet,
      free      = 2,
      traversal = Reachability.breadth_first,
    }
    local initial, states = reachability (petrinet)
    assert.are.equal (#states, 5)
    assert.is_nil     (initial.successors [petrinet.t0])
    assert.is_nil     (initial.successors [petrinet.t1])
    assert.is_nil     (initial.successors [petrinet.t2])
    assert.is_nil     (initial.successors [petrinet.t3])
    assert.is_not_nil (initial.successors [petrinet.t4])
    assert.is_not_nil (initial.successors [petrinet.t5])
    assert.is_not_nil (initial.successors [petrinet.t6])
  end)

  it ("can compute the reachability graph of a Petri net (breadth first)", function ()
    local reachability = Reachability {
      petrinet  = petrinet,
      free      = 2,
      traversal = Reachability.breadth_first,
    }
    local initial, states = reachability (petrinet)
    assert.are.equal (#states, 5)
    assert.is_nil     (initial.successors [petrinet.t0])
    assert.is_nil     (initial.successors [petrinet.t1])
    assert.is_nil     (initial.successors [petrinet.t2])
    assert.is_nil     (initial.successors [petrinet.t3])
    assert.is_not_nil (initial.successors [petrinet.t4])
    assert.is_not_nil (initial.successors [petrinet.t5])
    assert.is_not_nil (initial.successors [petrinet.t6])
  end)

  it ("can compute the reachability graph of the example", function ()
    local reachability = Reachability {
      petrinet  = petrinet,
      free      = 10,
      traversal = Reachability.breadth_first,
    }
    local _, states = reachability (petrinet)
    assert.are.equal (#states, 1244)
  end)

end)
