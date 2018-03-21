-- luacheck: std rockspec

package = "petrisport"
version = "master-1"
source  = {
  url    = "git+https://github.com/saucisson/petri-sport.git",
  branch = "master",
}

description = {
  summary    = "Petri sport",
  detailed   = [[]],
  homepage   = "https://github.com/saucisson/petri-sport",
  license    = "MIT/X11",
  maintainer = "Alban Linard <alban@linard.fr>",
}

dependencies = {
  "lua >= 5.1",
  "argparse",
  "busted",
  "luacheck",
  "cluacov",
  "coronest",
  "etlua",
  "luaexpat",
  "luafilesystem",
}

build = {
  type    = "builtin",
  modules = {
    ["petrinet"             ] = "src/petrinet/init.lua",
    ["petrinet.marking"     ] = "src/petrinet/marking/init.lua",
    ["petrinet.state"       ] = "src/petrinet/state/init.lua",
    ["petrinet.reachability"] = "src/petrinet/reachability/init.lua",
    ["petrinet.analysis"    ] = "src/petrinet/analysis/init.lua",
    ["petrinet.example.dimitri"     ] = "src/petrinet/example/dimitri.lua",
    ["petrinet.example.flag"        ] = "src/petrinet/example/flag.lua",
    ["petrinet.example.philosophers"] = "src/petrinet/example/philosophers.lua",
  },
  install = {
    bin = {
      ["petri-sport"] = "src/petrinet/bin.lua",
    },
  },
}
