require "actor"
require "entity"

local box = actor.new()
-- Idle state
local idleid = "idle"
fsm.vertex(box.control, idleid,
  function(c, f)

  end
)

box.visual[idleid] = function(c)
  local e = c.entity
  love.graphics.rectangle("fill", e.x - e.wx, e.y - e.wy, e.wx * 2, e.wy * 2)
end

-- Dying state
local dyingid = "dying"
local dyingtime = 0.25
fsm.vertex(box.control, dyingid,
  function(c, f)

  end
)

box.visual[dyingid] = function(c)
  local e = c.entity
  local t = (love.timer.getTime() - c.dead) / dyingtime
  love.graphics.setColor(120 * t + 200 * (1 - t), 200 * (1 - t), 120 * t + 200 * (1 - t), 255)
  love.graphics.rectangle("fill", e.x - e.wx, e.y - e.wy, e.wx * 2, e.wy * 2)
  love.graphics.setColor(255, 255, 255, 255)
end

-- Edges
fsm.connect(box.control, idleid).to(dyingid).when(
  function(c, f)
    if c.dead then return 1 end
  end
)

fsm.connect(box.control, dyingid).to("dead").when(
  function(c, f)
    if love.timer.getTime() - c.dead > dyingtime then return 1 end
  end
)

-- Init
box.context.entity = newEntity(200, -100, 10, 20)

box.hitbox = function(id, c)
  local e = c.entity
  local cb = function(ck)
    print(ck.x - e.x)
    e.vx = (ck.x - e.x) * (-100)
    c.dead = love.timer.getTime()
  end
  return {coolision.newAxisBox(e.x, e.y, e.wx, e.wy, cb)}
end

box.control.current = idleid

return box
