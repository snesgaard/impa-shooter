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

local function createdeathaction(gamedata, id)
  local co
  local death = gamedata.actor.death[id]
  if death then
    co = coroutine.create(function(gamedata, id, framedata)
      local deathco = coroutine.create(death)
      local status
      repeat
        status = coroutine.resume(deathco, gamedata, id, framedata)
        gamedata, id, framedata = coroutine.yield()
      until status == "dead"
      freeresource(gamedata.actor, id)
    end)
  else
    co = coroutine.create(function(gamedata, id, framedata)
      freeresource(gamedata.actor, id)
    end)
  end
  return co
end

function game.init(gamedata, colres, combatreq, combatres)
  -- Init entities
  local kid = knight.add(gamedata, 300, -160)
  local kid2 = knight.add(gamedata, 400, -160)
  local kid2 = knight.add(gamedata, 500, -160)
  local playerid = shalltear.add(gamedata, 200.98, -160)
  -- Init control scipts
  local shaker = camera.hitshaker(playerid)
  local tracker = camera.track(playerid)
  -- Init UI elements
  local phealth = initresource(
    gamedata.ui, actor.playerhealth, 0, 0, playerid
  )
  -- Init checker for death
  for id, ctrl in pairs(gamedata.actor.control) do
    gamedata.actor.control[id] = coroutine.create(function(gd, id, fd)
      while true do
        coroutine.resume(ctrl, gd, id, fd)
        if ai.healthleft(gd, id) <= 0 then
          gamedata.actor.control[id] = createdeathaction(gd, id)
        end
        coroutine.yield()
      end
    end)
  end
  -- Framedata
  local fd = {
    playerid = playerid,
    colres = colres,
    combatreq = combatreq,
    combatres = combatres,
  }
  while true do
    -- AI
    for id, ctrl in pairs(gamedata.actor.control) do
      coroutine.resume(ctrl, gamedata, id, fd)
    end
    -- Camera logic
    local _, cx, cy = coroutine.resume(shaker, gamedata, fd.combatreq)
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

    -- Update stamina
    local act = gamedata.actor
    for id, u in pairs(act.usedstamina) do
      local r = act.recover[id]
      u = u - r * gamedata.system.dt
      if u < 0 then u = nil end
      act.usedstamina[id] = u
    end

    gamedata, fd.colres, fd.combatreq, fd.combatres = coroutine.yield()
  end
end

return game
