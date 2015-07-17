require "actor"

function newhealthbar(globaltable, id, pcid)

  local hbar = actor.new()
  local vis = hbar.visual
  local ctrl = hbar.control
  local con = hbar.context

  -- Idle state
  local idleid = "idle"
  vis[idleid] = function(c)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setColor(255, 50, 50, 255)
    local h = globaltable.health[pcid]--c.health
    for x = 1, h do
      love.graphics.circle("fill", (x - 1) * 50 + c.x, c.y, 20, 20)
    end
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.pop()
  end

  -- Init
  --con.health = maxhealth
  con.x = 30
  con.y = 30

  ctrl.current = idleid

  -- Global API
  health = {}
  health.reduce = function(n)
    local h = globaltable.health[pcid]
    if h > n then
      globaltable.health[pcid] = h - n
      return true
    end
    return false
  end

  return hbar
end
