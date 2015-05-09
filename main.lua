require "math"
require ("modules/AnAL")
require "actor"
local sti = require ("modules/sti")
require ("modules/tilephysics")
local misc = require ("modules/misc")
require ("modules/coolision")
require "box"

function loadanimation(path, ...)
  local im = love.graphics.newImage(path)
  return newAnimation(im, ...)
end

function xor(a, b)
  a = a or false
  b = b or false
  return (a or b) and (not (a and b))
end

function love.keypressed(key, isrepeat)
  framedata.keyboard[key] = love.timer.getTime()
  --print(key)
end

function love.load()
  local filter = "nearest"
  love.graphics.setDefaultFilter(filter, filter, 0)
  framedata = {keyboard = {}}
  _global = {}

  --Global init
  _global.actors = {
    --box = newBox(200, -100),
    impa = require "impa",
    actioncharges = require "actioncharges",
    health = require "health",
    bullet = bullet,
  }
  for i = 1, 20 do
    table.insert(_global.actors, newBox(200 + i * 50, -100))
  end
  _global.map = sti.new("test")
  misc.setPosSTIMap(_global.map, 0, 0)
end


function love.update(dt)
  framedata.dt = dt

  -- Tilemap collisions
  _global.map:update(dt)
  table.foreach(_global.actors, function(_, a)
    if a.context.entity then
      mapAdvanceEntity(_global.map, "game", a.context.entity, dt)
    end
  end)

  -- Hitbox collision
  local boxes = {}
  -- Gather submitted hitboxes from actors
  table.foreach(_global.actors,
    function(_, a)
      local submit = a.hitbox(a.control.current, a.context) or {}
      table.foreach(submit,
        function(_, subbox)
          table.insert(boxes, subbox)
        end
      )
    end
  )
  -- Run collision detection and callbacks
  local collisiontable = coolision.collisiondetect(boxes, 1, 0)
  table.foreach(collisiontable,
    function(boxa, collisions)
      table.foreach(collisions,
        function(_, boxb)
          if boxa.hitcallback then boxa.hitcallback(boxb) end
          if boxb.hitcallback then boxb.hitcallback(boxa) end
        end
      )
    end
  )

  table.foreach(_global.actors,
    function(k, a)
      actor.update(a, framedata)
    end
  )

  local terminate = {}
  table.foreach(_global.actors, function(k, a)
    if a.control.current == "dead" then table.insert(terminate, k) end
  end)
  table.foreach(terminate, function(k, v)
    _global.actors[v] = nil
  end)
end

function love.draw()
  local s = 2
  love.graphics.scale(s)
  -- HACK, replace with actual love window dim API
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  -- end-of-HACK
  local ie = _global.actors.impa.context.entity
  local map = _global.map
  local mapwidth = map.width * map.tilewidth
  local mapheight = map.height * map.tileheight

  local x = math.min(map.x + mapwidth - w / s, math.max(-map.x, ie.x - 0.5 * w / s))
  local y = math.max(map.y - mapheight + h / s, math.min(map.y, ie.y + 0.5 * h / s))
  love.graphics.translate(-x, y)
  _global.map:draw()
  love.graphics.scale(1, -1)
  table.foreach(_global.actors,
    function(_, a)
      actor.draw(a)
    end
  )
end
