input = {}

function input.isdown(gamedata, key)
  local p = gamedata.system.pressed[key] or 0
  local r = gamedata.system.released[key] or 0
  return p > r
end

function input.ispressed(gamedata, key)
  local p = gamedata.system.pressed[key] or 0
  local t = gamedata.system.time
  local b = gamedata.system.buffer[key] or 0.2
  return p and t - p < b
end

function input.latch(gamedata, key)
  gamedata.system.pressed[key] = 0
end


return input
