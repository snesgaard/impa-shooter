require "math"
local addtrail = require "evadetrail"
require "gunexhaust"
require "bullet"

loaders = loaders or {}
actor = actor or {}

-- Utilities
local loadimage = function(gamedata, path)
  gamedata.visual.images[path] = love.graphics.newImage(path)
end
local onground = function(gamedata, id, buffer)
  local g = gamedata.ground[id]
  local t = gamedata.system.time
  return g and t - g < buffer
end

-- Defines
local w = 4
local h = 12
local exhaustcoords = {x = 18, y = 1}

local groundbuffer = 0.1
local walkspeed = 75
local jumpspeed = 200
local evadeduration = 0.1
local evadedistance = 30
local evadespeed = evadedistance / evadeduration
local evadesampling = 0.025
local fireframetime = 0.05
local fireframes = 4

-- Controls
local jumpkey = " "
local firekey = "a"
local evadekey = "lshift"

local imagepath = {
  idle = "res/impa/idle.png",
  walk = "res/impa/walk.png",
  ascend = "res/impa/ascend.png",
  descend = "res/impa/descend.png",
  fire = "res/impa/gunfire.png",--"res/fire.png",
  arialfire = "res/impa/arialfire.png",
  evade = "res/impa/evade.png",
}

loaders.impa = function(gamedata)
  for _, impath in pairs(imagepath) do
    loadimage(gamedata, impath)
  end
end

local draw_coroutines_creator = {}
draw_coroutines_creator.normal = function(animations)
  local normal = {}
  normal.ground = function(gamedata, id)
    local anime
    local entity = gamedata.entity[id]
    local face = gamedata.face[id]
    if math.abs(entity.vx) > 0 then
      anime = animations.walk
    else
      anime = animations.idle
    end
    anime:update(gamedata.system.dt)
    misc.draw_sprite_entity(anime, entity, face)
    coroutine.yield()
    return normal.ground(gamedata, id)
  end
  normal.arial = function(gamedata, id)
    while gamedata.entity[id].vy > 0 do
      animations.ascend:update(gamedata.system.dt)
      misc.draw_sprite_entity(animations.ascend, gamedata.entity[id], gamedata.face[id])
      coroutine.yield()
    end
    -- Possible transition animation goes here
    while gamedata.entity[id].vy <= 0 do
      animations.descend:update(gamedata.system.dt)
      misc.draw_sprite_entity(animations.descend, gamedata.entity[id], gamedata.face[id])
      coroutine.yield()
    end
    return normal.arial(gamedata, id)
  end
  local co_ground = coroutine.create(normal.ground)
  local co_arial = coroutine.create(normal.arial)
  normal.runner = function(gamedata, id)
    local g = onground(gamedata, id, groundbuffer)
    if g then
      coroutine.resume(co_ground, gamedata, id)
    else
      coroutine.resume(co_arial, gamedata, id)
    end
    coroutine.yield()
    return normal.runner(gamedata, id)
  end
  return coroutine.create(normal.runner)
end
draw_coroutines_creator.fire = function(animations)
  return coroutine.create(function(gamedata, id)
    local g = onground(gamedata, id, groundbuffer)
    local anime
    if g then
      anime = animations.fire
    else
      anime = animations.arialfire
    end
    anime:setMode("once")
    anime:reset()
    anime:play()
    local swapanimation = function(olda, newa)
      newa:setMode("once")
      newa:play()
      newa:seek(olda:getCurrentFrame())
      newa.timer = olda.timer
      return newa
    end
    while true do
      g = onground(gamedata, id, groundbuffer)
      -- Transition to normal ground fire animation
      if g and anime == animations.arialfire then
        anime = swapanimation(animations.arialfire, animations.fire)
      elseif not g and anime == animations.fire then
        anime = swapanimation(animations.fire, animations.arialfire)
      end
      anime:update(gamedata.system.dt)
      misc.draw_sprite_entity(anime, gamedata.entity[id], gamedata.face[id])
      coroutine.yield()
    end
  end)
end
draw_coroutines_creator.evade = function(animations)
  local trail = {}
  local draw
  draw = function(gamedata, id, trail)
    local anime = animations.evade
    local timer = misc.createtimer(gamedata.system.time, evadesampling)
    table.insert(trail, addtrail(gamedata.entity[id], gamedata.face[id], gamedata.system.time, anime))
    while timer(gamedata.system.time) do
      anime:update(gamedata.system.dt)
      love.graphics.setColor(100, 50, 255)
      misc.draw_sprite_entity(anime, gamedata.entity[id], gamedata.face[id])
      love.graphics.setColor(255, 255, 255)
      coroutine.yield()
    end
    return draw(gamedata, id, trail)
  end
  local init = function(gamedata, id)
    gamedata.init(gamedata, actor.evadetrail, trail)
    return draw(gamedata, id, trail)
  end
  return coroutine.create(init)
end

-- States
local normal = {}
local fire = {}
local evade = {}
-- State definitions
normal.begin = function(gamedata, id, cache)
  gamedata.visual.drawers[id] = cache.draw_coroutines.normal
  return normal.run(gamedata, id, cache)
end
normal.run = function(gamedata, id, cache)
  local r = input.isdown(gamedata, "right")
  local l = input.isdown(gamedata, "left")
  local e = gamedata.entity[id]
  local s = input.ispressed(gamedata, jumpkey)
  local g = onground(gamedata, id, groundbuffer)
  local a = input.ispressed(gamedata, firekey)
  local ev = input.ispressed(gamedata, evadekey)
  -- Jumping controls
  if s and g then
    input.latch(gamedata, jumpkey)
    gamedata.ground[id] = nil
    e.vy = jumpspeed
  end
  -- Control movement and direction
  if r then
    gamedata.face[id] = "right"
    e.vx = walkspeed
  elseif l then
    gamedata.face[id] = "left"
    e.vx = -walkspeed
  else
    e.vx = 0
  end
  coroutine.yield()
  if ev then
    input.latch(gamedata, evadekey)
    return evade.begin(gamedata, id, cache)
  elseif a then
    input.latch(gamedata, firekey)
    return fire.begin(gamedata, id, cache)
  end
  return normal.run(gamedata, id, cache)
end

fire.begin = function(gamedata, id, cache)
  gamedata.visual.drawers[id] = draw_coroutines_creator.fire(cache.animations)
  -- Set face
  local r = input.isdown(gamedata, "right")
  local l = input.isdown(gamedata, "left")
  if r then
    gamedata.face[id] = "right"
  elseif l then
    gamedata.face[id] = "left"
  end
  local movecontrol = function(gamedata, id)
    local e = gamedata.entity[id]
    local r = input.isdown(gamedata, "right")
    local l = input.isdown(gamedata, "left")
    local g = onground(gamedata, id, groundbuffer)
    if not g and r then
      e.vx = walkspeed
    elseif not g and l then
      e.vx = -walkspeed
    else
      e.vx = 0
    end
  end
  local co = coroutine.create(function(gamedata, id)
    local pretimer = misc.createtimer(gamedata.system.time, fireframetime)
    while pretimer(gamedata.system.time) do
      movecontrol(gamedata, id)
      coroutine.yield()
    end
    -- Spawn bullet here
    local entity = gamedata.entity[id]
    local face = gamedata.face[id]
    local sx = 1
    if face == "left" then sx = -1 end
    gamedata.init(
      gamedata, actor.gunexhaust, entity.x + exhaustcoords.x * sx,
      entity.y + exhaustcoords.y, face
    )
    gamedata.init(
      gamedata, actor.bullet, entity.x + exhaustcoords.x * sx,
      entity.y + exhaustcoords.y, 250 * sx
    )
    local posttimer = misc.createtimer(gamedata.system.time, fireframetime * 3)
    while posttimer(gamedata.system.time) do
      movecontrol(gamedata, id)
      coroutine.yield()
    end
  end)
  return fire.run(gamedata, id, cache, co)
end
fire.run = function(gamedata, id, cache, co)
  coroutine.resume(co, gamedata, id)
  coroutine.yield()
  local ev = input.ispressed(gamedata, evadekey)
  if ev then
    input.latch(gamedata, evadekey)
    return evade.begin(gamedata, id, cache)
  elseif coroutine.status(co) == "dead" then
    local a = input.ispressed(gamedata, firekey)
    if a then
      input.latch(gamedata, firekey)
      return fire.begin(gamedata, id, cache)
    end
    return normal.begin(gamedata, id, cache)
  end
  return fire.run(gamedata, id, cache, co)
end

evade.begin = function(gamedata, id, cache)
  gamedata.visual.drawers[id] = draw_coroutines_creator.evade(cache.animations)
  local r = input.isdown(gamedata, "right")
  local l = input.isdown(gamedata, "left")
  if r then
    gamedata.face[id] = "right"
  elseif l then
    gamedata.face[id] = "left"
  end
  local e = gamedata.entity[id]
  if gamedata.face[id] == "right" then
    e.vx = evadespeed
  else
    e.vx = -evadespeed
  end
  return evade.run(gamedata, id, cache)
end
evade.run = function(gamedata, id, cache)
  local timer = misc.createtimer(gamedata.system.time, evadeduration)
  local e = gamedata.entity[id]
  while timer(gamedata.system.time) do
    e.vy = 0
    coroutine.yield()
  end
  return normal.begin(gamedata, id, cache)
end

local _recursive_control = function(gamedata, id)
  local ims = gamedata.visual.images
  local cache = {}
  cache.animations = {
    idle = newAnimation(ims[imagepath.idle], 48, 48, 0.2, 4),
    walk = newAnimation(ims[imagepath.walk], 48, 48, 0.15, 4),
    descend = newAnimation(ims[imagepath.descend], 48, 48, 0.15, 2),
    ascend = newAnimation(ims[imagepath.ascend], 48, 48, 0.15, 2),
    fire = newAnimation(ims[imagepath.fire], 48, 48, fireframetime, fireframes),
    arialfire = newAnimation(ims[imagepath.arialfire], 48, 48, fireframetime, fireframes),
    evade = newAnimation(ims[imagepath.evade], 48, 48, 0.15, 2)
  }
  cache.draw_coroutines = {
    normal = draw_coroutines_creator.normal(cache.animations),
    fire = draw_coroutines_creator.fire(cache.animations),
  }
  return normal.begin(gamedata, id, cache)
end

local control = _recursive_control
local type = "player"
actor.impa = function(gamedata, id, x, y)
  gamedata.actor[id] = "player"
  gamedata.entity[id] = newEntity(x, y, w, h)
  gamedata.entity[id].mapCollisionCallback = function(e, _, _, cx, cy)
    if cy and cy < e.y then
      gamedata.ground[id] = gamedata.system.time
    end
  end
  gamedata.control[id] = coroutine.create(control)
  gamedata.face[id] = "left"
  gamedata.visual.layer[id] = layer
  -- Init game related stats
  gamedata.maxhealth[id] = 4
  gamedata.maxstamina[id] = 2
end
