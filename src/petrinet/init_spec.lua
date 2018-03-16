local assert   = require "luassert"
local Petrinet = require "petrinet"

describe ("Petri nets", function ()

  it ("can be created", function ()
    local petrinet = Petrinet ()
    assert.are.equal (getmetatable (petrinet), Petrinet)
  end)

  it ("can create a place with an implicit marking", function ()
    local petrinet = Petrinet ()
    petrinet.p     = petrinet:place  {}
    assert.are.equal (getmetatable (petrinet.p), Petrinet.Place)
    assert.are.equal (petrinet.p.marking, 0)
  end)

  it ("can create a place with an explicit marking", function ()
    local petrinet = Petrinet ()
    petrinet.p     = petrinet:place { marking = 5 }
    assert.are.equal (getmetatable (petrinet.p), Petrinet.Place)
    assert.are.equal (petrinet.p.marking, 5)
  end)

  it ("can iterate over its places", function ()
    local petrinet = Petrinet ()
    petrinet.p     = petrinet:place { marking = 5 }
    petrinet.q     = petrinet:place { marking = 0 }
    local places   = {}
    for _, place in petrinet:places () do
      assert.are.equal (getmetatable (place), Petrinet.Place)
      places [place] = true
    end
    assert.are.same (places, {
      [petrinet.p] = true,
      [petrinet.q] = true,
    })
  end)

  it ("can create a transition", function ()
    local petrinet = Petrinet ()
    petrinet.p     = petrinet:place {}
    petrinet.q     = petrinet:place {}
    petrinet.t     = petrinet:transition {
      petrinet.p - 1,
      petrinet.q + 1,
    }
    assert.are.equal (getmetatable (petrinet.t), Petrinet.Transition)
    assert.are.equal (getmetatable (petrinet.t [1]), Petrinet.Arc)
    assert.are.equal (getmetatable (petrinet.t [2]), Petrinet.Arc)
    assert.are.equal (petrinet.t [1].place, petrinet.p)
    assert.are.equal (petrinet.t [2].place, petrinet.q)
    assert.are.equal (petrinet.t [1].valuation, 1)
    assert.are.equal (petrinet.t [2].valuation, 1)
  end)

  it ("can iterate over its transitions", function ()
    local petrinet = Petrinet ()
    petrinet.p     = petrinet:place {}
    petrinet.q     = petrinet:place {}
    petrinet.t     = petrinet:transition {
      petrinet.p - 1,
      petrinet.q + 1,
    }
    petrinet.u     = petrinet:transition {
      petrinet.q - 1,
      petrinet.p + 1,
    }
    local transitions = {}
    for _, transition in petrinet:transitions () do
      assert.are.equal (getmetatable (transition), Petrinet.Transition)
      transitions [transition] = true
    end
    assert.are.same (transitions, {
      [petrinet.t] = true,
      [petrinet.u] = true,
    })
  end)

  it ("can iterate over pre arcs", function ()
    local petrinet = Petrinet ()
    petrinet.p     = petrinet:place {}
    petrinet.q     = petrinet:place {}
    petrinet.t     = petrinet:transition {
      petrinet.p - 1,
      petrinet.q + 1,
    }
    local arcs = {}
    for arc in petrinet.t:pre () do
      assert.are.equal (getmetatable (arc), Petrinet.Arc)
      arcs [#arcs+1] = true
    end
    assert.are.equal (#arcs, 1)
  end)

  it ("can iterate over post arcs", function ()
    local petrinet = Petrinet ()
    petrinet.p     = petrinet:place {}
    petrinet.q     = petrinet:place {}
    petrinet.t     = petrinet:transition {
      petrinet.p - 1,
      petrinet.q + 1,
    }
    local arcs = {}
    for arc in petrinet.t:post () do
      assert.are.equal (getmetatable (arc), Petrinet.Arc)
      arcs [#arcs+1] = true
    end
    assert.are.equal (#arcs, 1)
  end)

  it ("can load the example", function ()
    local _ = require "petrinet.example"
  end)


end)
