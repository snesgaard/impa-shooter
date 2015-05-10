require "actor"
require "entity"

function newBoxBullet(x, y, face)
  -- Defines
  local speed = 150

  local bb = actor.new()
  -- Idle state
  local idleid = "idle"
  bb.visual[idleid] = function(c)
    local e = c.entity
    love.graphics.setColor(255, 255, 0, 255)
    love.graphics.rectangle("fill", e.x - e.wx, e.y - e.wy, e.wx * 2, e.wy * 2)
    love.graphics.setColor(255, 255, 255, 255)
  end

  -- Init
  bb.control.current = idleid
  local e = newEntity(x, y, 3, 1)
  bb.context.entity = e
  e.face = face
  if face == "right" then
    e.vx = speed
  elseif face == "left" then
    e.vx = -speed
  else
    error("Invalid face value was given: " .. face)
  end
  e._do_gravity = false

  return bb
end
