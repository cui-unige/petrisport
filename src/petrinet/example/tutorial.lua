local Petrinet = require "petrinet"
local result   = Petrinet ()

result.p0 = result:place {
  name    = "P0",
  marking = 0,
  x       = 0,
  y       = 0,
}
result.p1 = result:place {
  name    = "P1",
  marking = 0,
  x       = 2,
  y       = 1,
}
result.p2 = result:place {
  name    = "P2",
  marking = 0,
  x       = 2,
  y       = -1,
}
result.p3 = result:place {
  name    = "P3",
  marking = 0,
  x       = 4,
  y       = 0,
}

result.t0 = result:transition {
  name = "T0",
  x    = 0,
  y    = 1,
  result.p0 + 1,
}
result.t1 = result:transition {
  name = "T1",
  x    = 1,
  y    = 1,
  result.p0 - 1,
  result.p1 + 1,
}
result.t2 = result:transition {
  name = "T2",
  x    = 1,
  y    = -1,
  result.p0 - 1,
  result.p1 + 1,
  result.p2 + 1,
}
result.t3 = result:transition {
  name = "T3",
  x    = 3,
  y    = 0,
  result.p1 - 2,
  result.p2 - 1,
  result.p3 + 1,
}
result.t4 = result:transition {
  name = "T4",
  x    = 4,
  y    = 1,
  result.p3 - 1,
}

return result
