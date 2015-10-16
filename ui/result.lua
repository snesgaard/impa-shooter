local function getdims(gamedata)
  local x = 100
  local y = 100
  local w = gamedata.visual.width - x * 2
  local h = gamedata.visual.height - y * 2
  local s = 1.0 / gamedata.visual.scale
  return x * s, y * s, w * s, h * s
end

local draw = {}

local fadeintime = 0.75
local color = {0, 0, 0, 200}
function draw.fadein(gamedata, id)
  local inittime = gamedata.system.time
  local timer = misc.createtimer(inittime, fadeintime)
  local x, y, w, h = getdims(gamedata)
  while timer(gamedata.system.time) do
    local s = (gamedata.system.time - inittime) / fadeintime
    gfx.setColor(unpack(color))
    local tmpx = x * s + (x + w * 0.5) * (1 - s)
    local tmpy = y * s + (y + h * 0.5) * (1 - s)
    gfx.rectangle("fill", tmpx, tmpy, w * s, h * s)
    coroutine.yield()
  end
  return draw.idle(gamedata, id)
end

local txtcolor = {255, 255, 255}
function draw.idle(gamedata, id)
  local x, y, w, h = getdims(gamedata)
  gfx.setColor(unpack(color))
  gfx.rectangle("fill", x, y, w, h)
  gfx.setColor(unpack(txtcolor))
  gfx.print(
    string.format("Final Score: %i", gamedata.score), x + w * 0.5 - 40,
    y + h * 0.5 - 50
  )
  return draw.idle(coroutine.yield())
end

local function create(gamedata, id)
  gamedata.visual.uidrawers[id] = coroutine.create(draw.fadein)
end

return create
