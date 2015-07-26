require "entity"

actor = actor or {}

local w = 20
local h = 20

local function draw(gamedata, id)
  while true do
    local e = gamedata.entity[id]
    love.graphics.rectangle("fill", e.x - w, e.y - h, w * 2, h * 2)
    coroutine.yield()
  end
end

local moverate = 100
local function control(gamedata, id)
  local codraw = coroutine.create(draw)
  gamedata.visual.drawers[id] = codraw
  while true do
    -- Set body coordinates
    local body = gamedata.hitbox[id].body
    local entity = gamedata.entity[id]
    body.x = entity.x - w
    body.y = entity.y + h
    coroutine.yield()
  end
end

actor.box = function(gamedata, id, x, y)
  gamedata.actor[id] = "box"
  gamedata.entity[id] = newEntity(x, y, w, h)
  gamedata.control[id] = coroutine.create(control)
  gamedata.soak[id] = 0
  gamedata.reduce[id] = 1
  gamedata.invincibility[id] = 0
  local body = coolision.newAxisBox(
    id, x - w, y + h, w * 2, h * 2, gamedata.hitboxtypes.enemybody
  )
  body.applydamage = function(otherid, x, y, damage)
    local s = gamedata.soak[id]
    local r = gamedata.reduce[id]
    local i = gamedata.invincibility[id]
    local d = combat.calculatedamage(damage, s, r, i)
    print("pow", d)
    return d
  end
  gamedata.hitbox[id] = {
    body = body
  }
end
