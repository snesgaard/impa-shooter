-- Defines
local roundtime = 60
--local roundtime = 1.0

local inputhandler = {}

function inputhandler.keypressed(key, isrepeat)
  gamedata.system.pressed[key] = gamedata.system.time
end

function inputhandler.keyreleased(key, isrepeat)
  gamedata.system.released[key] = gamedata.system.time
end


-- Rendering function
local render = {}
function render.normal()
  --love.graphics.scale(gamedata.visual.scale)
  local basecanvas = gamedata.visual.basecanvas
  basecanvas:clear()
  gfx.setCanvas(basecanvas)
  gfx.setColor(70, 70, 120)
  -- Setup camera translation
  gfx.rectangle("fill", 0, 0, gamedata.visual.width, gamedata.visual.height)
  gfx.setColor(255, 255, 255)
  local tmap = gamedata.resource.tilemaps[gamedata.global.level]
  --local pentity = gamedata.entity[gamedata.global.playerid]
  local x, y = calculatecameracenter(tmap, pentity)
  love.graphics.translate(x, y)
  -- Draw level tilemap
  coroutine.resume(gamedata.visual.leveldraw, gamedata, gamedata.global.level)
  -- Setup actor drawing transforms
  love.graphics.scale(1, -1)
  -- First sort all actors according to layers
  local sorted_drawers = {}
  --[[
  for id, d in pairs(gamedata.drawers.world) do
    local type = gamedata.actor[id]
    local order = gamedata.visual.draworder[type] or -1
    table.insert(sorted_drawers, {ord = order, id = id, co = d})
  end
  -- Sort according to layer or id
  table.sort(sorted_drawers, function(t1, t2)
    if t1.ord ~= t2.ord then
      return t1.ord < t2.ord
    else
      return t1.id < t2.id
    end
  end)
  -- Okay run drawing after sorting
  for _, t in ipairs(sorted_drawers) do
    coroutine.resume(t.co, gamedata, t.id)
  end
  ]]--
  -- Draw boxes if needed
  --[[
  if drawboxes then
    for _, subhailer in pairs(drawhailers) do
      for _, box in pairs(subhailer) do
        drawhitbox(box)
      end
    end
  end
  ]]--
  love.graphics.setColor(255, 255, 255)
  -- Reset transforms
  love.graphics.origin()
  gfx.setCanvas()
  light.draw(gamedata, basecanvas, x, y)
  -- Introduce normalize screen coordinates for UI drawing
  -- love.graphics.scale(gamedata.visual.width, gamedata.visual.width)
  love.graphics.scale(gamedata.visual.scale)
  for id, d in pairs(gamedata.drawers.ui) do
    coroutine.resume(d, gamedata, id)
  end
  -- Finally draw the time remaining
  if gamedata.timeleft > roundtime * 0.5 then
    gfx.setColor(255, 255, 255)
  elseif gamedata.timeleft > 10 then
    gfx.setColor(255, 255, 0)
  else
    gfx.setColor(255, 0, 0)
  end
  gfx.print(
    string.format("%02d", math.max(0, gamedata.timeleft)),
    gamedata.visual.width / gamedata.visual.scale * 0.5, 0
  )
end

-- gameplay related fucitonality
game = {}
game.onground = function(gamedata, id)
  local buffer = 0.1 -- Add to global data if necessary
  local g = gamedata.ground[id]
  local t = gamedata.system.time
  return g and t - g < buffer
end

game.loadimage = function(gamedata, path)
  gamedata.resource.images[path] = love.graphics.newImage(path)
end

local function mainlogic(gamedata)
  -- Move all entities
  local tmap = gamedata.resource.tilemaps[gamedata.global.activelevel]
  local ac = gamedata.actor
  for id, _ in ipairs(ac.x) do
    local x, y, vx, vy, cx, cy = mapAdvanceEntity(tmap, "game", id, gamedata)
    ac.x[id] = x
    ac.y[id] = y
    ac.vx[id] = vx
    ac.vy[id] = vy
    local tco = ac.terrainco[id]
    if tco then coroutine.resume(tco, gamedata, id, cx, cy) end
  end
  -- Initiate all coroutines
  local colrequest = {}
  for id, co in ipairs(gamedata.control) do
    colrequest[id] = coroutine.resume(gamedata)
  end

  -- Now hit detection on all registered hitboxes

  -- Align lighyt with player
  --gamedata.light.point.pos[1][1] = gamedata.entity[gamedata.game.playerid].x
  --gamedata.light.point.pos[1][2] = gamedata.entity[gamedata.game.playerid].y
  --[[
  for id, clean in pairs(gamedata.cleanup) do
    clean(gamedata, id)
    gamedata.unregister(id)
  end
  ]]--
  gamedata.cleanup = {}
end

local function donelogic(gamedata)
  -- Move all entities
  local tmap = gamedata.tilemaps[gamedata.game.activelevel]
  for _, e in pairs(gamedata.entity) do
    mapAdvanceEntity(tmap, "game", e, gamedata.system.dt)
  end
  -- Update control state for all actors
  for id, cont in pairs(gamedata.control) do
    coroutine.resume(cont, gamedata, id)
  end
  for id, clean in pairs(gamedata.cleanup) do
    clean(gamedata, id)
    gamedata.unregister(id)
  end
  gamedata.cleanup = {}
end

function game.init(gamedata)
  -- Do soft initialization here
  --[[
  initactor(gamedata, actor.statsui)
  gamedata.global.playerid = initactor(gamedata, actor.shalltear, 100, -100)
  --initactor(gamedata, actor.mobolee, 600, -100)
  gamedata.moboleemaster = initactor(
    gamedata, actor.moboleemaster, 100, 600, -110, -100, 30, 0.3
  )
  ]]--
  gamedata.visual.basecanvas = gfx.newCanvas(
    gamedata.visual.width, gamedata.visual.height
  )
  gamedata.visual.basecanvas:setFilter("nearest", "nearest")
  love.draw = render.normal
  gamedata.mobolee.timeleft = roundtime

  love.keypressed = inputhandler.keypressed
  love.keyreleased = inputhandler.keyreleased
  return game.run(gamedata)
end

function game.run(gamedata)
  -- Main game logic here
  mainlogic(gamedata)
  local pid = gamedata.global.playerid
  local actab = gamedata.actor
  local phealth = actab.health[pid] or 0
  local pdmg = actab.damage[pid] or 0
  gamedata.mobolee.timeleft = gamedata.mobolee.timeleft - gamedata.system.dt
  --[[
  if not (phealth > pdmg)  then
    --return game.done(coroutine.yield())
    -gamedata.softreset(gamedata)
    return game.init(coroutine.yield())
  --]]
  if gamedata.mobolee.timeleft < 0 or phealth <= pdmg then
    return game.done.begin(coroutine.yield())
  else
    return game.run(coroutine.yield())
  end
end

game.done = {}
local resultuicreator = require "ui/result"
function game.done.begin(gamedata)
  initactor(gamedata, resultuicreator)
  return game.done.run(gamedata)
end

function game.done.run(gamedata, resultui)
  donelogic(gamedata)
  -- Game logic here
  if player_exit then
    -- throw exit event
  end
  if player_reset then
    return game.init(coroutine.yield())
  else
    return game.done.run(coroutine.yield())
  end
end

return game
