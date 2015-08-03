actor = actor or {}
loaders = loaders or {}

local images = {
  riflebullet = "res/impa/riflebulletui.png"
}

loaders.statsui = function(gamedata)
  for _, path in pairs(images) do
    gamedata.visual.images[path] = love.graphics.newImage(path)
  end
end

local radius = 0.02
local bulletscale = 0.001
local bulletframe = {
  w = 50,
  h = 19,
}

local drawstats = function(gamedata, id)
  local riflebullet = newAnimation(
    gamedata.visual.images[images.riflebullet], bulletframe.w, bulletframe.h,
    0, 1
  )
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
    -- Render ammunition:
    -- TODO should pick whatever selected weapon
    local wid = gamedata.weapons.inuse[pid]
    local maxa = gamedata.weapons.maxammo[wid]
    local missa = gamedata.weapons.usedammo[wid] or 0
    local renderammo =  maxa - missa
    love.graphics.setColor(255, 255, 255)
    for ammo = 1, renderammo do
      --love.graphics.circle(
      --  "fill", radius * 1.5 + offset * (ammo - 1), radius * 6.5, radius, 100
      --)
      riflebullet:draw(
        radius * 1.5, radius * 6.5  + offset * (maxa - ammo), 0,
        bulletscale, bulletscale
      )
    end
    coroutine.yield()
  end
end

actor.statsui = function(gamedata, id)
  gamedata.visual.uidrawers[id] = coroutine.create(drawstats)
end
