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

local riflefiretime = 0.6
local riflefireframes = 6
local riflefireframetime = riflefiretime / riflefireframes
local riflereloadtime = 0.5
local riflereloadframes = 5
local riflereloadft = riflereloadtime / (riflereloadframes * 2)

-- Controls
local jumpkey = " "
local firekey = "a"
local reloadkey = "s"
local evadekey = "lshift"

local imagepath = {
  idle = "res/impa/idle.png",
  walk = "res/impa/walk.png",
  ascend = "res/impa/ascend.png",
  descend = "res/impa/descend.png",
  fire = "res/impa/gunfire.png",--"res/fire.png",
  arialfire = "res/impa/arialfire.png",
  evade = "res/impa/evade.png",
  riflefire = "res/impa/riflefire.png",
  riflecomboreload = "res/impa/riflecomboreload.png",
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
draw_coroutines_creator.fire = function(animeground, animearial)
  return coroutine.create(function(gamedata, id)
    local g = onground(gamedata, id, groundbuffer)
    local resetanimation = function(anime)
      anime:setMode("once")
      anime:reset()
      anime:play()
    end
    resetanimation(animeground)
    resetanimation(animearial)
    local anime
    if g then
      anime = animeground
    else
      anime = animearial
    end

    local swapanimation = function(olda, newa)
      newa:seek(olda:getCurrentFrame())
      newa.timer = olda.timer
      return newa
    end
    while true do
      g = onground(gamedata, id, groundbuffer)
      -- Transition to normal ground fire animation
      if g and anime == animearial and not anime == animeground then
        anime = swapanimation(animearial, animeground)
      elseif not g and anime == animeground and not anime == animearial then
        anime = swapanimation(animeground, animearial)
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
local riflereload = {}
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

fire.movecontrol = function(gamedata, id)
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

riflereload.begin = function(gamedata, id, cache)
  local missammo = gamedata.game.missingammunition.rifle or 0
  if missammo <= 1 then
    gamedata.game.missingammunition.rifle = nil
  else
    gamedata.game.missingammunition.rifle = missammo - 1
  end
  local reloadtimer = misc.createtimer(gamedata.system.time, riflereloadtime)
  gamedata.visual.drawers[id] = misc.createbouncedrawer(cache.animations.riflecomboreload)
  local nextrun
  while reloadtimer(gamedata.system.time) do
    if input.ispressed(gamedata, firekey) then
      input.latch(gamedata, firekey)
      nextrun = fire.begin
    end
    fire.movecontrol(gamedata, id)
    coroutine.yield()
  end
  if nextrun then return nextrun(gamedata, id, cache) end
end

fire.gun = function(gamedata, id)
  local movecontrol = fire.movecontrol
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
end
fire.rifle = function(gamedata, id, cache)
  local movecontrol = fire.movecontrol
  local pretimer = misc.createtimer(gamedata.system.time, riflefireframetime)
  local missammo = gamedata.game.missingammunition.rifle or 0
  gamedata.game.missingammunition.rifle = missammo + 1
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
  local inittime = gamedata.system.time
  local posttimer = misc.createtimer(inittime, riflefireframetime * 5)
  local actiontimer = misc.createtimer(inittime, riflefireframetime)
  local botched = false
  while posttimer(gamedata.system.time) do
    fire.movecontrol(gamedata, id)
    local r = input.ispressed(gamedata, reloadkey)
    if r and not botched then
      input.latch(gamedata, reloadkey)
      if not actiontimer(gamedata.system.time) then
        return riflereload.begin(gamedata, id, cache)
      else
        botched = true
      end
    end
    local a = input.ispressed(gamedata, firekey)
    if a and not actiontimer(gamedata.system.time) then
      return fire.begin(gamedata, id, cache)
    end
    coroutine.yield()
  end
  --[[
  local reloadtimer = misc.createtimer(gamedata.system.time, riflereloadtime)
  gamedata.visual.drawers[id] = misc.createbouncedrawer(cache.animations.riflecomboreload)
  while reloadtimer(gamedata.system.time) do
    coroutine.yield()
  end
  --]]
end
fire.begin = function(gamedata, id, cache)
  local createentry = function(pressed, ground, arial, co)
    return {pressed = pressed, ground = ground, arial = arial, co = co}
  end
  local anime = cache.animations
  local firestates = {
    createentry(
      gamedata.system.pressed["1"] or 1, anime.fire, anime.arialfire,
      fire.gun
    ),
    createentry(
      gamedata.system.pressed["2"] or 0, anime.riflefire, anime.riflefire,
      fire.rifle
    )
  }
  table.sort(firestates, function(v1, v2) return v1.pressed < v2.pressed end)
  local firestate = firestates[#firestates]
  local animeground = firestate.ground
  local animearial = firestate.arial
  gamedata.visual.drawers[id] = draw_coroutines_creator.fire(
    animeground, animearial
  )
  -- Set face
  local r = input.isdown(gamedata, "right")
  local l = input.isdown(gamedata, "left")
  if r then
    gamedata.face[id] = "right"
  elseif l then
    gamedata.face[id] = "left"
  end

  if firestate.co == fire.rifle then
    local amiss = gamedata.game.missingammunition.rifle or 0
    local amax = gamedata.game.maxammunition.rifle
    if amax <= amiss then return normal.begin(gamedata, id, cache) end
  end
  local co = coroutine.create(firestate.co)
  return fire.run(gamedata, id, cache, co)
end
fire.run = function(gamedata, id, cache, co)
  coroutine.resume(co, gamedata, id, cache)
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
    evade = newAnimation(ims[imagepath.evade], 48, 48, 0.15, 2),
    riflefire = newAnimation(ims[imagepath.riflefire], 48, 48, riflefireframetime, riflefireframes),
    riflecomboreload = newAnimation(ims[imagepath.riflecomboreload], 48, 48, riflereloadft, riflereloadframes),
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
  gamedata.game.maxammunition.rifle = 3
end
