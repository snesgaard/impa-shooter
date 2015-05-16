require "actor"
require "entity"
require "boxbullet"
require "bullet"

local function boxBullet(x, y, s)
  local face = "right"
  if s < 0 then face = "left" end
  local b = newBullet(x, y, s, face)

  local visual = {}
  table.foreach(b.visual,
    function(k, v)
      visual[k] = function(c)
        love.graphics.setColor(255, 150, 150, 255)
        v(c)
        love.graphics.setColor(255, 255, 255, 255)
      end
    end
  )
  b.visual = visual

  local hitbox = {}
  table.foreach(b.hitbox,
  function(id, h)
    hitbox[id] = function(c)
      local taggedboxes = h(c)
      table.foreach(taggedboxes,
        function(k, v)
          v.seek = {actor.types.allybody}
          v.hail = {actor.types.enemyprojectile}
        end
      )
      return taggedboxes
    end
  end
  )
  b.hitbox = hitbox

  return b
end

function newBox(x, y)
  -- Defines
  local maxfiretime = 7.0
  local minfiretime = 3.0
  local scanarea = 100

  local box = actor.new()
  -- Idle state
  local idleid = "idle"
  fsm.vertex(box.control, idleid,
    function(c, f)

    end,
    function(c, f)
      local dt = util.linterpolate(love.math.random(), minfiretime, maxfiretime)
      local t = love.timer.getTime()

      c.dofire = function() return love.timer.getTime() - t > dt end
    end
  )

  box.visual[idleid] = function(c)
    local e = c.entity
    love.graphics.rectangle("fill", e.x - e.wx, e.y - e.wy, e.wx * 2, e.wy * 2)
  end

  -- Fire state
  local fireid = "fire"
  fsm.vertex(box.control, fireid,
    function(c, f)

    end,
    function(c, f)
      local e = c.entity
      if c.playerlast then
        if e.x - c.playerlast < 0 then
          table.insert(_global.actors, boxBullet(e.x, e.y, 0.5))
        else
          table.insert(_global.actors, boxBullet(e.x, e.y, -0.5))
        end
      end
      c.dofire = function() return false end
    end
  )
  box.visual[fireid] = function(c)
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
  fsm.connect(box.control, idleid, fireid).to(dyingid).when(
    function(c, f)
      if c.dead then
        return 2
      end
    end
  )
  fsm.connect(box.control, dyingid).to("dead").when(
    function(c, f)
      if love.timer.getTime() - c.dead > dyingtime then return 1 end
    end
  )
  fsm.connect(box.control, idleid).to(fireid).when(
    function(c, f)
      if c.dofire() then
        return 1
      end
    end
  )
  fsm.connect(box.control, fireid).to(idleid).when(
    function() return 1 end
  )

  -- Init
  box.context.dofire = function() return false end
  box.context.entity = newEntity(x, y, 10, 40)

  box.hitbox[idleid] = function(c)
    local e = c.entity
    local cb = function(ck)
      -- Hack
      if ck.damage then
        e.vx = (ck.x - e.x) * (-100)
        c.dead = love.timer.getTime()
      end
    end

    local body = actor.taggedbox(
      coolision.newAxisBox(e.x - e.wx, e.y + e.wy, e.wx * 2, e.wy * 2, cb),
      actor.types.enemybody
    )

    local scb = function(pb)
      c.playerlast = pb.x + pb.w * 0.5
    end

    local scanbox = actor.taggedbox(
      coolision.newAxisBox(e.x - scanarea, e.y + scanarea, scanarea * 2, scanarea * 2, scb),
      nil,
      actor.types.allybody
    )

    return {scanbox, body}
  end

  fsm.traverse(box.control, idleid, box.context)

  return box
end
