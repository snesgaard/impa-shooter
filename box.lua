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
    local e = gamedata.entity[id]
    -- Update vx
    local vx = 0
    if input.isdown(gamedata, "right") then
      vx = vx + moverate
    end
    if input.isdown(gamedata, "left") then
      vx = vx - moverate
    end
    e.vx = vx
    -- Update vy
    local vy = 0
    if input.isdown(gamedata, "up") then
      vy = vy + moverate
    end
    if vy ~= 0 then e.vy = vy end
    coroutine.yield()
  end
end

actor.box = function(gamedata, id, x, y)
  gamedata.entity[id] = newEntity(x, y, w, h)
  gamedata.control[id] = coroutine.create(control)
  local body = coolision.newAxisBox(x - w, y + h, w * 2, h * 2)
end
