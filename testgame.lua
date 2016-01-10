require "ui/playerhealth"
require "math"

local game = {}

local function round(num)
    if num >= 0 then return math.floor(num+.5)
    else return math.ceil(num-.5) end
end

local function calccamera(ex, ey, w, h, s)
  local x = ex
  local y = ey
  return 0, 0
end

function game.init(gamedata, colres, combatreq, combatres)
  -- Init entities
  local kid = knight.add(gamedata, 300, -160)
  local playerid = shalltear.add(gamedata, 200.98, -160)
  -- Init control scipts
  local playercontrol = shalltear.control(playerid)
  local shaker = camera.hitshaker(playerid)
  local tracker = camera.track(playerid)
  -- Init UI elements
  local phealth = initresource(
    gamedata.ui, actor.playerhealth, 0, 0, playerid
  )
  local actor = gamedata.actor
  local actpick = function(gd, id)
    local pa = {knight.action.poke, knight.action.upslash, knight.action.evadeslash}
    a = pa[love.math.random(1, 3)]
    return a(gd, id, playerid)
  end
  actor.action[kid] = coroutine.create(actpick)
  while true do
    -- AI
    if coroutine.status(actor.action[kid]) == "dead" then
      actor.action[kid] = coroutine.create(actpick)
    end
    coroutine.resume(playercontrol, gamedata, playerid, colres, combatres)

    -- Camera logic
    local _, cx, cy = coroutine.resume(shaker, gamedata, combatreq)
    local _, tx, ty = coroutine.resume(tracker, gamedata)
    local t = gamedata.system.time
    local s = gamedata.visual.scale
    local w = gamedata.visual.width
    local h = gamedata.visual.height
    local x = math.floor(tx + cx) * s - w / 2
    local y = math.floor(ty + cy) * s + h / 2
    -- Clamp camera to the boundries of the current map
    local level = gamedata.global.level
    local map = gamedata.resource.tilemaps[level]
    local mw = map.width * map.tilewidth * s
    local mh = map.height * map.tileheight * s
    gamedata.visual.x = math.max(0, math.min(mw - w, x))
    gamedata.visual.y = math.min(0, math.max(h - mh, y))



    gamedata, colres, combatreq, combatres = coroutine.yield()
  end
end

return game
