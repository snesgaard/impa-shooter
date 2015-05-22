require "util"
require "math"
require ("modules/AnAL")
require "actor"
local sti = require ("modules/sti")
require ("modules/tilephysics")
local misc = require ("modules/misc")
require ("modules/coolision")
require "box"

-- Utilities
function loadanimation(path, ...)
  local im = love.graphics.newImage(path)
  return newAnimation(im, ...)
end

function xor(a, b)
  a = a or false
  b = b or false
  return (a or b) and (not (a and b))
end

function getplayer(g)
  return g.actors.impa
end

local timerfreq = 4

function love.keypressed(key, isrepeat)
  framedata.keyboard[key] = love.timer.getTime()
  if key == "q" then timerfreq = timerfreq + 0.1 end
  if key == "e" then timerfreq = timerfreq - 0.1 end
end

function love.load()
  local filter = "nearest"
  love.graphics.setDefaultFilter(filter, filter, 0)
  framedata = {keyboard = {}}
  --Global init
  _global = {}
  _global.actors = {
    impa = require "impa",
    actioncharges = require "actioncharges",
    health = require "health",
    bullet = bullet,
  }
  for i = 1, 4 do
    table.insert(_global.actors, newBox(150 + i * 50, -100))
  end
  _global.map = sti.new("res/rainylevel")
  misc.setPosSTIMap(_global.map, 0, 0)
  -- Test for shader
  local shaderstr = love.filesystem.read("res/shaders/rain.glsl")
  shader = love.graphics.newShader(shaderstr)
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

  -- Collision detection
  -- Collect + group all seekers and hailers
  local hailers = {}
  local seekers = {}
  -- Utility for inserting a typed box into a subtable
  local inserttype = function(t, type, box)
    if not type then return end
    local sbt = t[type] or {}
    table.insert(sbt, box)
    t[type] = sbt
  end
  -- Iterate through all actors, allowing them to submit hitboxes for the update
  -- Hitboxes are divided into seekers and hailers
  table.foreach(_global.actors,
    function(_, a)
      local makehitbox = a.hitbox[a.control.current] or function() return {} end
      local submit = makehitbox(a.context)
      table.foreach(submit,
        function(_, v)
          table.foreach(v.seek,
            function(_, s)
              inserttype(seekers, s, v.box)
            end
          )
          table.foreach(v.hail,
            function(_, h)
              inserttype(hailers, h, v.box)
            end
          )
        end
      )
    end
  )
  -- Now go through all hailers
  table.foreach(hailers,
    function(type, subhailers)
      -- Find correspoding seekers (ala signal and slot)
      local subseekers = seekers[type] or {}
      -- Now do a grouped collision detection
      local collisiontable = coolision.groupedcd(subseekers, subhailers, 1, 0)
      -- Resolve the collisions
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
  love.graphics.setBackgroundColor(70, 70, 120, 255)
  love.graphics.setShader()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
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
  love.graphics.setShader(shader)
  shader:send("campos", {x, y})
  shader:send("scale", s)
  shader:send("fade", 0.1)
  shader:send("time", love.timer.getTime())
  --shader:send("time", 1)
  local dx = -1
  shader:send("direction", {dx, 1})
  shader:send("spatialfreq", 0.005)
  local ft = timerfreq
  shader:send("temporalfreq", ft)
  shader:send("normalfreq", 0.05)
  shader:send("spatialvar", 0.005)
  shader:send("spatialthreshold", 0.80)
  shader:send("normalthreshold", 0.95)
  love.graphics.origin()
  love.graphics.rectangle("fill", 0, 0, w, h)
  shader:send("normalfreq", 0.1)
  shader:send("fade", 0.075)
  shader:send("temporalfreq", ft + 1)
  love.graphics.rectangle("fill", 0, 0, w, h)
end
