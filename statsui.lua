actor = actor or {}

local radius = 0.02
local drawstats = function(gamedata, id)
  while true do
    local pid = gamedata.game.playerid
    -- Render health
    local renderhp = 0
    --local maxhp = gamedata.maxhealth[pid]
    local hp = gamedata.health[pid]
    if hp then
      renderhp = hp.health - hp.damage
    else
      renderhp = gamedata.maxhealth[pid]
    end
    love.graphics.setColor(255, 0, 0)
    local offset = radius * 2.5
    for i = 1, renderhp do
      love.graphics.circle(
        "fill", radius * 1.5 + offset * (i - 1), radius * 1.5, radius, 100
      )
    end
    -- Render stamina
    local renderstam = 0
    local stam = gamedata.stamina[pid]
    if stam then
      renderstam = stam.stamina - stam.damage
    else
      renderstam = gamedata.maxstamina[pid]
    end
    love.graphics.setColor(0, 255, 0)
    for i = 1,renderstam do
      love.graphics.circle(
        "fill", radius * 1.5 + offset * (i - 1), radius * 4, radius, 100
      )
    end
    love.graphics.setColor(255, 255, 255)
    coroutine.yield()
  end
end

actor.statsui = function(gamedata, id)
  gamedata.visual.uidrawers[id] = coroutine.create(drawstats)
end
