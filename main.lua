require "util"
require "math"
require ("modules/AnAL")
require "actor"
local sti = require ("modules/sti")
require ("modules/tilephysics")
local misc = require ("modules/misc")
require ("modules/coolision")
require "box"
require "mobolee"
require "impa"
require "health"
require ("modules/functional")
require "combat"
require "globaldata"

-- Utilities
function loadanimation(path, ...)
  local im = love.graphics.newImage(path)
  return newAnimation(im, ...)
end
function drawbox(x, y, w, h, r, g, b)
  r = r or 255
  g = g or 255
  b = b or 255
  love.graphics.setColor(r, g, b, 255)
  love.graphics.rectangle("line", x, y, w, h)
  love.graphics.setColor(r, g, b, 100)
  love.graphics.rectangle("fill", x, y, w, h)
  love.graphics.setColor(255, 255, 255, 255)
end

function xor(a, b)
  a = a or false
  b = b or false
  return (a or b) and (not (a and b))
end

function getplayer(g)
  return g.actors.impa
end

function love.keypressed(key, isrepeat)
  framedata.keyboard[key] = love.timer.getTime()
  if key == "escape" then love.event.quit() end
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

function table.copyto(dst, src)
  for k, v in ipairs(src) do
    dst[k] = v
  end
end

-- Defines
local renderhitbox = false

function love.load()
  local filter = "nearest"
  love.graphics.setDefaultFilter(filter, filter, 0)
  framedata = {keyboard = {}}
  --Global init
  _global = {}
  _global.actors = {
    actioncharges = require "actioncharges",
    impa = newimpa(global, "impa", 100, -100),
    health = newhealthbar(global, "healthbar", "impa"),--require "health",
    mobolee = newMobolee(global, "mobo", 200, -100),
  }
  _global.data = {}

  _global.map = sti.new("res/rainylevel")
  misc.setPosSTIMap(_global.map, 0, 0)
  -- Test for shader
  local shaderstr = love.filesystem.read("res/shaders/rain.glsl")
  shader = love.graphics.newShader(shaderstr)

end


function love.update(dt)
  renderboxes = {}

  framedata.dt = dt
  framedata.time = love.timer.getTime()
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
    function(id, a)
      local makehitbox = a.hitbox[a.control.current] or function() return {} end
      local submit = makehitbox(a.context) or {}
      table.foreach(submit,
        function(_, v)
          -- First add a global id tag to the hitbox
          -- This can be used for identifying the box in each iteration
          v.box.globalid = function() return id end
          -- Proceed to sort hitboxes by seeker and hailer type
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
          if renderhitbox then
            table.insert(renderboxes, v)
          end
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
              if boxa.hitcallback then boxa.hitcallback(boxb, boxa) end
              if boxb.hitcallback then boxb.hitcallback(boxa, boxb) end
            end
          )
        end
      )
    end
  )
  table.foreach(_global.actors,
    function(k, a)
      local f = table.shallowcopy(framedata)
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
  -- HACK
  --love.event.quit()
  --print(_global.actors.bullet.context.entity.x)
end

function love.draw()
  local s = 2
  love.graphics.scale(s)
  love.graphics.setBackgroundColor(70, 70, 120, 255)
  love.graphics.setShader()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  local ie = {x = 0, y = 0}
  if _global.actors.impa then ie = _global.actors.impa.context.entity end
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
  local findtable = function(h, ...)
    local args = {...}
    for _, v in pairs(args) do
      args[v] = true
    end
    for k, v in pairs(h) do
      if args[v] then
        return true
      end
    end
    return false
  end
  table.foreach(renderboxes,
    function(_, v)
      local b = v.box
      if findtable(v.hail, actor.types.allybody, actor.types.enemybody) then
        drawbox(b.x, b.y, b.w, -b.h)
      elseif findtable(v.hail, actor.types.allyprojectile, actor.types.enemyprojectile, actor.types.enemymelee) then
        drawbox(b.x, b.y, b.w, -b.h, 255, 0, 0)
      elseif findtable(v.seek, actor.types.allybody) then
        drawbox(b.x, b.y, b.w, -b.h, 0, 0, 255)
      end
    end
  )

  love.graphics.origin()
  love.graphics.setShader(shader)
  local dir = {1, 1}
  local l = math.sqrt(dir[1] * dir[1] + dir[2] * dir[2])
  dir[1] = dir[1] / l
  dir[2] = dir[2] / l
  shader:send("campos", {x, y})
  shader:send("scale", s)
  shader:send("fade", 0.1)
  shader:send("time", love.timer.getTime())
  shader:send("direction", dir)
  shader:send("spatialfreq", 0.005)
  local ft = 3
  shader:send("temporalfreq", ft)
  shader:send("normalfreq", 0.05)
  shader:send("spatialvar", 0.005)
  shader:send("spatialthreshold", 0.75)
  shader:send("normalthreshold", 0.95)
  love.graphics.rectangle("fill", 0, 0, w, h)
  shader:send("normalfreq", 0.1)
  shader:send("fade", 0.075)
  shader:send("temporalfreq", ft * 1.5)
  love.graphics.rectangle("fill", 0, 0, w, h)

  shader:send("normalfreq", 0.2)
  shader:send("fade", 0.05)
  shader:send("temporalfreq", ft * 2)
  love.graphics.rectangle("fill", 0, 0, w, h)
end
