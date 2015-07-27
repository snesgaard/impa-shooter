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
misc.createrepeatdrawer = function(anim)
  anim:reset()
  anim:play()
  local w = anim:getWidth() / 2
  local h = anim:getHeight() / 2
  local co = coroutine.create(function(gamedata, id)
    while true do
      local e = gamedata.entity[id]
      local f = gamedata.face[id]
      anim:update(gamedata.system.dt)
      if f == "right" then
        anim:draw(e.x - w, e.y + h, 0, 1, -1)
      else
        anim:draw(e.x + w, e.y + h, 0, -1, -1)
      end
      coroutine.yield()
    end
  end)
  return co
end
misc.createoneshotdrawer = function(anime)
  anime:setMode("once")
  return misc.createrepeatdrawer(anime)
end
misc.createbouncedrawer = function(anime)
  anime:setMode("bounce")
  return misc.createrepeatdrawer(anime)
end
misc.draw_sprite_entity = function(anim, entity, face)
  local e = entity
  local f = face
  local w = anim:getWidth() * 0.5
  local h = anim:getHeight() * 0.5
  if f == "right" then
    anim:draw(e.x - w, e.y + h, 0, 1, -1)
  else
    anim:draw(e.x + w, e.y + h, 0, -1, -1)
  end
end
misc.createtimer = function(start, duration)
  return function(time)
    return time - start < duration
  end
end

return misc
