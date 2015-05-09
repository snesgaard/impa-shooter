require "actor"
require "entity"

function newBoxBullet(x, y, dir)
  local bb = actor.new()

  -- Idle state
  local idleid
  bb.visual[idleid] = function(c)
    local e = c.entity
    love.graphics.setColor(255, 0, 255, 255)
    love.graphics.rectangle("fill", e.x - e.wx, e.y - e.wy, e.wx * 2, e.wy * 2)
    love.graphics.setColor(255, 255, 255, 255)
  end

  -- Init
  bb.control.current = idleid
  bb.context.entity  newEntity(x, y, 3, 1)

  return bb
end
