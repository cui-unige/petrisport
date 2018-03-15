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
  "busted",
  "luacheck",
  "cluacov",
  "coronest",
  "etlua",
}

build = {
  type    = "builtin",
  modules = {
    ["petrinet"] = "src/petrinet/init.lua",
  },
}
