local Petrinet = require "petrinet"
local result   = Petrinet ()

result.p0 = result:place {
  name    = "P0",
  marking = 1,
  x       = 0,
  y       = 2,
}
result.p1 = result:place {
  name    = "P1",
  marking = 1,
  x       = -4,
  y       = 0,
}
result.p2 = result:place {
  name    = "P2",
  marking = 1,
  x       = -3,
  y       = 0,
}
result.p3 = result:place {
  name    = "P3",
  marking = 0,
  x       = -2,
  y       = 0,
}
result.p4 = result:place {
  name    = "P4",
  marking = 0,
  x       = -1,
  y       = 0,
}
result.p5 = result:place {
  name    = "P5",
  marking = 1,
  x       = 0,
  y       = 0,
}
result.p6 = result:place {
  name    = "P6",
  marking = 0,
  x       = 2,
  y       = 0,
}
result.p7 = result:place {
  name    = "P7",
  marking = 0,
  x       = 4,
  y       = 0,
}
result.p8 = result:place {
  name    = "P8",
  marking = 0,
  x       = 0,
  y       = -2,
}

result.t0 = result:transition {
  name = "T0",
  x    = -1,
  y    =  1,
  result.p3 - 1,
  result.p4 - 1,
  result.p5 - 1,
  result.p0 + 1,
  result.p1 + 1,
  result.p2 + 1,
}
result.t1 = result:transition {
  name = "T1",
  x    = -1,
  y    = -1,
  result.p1 - 1,
  result.p2 - 1,
  result.p8 - 1,
  result.p3 + 1,
  result.p4 + 1,
  result.p5 + 1,
}
result.t2 = result:transition {
  name = "T2",
  x    = 2,
  y    = 1,
  result.p0 - 1,
  result.p5 - 1,
  result.p6 + 1,
  result.p7 + 1,
}
result.t3 = result:transition {
  name = "T3",
  x    =  2,
  y    = -1,
  result.p6 - 1,
  result.p7 - 1,
  result.p5 + 1,
  result.p8 + 1,
}

return result
