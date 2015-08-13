actor = actor or {}
loaders = loaders or {}

local images = {
  hporb = "res/healthgem.png",
  stamorb = "res/stamgem.png",
}
local radius = 3

loaders.statsui = function(gamedata)
  for _, path in pairs(images) do
    gamedata.visual.images[path] = love.graphics.newImage(path)
  end
end

local drawstats = function(gamedata, id)
  while true do
    local pid = gamedata.game.playerid
    -- Render health
    local renderhp = 0
    --local maxhp = gamedata.maxhealth[pid]
    local hp = gamedata.health[pid]
    local hpim = gamedata.visual.images[images.hporb]
    if hp then
      renderhp = hp.health - hp.damage
    else
      renderhp = gamedata.maxhealth[pid]
    end
    --love.graphics.setColor(255, 75, 75)
    local offset = 10
    for i = 1, renderhp do
      love.graphics.draw(
        hpim, radius * 2.0 + offset * (i - 1) - 4, radius * 2.0 - 4
      )
    end
    -- Render stamina
    local renderstam = 0
    local stam = gamedata.stamina[pid]
    local stamim = gamedata.visual.images[images.stamorb]
    if stam then
      renderstam = stam.stamina - stam.damage
    else
      renderstam = gamedata.maxstamina[pid]
    end
    --love.graphics.setColor(75, 255, 75)
    for i = 1,renderstam do
      love.graphics.draw(
        stamim, radius * 2.0 + offset * (i - 1) - 4, radius * 5.0 - 3
      )
--      love.graphics.circle(
  --      "fill", radius * 2.0 + offset * (i - 1), radius * 5, radius, 100
    --  )
    end
    love.graphics.setColor(255, 255, 255)
    coroutine.yield()
  end
end

actor.statsui = function(gamedata, id)
  gamedata.visual.uidrawers[id] = coroutine.create(drawstats)
end
