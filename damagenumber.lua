actor = actor or {}

local cleanup = function(gamedata, id)
  gamedata.visual.drawers[id] = nil
end

local blinkfreq = 10
local blinkduration = 1.0 / blinkfreq
local speed = 50.0

local drawtext = function(text, color, x, y)
  love.graphics.setColor(unpack(color))
  love.graphics.print(text, x, y, 0, 1, -1)
  love.graphics.setColor(255, 255, 255)
end

local visual = function(gamedata, id, x, y, damage, lifetime)
  local color = {255, 50, 50}
  local pretimer = misc.createtimer(gamedata.system.time, lifetime)
  while pretimer(gamedata.system.time) do
    y = y + speed * gamedata.system.dt
    drawtext(damage, color, x, y)
    coroutine.yield()
  end
  local posttimer = misc.createtimer(gamedata.system.time, lifetime)
  while posttimer(gamedata.system.time) do
    local timer = misc.createtimer(gamedata.system.time, blinkduration)
    while timer(gamedata.system.time) do
      --y = y + speed * gamedata.system.dt
      drawtext(damage, color, x, y)
      coroutine.yield()
    end
    timer = misc.createtimer(gamedata.system.time, blinkduration)
    while timer(gamedata.system.time) do
      --y = y + speed * gamedata.system.dt
      coroutine.yield()
    end
  end
  gamedata.cleanup[id] = cleanup
end

local init = function(x, y, damage, lifetime)
  local f = function(gamedata, id)
    return visual(gamedata, id, x, y, damage, lifetime)
  end
  return f
end

actor.damagenumber = function(gamedata, id, x, y, damage, lifetime)
  gamedata.actor[id] = "damagenumber"
  gamedata.visual.drawers[id] = coroutine.create(init(x, y, damage, lifetime))
end
