global = {}

local function do_entry(key)
  global[key] = {}
end

local seed = 0
global.genid = function()
  local s = seed
  seed = seed + 1
  return s
end

global.runinit = function(_global, f, ...)
  local k = _global.genid()
  f(_global, k, ...)
  table.insert(_global.actorids, id)
  return k
end

do_entry("health")
do_entry("maxhealth")
do_entry("stamina")
do_entry("maxstamina")
do_entry("soak")
do_entry("reduce")
do_entry("invicibility")
do_entry("animation")
do_entry("finitestatemachine")
do_entry("actors")
