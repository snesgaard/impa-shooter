local gfx = love.graphics

actor = actor or {}
loaders = loaders or {}

-- defines
local w = 2.5
local h = 1
local lifetime = 4
local impacttime = 0.1
local impactframes = 3
local impactframetime = impacttime / impactframes


local imagepaths = {
  body = "res/bullet.png",
  dudimpact = "res/bulletimpact.png",
  minorimpact = "res/minorbulletimpact.png",
  majorimpact = "res/majorbulletimpact.png",
}

local particles

loaders.bullet = function(gamedata)
  local ims = gamedata.visual.images
  for _, path in pairs(imagepaths) do
    gamedata.visual.images[path] = love.graphics.newImage(path)
  end
end

local cleanup = function(gamedata, id)
  gamedata.visual.drawers[id] = nil
  gamedata.control[id] = nil
  gamedata.ground[id] = nil
  gamedata.entity[id] = nil
  gamedata.hitbox[id] = nil
end

local visual = {}

visual.alive = function(animations)
  local co
  co = function(gamedata, id)
    local anime = animations.body
    local entity = gamedata.entity[id]
    local face = gamedata.face[id]
    local color = {190, 28, 164}
    --gfx.setColor(unpack(color))
    misc.draw_sprite_entity(anime, entity, face)
    --[[
    local btrail = gamedata.visual.particles.btrail
    btrail:setPosition(entity.x + 5, entity.y)
    btrail:update(gamedata.system.dt)
    local r, g, b = unpack(color)
    btrail:setColors(r, g, b, 150)
    gfx.draw(btrail)
    --]]
    gfx.setColor(255, 255, 255)
    coroutine.yield()
    anime:update(gamedata.system.dt)
    local dmg = gamedata.bullet.damagedealt[id]
    if dmg then
      local impco
      if dmg > 1 then
        impco = visual.majorimpact(animations)
      elseif dmg == 1 then
        impco = visual.minorimpact(animations)
      else
        impco = visual.dudimpact(animations)
      end
      return impco(gamedata, id)
    else
      return co(gamedata, id)
    end
  end
  return co
end

visual.dudimpact = function(animations)
  local co
  co = function(gamedata, id)
    local anime = animations.dudimpact
    local entity = gamedata.entity[id]
    local face = gamedata.face[id]
    misc.draw_sprite_entity(anime, entity, face)
    coroutine.yield()
    anime:update(gamedata.system.dt)
    return co(gamedata, id)
  end
  return co
end

visual.minorimpact = function(animations)
  local co
  co = function(gamedata, id)
    local anime = animations.minorimpact
    local entity = gamedata.entity[id]
    local face = gamedata.face[id]
    misc.draw_sprite_entity(anime, entity, face)
    coroutine.yield()
    anime:update(gamedata.system.dt)
    return co(gamedata, id)
  end
  return co
end

visual.majorimpact = function(animations)
  local co
  co = function(gamedata, id)
    local anime = animations.majorimpact
    local entity = gamedata.entity[id]
    local face = gamedata.face[id]
    misc.draw_sprite_entity(anime, entity, face)
    coroutine.yield()
    anime:update(gamedata.system.dt)
    return co(gamedata, id)
  end
  return co
end

local alive = function(gamedata, id)
  local e = gamedata.entity[id]
  local b = gamedata.hitbox[id].body
  local timer = misc.createtimer(gamedata.system.time, lifetime)
  while
    timer(gamedata.system.time)
    and not gamedata.bullet.damagedealt[id]
  do
    e.vy = 0
    b.x = e.x - w
    coroutine.yield()
  end
  gamedata.hitbox[id] = {}
  local deadtimer = misc.createtimer(gamedata.system.time, impacttime)
  while deadtimer(gamedata.system.time) do
    e.vx = 0
    e.vy = 0
    coroutine.yield()
  end
  gamedata.cleanup[id] = cleanup
  coroutine.yield()
end

local type = "bullet"
actor.bullet = function(gamedata, id, x, y, speed, seek, dmg)
  dmg = dmg or 1
  gamedata.actor[id] = type
  local e = newEntity(x, y, w, h)
  e.vx = speed
  e.mapCollisionCallback = function(e, _, _, cx, cy)
    if cx or cy then
      gamedata.bullet.damagedealt[id] = 0
      --gamedata.ground[id] = gamedata.system.time
    end
  end
  gamedata.entity[id] = e

  if speed > 0 then gamedata.face[id] = "right" else gamedata.face[id] = "left" end

  gamedata.control[id] = coroutine.create(alive)

  local body = coolision.newAxisBox(
    id, x - w, y + h, w * 2, h * 2, gamedata.hitboxtypes.allyprojectile,
    gamedata.hitboxtypes.enemybody
  )
  gamedata.hitbox[id] = {
    body = body
  }
  -- Init bullet stats
  gamedata.bullet.lifetime[id] = lifetime
  gamedata.bullet.damagedealt[id] = nil
  -- Visualizer init
  local ims = gamedata.visual.images
  local animations = {
    body = newAnimation(ims[imagepaths.body], 5, 3, 0.05, 0),
    dudimpact = newAnimation(ims[imagepaths.dudimpact], 15, 9, impactframetime, impactframes),
    minorimpact = newAnimation(ims[imagepaths.minorimpact], 15, 9, impactframetime, impactframes),
    majorimpact = newAnimation(ims[imagepaths.majorimpact], 15, 18, impactframetime, impactframes),
  }
  local callback = function(this, other)
    if other.applydamage ~= nil then
      local x = this.x + this.w * 0.5
      local y = this.y - this.h * 0.5 
      gamedata.bullet.damagedealt[id] = other.applydamage(
        this.id, x, y, dmg
      )
    end
  end
  coolision.setcallback(body, callback)
  gamedata.visual.drawers[id] = coroutine.create(visual.alive(animations))
end
