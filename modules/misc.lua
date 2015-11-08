misc = {}
misc.setPosSTIMap = function(map, x, y)
  for _, layer in pairs(map.layers) do
    layer.x = x
    layer.y = -y
  end
  map.x = x
  map.y = y
  return map
end
misc.createdrawer = function(animeid, mode, ox, oy)
  ox = ox or 0
  oy = oy or 0
  mode = mode or "repeat"
  local w
  local h
  local draw
  local begin = function(gamedata, id)
    local anime = gamedata.animations[animeid]
    anime:setMode(mode)
    anime:reset()
    anime:play()
    w = anime:getWidth() / 2
    h = anime:getHeight() / 2
    return draw(gamedata, id)
  end
  draw = function(gamedata, id)
    local anime = gamedata.animations[animeid]
    local act = gamedata.actor
    local f = act.face[id]
    local x = act.x[id] - f * w + ox
    local y = act.y[id] + h + oy
    anime:draw(math.floor(x), math.floor(y), 0, f, -1)
    anime:update(gamedata.system.dt)
    return draw(coroutine.yield())
  end

  return coroutine.create(begin)
end
misc.createtimer = function(gamedata, duration)
  local start = gamedata.system.time
  return function(gamedata)
    return gamedata.system.time - start < duration
  end
end
misc.createinterval = function(gamedata, start, duration)
  local stamp = gamedata.system.time
  local stoptime = start + duration
  return function(gamedata)
    local t = gamedata.system.time
    local dostart = t - stamp > start
    local dostop = t - stamp > stoptime
    return dostart and not dostop
  end
end
misc.wait = function(gamedata, duration)
  local timer = misc.createtimer(gamedata.system.time, duration)
  while timer(gamedata.system.time) do coroutine.yield() end
end

return misc
