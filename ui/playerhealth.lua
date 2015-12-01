actor = actor or {}
loaders = loaders or {}

local images = {
  hporb = "res/healthgem.png",
  stamorb = "res/stamgem.png",
}
local radius = 3

loaders.playerhealth = function(gamedata)
  for _, path in pairs(images) do
    gamedata.resource.images[path] = love.graphics.newImage(path)
  end
end
local run
run = function(gamedata, id, pid)
  -- Render health
  local actor = gamedata.actor
  local renderhp = 0
  --local maxhp = gamedata.maxhealth[pid]
  local hp = actor.health[pid]
  local dmg = actor.damage[pid]
  local hpim = gamedata.resource.images[images.hporb]
  if hp and dmg then
    renderhp = hp - dmg
  else
    renderhp = hp or 0
  end
  local offset = 10
  for i = 1, renderhp do
    love.graphics.draw(
      hpim, radius * 2.0 + offset * (i - 1) - 4, radius * 2.0 - 4
    )
  end
  -- Render stamina

  local renderstam = 0
  local stam = actor.stamina[pid]
  local ustam = actor.usedstamina[pid]
  local stamim = gamedata.resource.images[images.stamorb]
  if stam and ustam then
    renderstam = stam - math.ceil(ustam)
  else
    renderstam = stam or 0
  end
  --love.graphics.setColor(75, 255, 75)
  for i = 1,renderstam do
    love.graphics.draw(
      stamim, radius * 2.0 + offset * (i - 1) - 4, radius * 5.0 - 3
    )
  end
  -- Render missing stamina
  if ustam then
    local nextstam = 1.0 - (math.ceil(ustam) - ustam)
    local mw = 40
    local mh = 2
    love.graphics.setColor(75, 255, 75)
    gfx.rectangle("fill", 3, 22, mw * nextstam, mh)
  end
  love.graphics.setColor(255, 255, 255)
  gamedata, id = coroutine.yield()
  return run(gamedata, id, pid)
end


local function create(pid)
  return function(gamedata, id)
    return run(gamedata, id, pid)
  end
end

function actor.playerhealth(ui, id, x, y, pid)
  ui.x[id] = x
  ui.y[id] = y
  ui.draw[id] = coroutine.create(create(pid))
end
