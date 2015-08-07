require "globaldata" -- THis will generate the global "data" table
require "game"
require "input"
require "coroutine"
require "combat"
require ("modules/AnAL")
require ("modules/tilephysics")
require ("modules/coolision")
local misc = require ("modules/misc")
local sti = require ("modules/sti")
require ("actors/box")
require ("actors/impa")
require "statsui"

function loadanimation(path, ...)
  local im = love.graphics.newImage(path)
  return newAnimation(im, ...)
end

function table.shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function love.keypressed(key, isrepeat)
  print(key)
  gamedata.system.pressed[key] = gamedata.system.time
end

function love.keyreleased(key, isrepeat)
  gamedata.system.released[key] = gamedata.system.time
end

-- Utility
function createmapdrawer(mapkey)
  local co = coroutine.create(function(gamedata)
    while true do
      love.graphics.setBackgroundColor(70, 70, 120, 255)
      local map = gamedata.tilemaps[mapkey]
      map:draw()
      coroutine.yield()
    end
  end)
  return co
end
function calculatecameracenter(map, entity)
  if not entity then return 0, 0 end
  local mw = map.width * map.tilewidth
  local mh = map.height * map.tileheight
  local w = gamedata.visual.width
  local h = gamedata.visual.height
  local s = gamedata.visual.scale
  local ex = entity.x
  local ey = entity.y
  local x = math.min(map.x + mw - w / s, math.max(-map.x, ex - 0.5 * w / s))
  local y = math.max(map.y - mh + h / s, math.min(map.y, ey + 0.5 * h / s))
  return -x, y
end

-- Timer and break condition related functions
-- This function waits until annointed time or interrupt conditions occur
coroutine.wait = function(gamedata, duration, interrupt)
  local t = gamedata.system.time
  while gamedata.system.time - t < duration do
    if interrupt and interrupt() then return false end
    coroutine.yield()
  end
  return true
end
-- redefine coroutine resume to be a bit more verbose
_coroutine_resume = coroutine.resume
function coroutine.resume(...)
	local state,result = _coroutine_resume(...)
	if not state then
		error( tostring(result), 2 )	-- Output error message
	end
	return state,result
end

local levelpath = "res/rainylevel"
local levelid
local leveldraw
function love.load()
  -- Set filtering to nearest neighor
  local filter = "nearest"
  love.graphics.setDefaultFilter(filter, filter, 0)
  gamedata.visual.scale = 2
  gamedata.visual.width = love.graphics.getWidth()
  gamedata.visual.height = love.graphics.getHeight()
  gamedata.visual.aspect = gamedata.visual.width / gamedata.visual.height
  -- Load stage
  levelid = gamedata.genid()
  gamedata.tilemaps[levelid] = sti.new(levelpath)
  misc.setPosSTIMap(gamedata.tilemaps[levelid], 0, 0)
  gamedata.game.activelevel = levelid
  local leveldraw = createmapdrawer(levelid)
  -- Update map and insert drawer
  gamedata.visual.leveldraw = leveldraw
  -- Load resoures
  loaders.impa(gamedata)
  loaders.gunexhaust(gamedata)
  loaders.bullet(gamedata)
  loaders.statsui(gamedata)
  -- Create actors and collect ids
  gamedata.game.playerid = gamedata.init(gamedata, actor.impa, 200, -100)
  gamedata.init(gamedata, actor.statsui)
  gamedata.init(gamedata, actor.box, 300, -100)
end

function love.update(dt)
  -- Check for exit
  if gamedata.system.pressed["escape"] then love.event.quit() end
  -- Update time
  gamedata.system.time = love.timer.getTime()
  gamedata.system.dt = dt
  -- Move all entities
  local tmap = gamedata.tilemaps[gamedata.game.activelevel]
  for _, e in pairs(gamedata.entity) do
    mapAdvanceEntity(tmap, "game", e, dt)
  end
  -- Now hit detection on all registered hitboxes
  local seekers, hailers = coolision.sortcollisiongroups(gamedata.hitbox)
  coolision.docollisiongroups(seekers, hailers)
  -- Update weapon data
  rifle.updatemultipliers(gamedata)
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

function love.draw()
  love.graphics.scale(gamedata.visual.scale)
  -- Setup camera translation
  local tmap = gamedata.tilemaps[gamedata.game.activelevel]
  local pentity = gamedata.entity[gamedata.game.playerid]
  love.graphics.translate(calculatecameracenter(tmap, pentity))
  -- Draw level tilemap
  coroutine.resume(gamedata.visual.leveldraw, gamedata, gamedata.game.activelevel)
  -- Setup actor drawing transforms
  love.graphics.scale(1, -1)
  -- First sort all actors according to layers
  local sorted_drawers = {}
  for id, d in pairs(gamedata.visual.drawers) do
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
  love.graphics.setColor(255, 255, 255)
  -- Reset transforms
  love.graphics.origin()
  -- Introduce normalize screen coordinates for UI drawing
  -- love.graphics.scale(gamedata.visual.width, gamedata.visual.width)
  for id, d in pairs(gamedata.visual.uidrawers) do
    coroutine.resume(d, gamedata, id)
  end
end
