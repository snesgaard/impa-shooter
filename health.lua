require "actor"

local hbar = actor.new()
local vis = hbar.visual
local ctrl = hbar.control
local con = hbar.context

-- Defines
local maxhealth = 4

-- Idle state
local idleid = "idle"
vis[idleid] = function(c)
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setColor(255, 50, 50, 255)
  local h = c.health
  for x = 1, h do
    love.graphics.circle("fill", (x - 1) * 50 + c.x, c.y, 20, 20)
  end
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.pop()
end

-- Init
con.health = maxhealth
con.x = 30
con.y = 30

ctrl.current = idleid

return hbar
