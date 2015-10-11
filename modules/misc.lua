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
misc.createrepeatdrawer = function(anim, ox, oy)
  anim:reset()
  anim:play()
  local w = anim:getWidth() / 2
  local h = anim:getHeight() / 2
  ox = ox or 0
  oy = oy or 0
  local co = coroutine.create(function(gamedata, id)
    while true do
      local e = gamedata.entity[id]
      local f = gamedata.face[id]
      anim:update(gamedata.system.dt)
      local y = e.y + h + oy
      local x
      local s
      if f == "right" then
        x = e.x - w + ox
        s = 1
      else
        x = e.x + w + ox
        s = -1
      end
      anim:draw(math.floor(x), math.floor(y), 0, s, -1)
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
  local y = e.y + h
  if f == "right" then
    anim:draw(math.floor(e.x - w), math.floor(y), 0, 1, -1)
  else
    anim:draw(math.floor(e.x + w), math.ceil(y), 0, -1, -1)
  end
end
misc.drawsprite = function(anime, x, y, face)
  local w = anime:getWidth() * 0.5
  local h = anime:getHeight() * 0.5
  if face == "right" then
    anime:draw(math.floor(x - w), math.floor(y + h), 0, 1, -1)
  else
    anime:draw(math.floor(x + w), math.floor(y + h), 0, -1, -1)
  end
end
misc.createtimer = function(start, duration)
  return function(time)
    return time - start < duration
  end
end
misc.wait = function(gamedata, duration)
  local timer = misc.createtimer(gamedata.system.time, duration)
  while timer(gamedata.system.time) do coroutine.yield() end
end
misc.createhbsync = function(hitboxid, x, y)
  local f
  f = function(gamedata, id)
    local e = gamedata.entity[id]
    local hb = gamedata.hitbox[id][hitboxid]
    local face = gamedata.face[id]
    hb.y = e.y + y
    if face == "right" then
      hb.x = e.x + x
    else
      hb.x = e.x - x - hb.w
    end
    coroutine.yield()
    return f(gamedata, id)
  end
  return f
end

return misc
