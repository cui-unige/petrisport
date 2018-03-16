local assert   = require "luassert"
local Analysis = require "petrinet.analysis"
local petrinet = require "petrinet.example"

describe ("Analysis", function ()

  it ("can compute the choice ratio", function ()
    local analysis = Analysis {
      petrinet = petrinet,
      free     = 2,
    }
    assert.is.not_nil (analysis:choice ())
  end)


end)
