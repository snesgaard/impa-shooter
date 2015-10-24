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
require ("actors/mobolee")
require ("actors/shalltear")
require ("actors/moboleemaster")
require "statsui"
require ("modules/functional")
require "light"

function loadanimation(path, ...)
  local im = love.graphics.newImage(path)
  return newAnimation(im, ...)
end

function loadspriteimage(path)
  return love.graphics.newImage(path)
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

function drawhitbox(hitbox)
  love.graphics.rectangle("line", hitbox.x, hitbox.y, hitbox.w, -hitbox.h)
end
drawboxes = false

function love.keypressed(key, isrepeat)
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
      local map = gamedata.resource.tilemaps[mapkey]
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
  local my = math.floor(ey) + math.floor(0.5 * h / s)
  local y = math.max(map.y - mh + h / s, math.min(map.y, my))
  return math.floor(-x), math.floor(y)
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

local levelpath = "res/rainylevel.lua"
local leveldraw
function love.load()
  -- Some global names
  gfx = love.graphics
  -- Set filtering to nearest neighor
  local filter = "nearest"
  local s = 4
  love.graphics.setDefaultFilter(filter, filter, 0)
  gamedata.visual.scale = s
  gamedata.visual.width = love.graphics.getWidth()
  gamedata.visual.height = love.graphics.getHeight()
  gamedata.visual.aspect = gamedata.visual.width / gamedata.visual.height
  -- Load stage
  --levelid = gamedata.genid()
  gamedata.resource.tilemaps[levelpath] = sti.new(levelpath)
  misc.setPosSTIMap(gamedata.resource.tilemaps[levelpath], 0, 0)
  gamedata.global.level = levelpath
  local leveldraw = createmapdrawer(levelpath)
  -- Update map and insert drawer
  gamedata.visual.leveldraw = leveldraw
  -- Load resoures
  loaders.statsui(gamedata)
  loaders.mobolee(gamedata)
  loaders.light(gamedata)
  loaders.shalltear(gamedata)
  -- Canvas
  --basecanvas = gfx.newCanvas(
  --  gamedata.visual.width, gamedata.visual.height
  --)
  --basecanvas:setFilter(filter, filter)
  light.testsetup(gamedata)
  -- Create actors and collect ids
  --[[
  gamedata.init(gamedata, actor.statsui)
  gamedata.game.playerid = gamedata.init(gamedata, actor.shalltear, 100, -100)
  gamedata.init(gamedata, actor.mobolee, 400, -100)
  gamedata.init(gamedata, actor.mobolee, 500, -100)
  ]]--
  gameco = coroutine.create(game.init)
end

function love.update(dt)
  -- Check for exit
  if gamedata.system.pressed["escape"] then love.event.quit() end
  -- Update time
  gamedata.system.time = love.timer.getTime()
  gamedata.system.dt = dt
  coroutine.resume(gameco, gamedata)
end

function love.draw()
  --love.graphics.scale(gamedata.visual.scale)
  basecanvas:clear()
  gfx.setCanvas(basecanvas)
  gfx.setColor(70, 70, 120)
  -- Setup camera translation
  gfx.rectangle("fill", 0, 0, gamedata.visual.width, gamedata.visual.height)
  gfx.setColor(255, 255, 255)
  local tmap = gamedata.tilemaps[gamedata.game.activelevel]
  local pentity = gamedata.entity[gamedata.game.playerid]
  local x, y = calculatecameracenter(tmap, pentity)
  love.graphics.translate(x, y)
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
  -- Draw boxes if needed
  if drawboxes then
    for _, subhailer in pairs(drawhailers) do
      for _, box in pairs(subhailer) do
        drawhitbox(box)
      end
    end
  end
  love.graphics.setColor(255, 255, 255)
  -- Reset transforms
  love.graphics.origin()
  gfx.setCanvas()
  light.draw(gamedata, basecanvas, x, y)
  -- Introduce normalize screen coordinates for UI drawing
  -- love.graphics.scale(gamedata.visual.width, gamedata.visual.width)
  love.graphics.scale(gamedata.visual.scale)
  for id, d in pairs(gamedata.visual.uidrawers) do
    coroutine.resume(d, gamedata, id)
  end
end
