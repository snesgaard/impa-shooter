actor = actor or {}
loaders = loaders or {}

local ims = {
  hit = "res/mobolee/hit.png",
  idle = "res/mobolee/idle.png",
  prehit = "res/mobolee/prehit.png",
  walk = "res/mobolee/walk.png",
  boom = "res/majorbulletimpact.png"
}

local w = 6
local h = 12

local walkspeed = 25
local prehittime = 0.4
local hittime = 0.2
local hitframes = 4
local hitframetime = hittime / hitframes
local dyingtime = 2.0

local psearch = {
  w = 300, h = 200
}
local followthreshold = 2
local phit = {
  w = 30, h = 30
}

loaders.mobolee = function(gamedata)
  for _, path in pairs(ims) do
    gamedata.visual.images[path] = gamedata.visual.images[path] or loadspriteimage(path)
  end
end

local createidledrawer = function(gamedata)
  local im = gamedata.visual.images[ims.idle]
  return misc.createrepeatdrawer(
    newAnimation(im, 48, 48, 0.4, 2)
  )
end
local createwalkdrawer = function(gamedata)
  local im = gamedata.visual.images[ims.walk]
  return misc.createrepeatdrawer(
    newAnimation(im, 48, 48, 0.2, 0)
  )
end
local createprehitdrawer = function(gamedata)
  local im = gamedata.visual.images[ims.prehit]
  local frames = 4
  local frametime = prehittime / frames
  return misc.createoneshotdrawer(
    newAnimation(im, 48, 48, frametime, frames)
  )
end
local createhitdrawer = function(gamedata)
  local im = gamedata.visual.images[ims.hit]
  return misc.createoneshotdrawer(
    newAnimation(im, 48, 48, hitframetime, hitframes)
  )
end

-- Control states
local idle = {}
local hit = {}
local follow = {}
local control = {}
local dead = {}

idle.begin = function(gamedata, id)
  gamedata.visual.drawers[id] = createidledrawer(gamedata)
  local entity = gamedata.entity[id]
  entity.vx = 0
  return idle.run(gamedata, id)
end

idle.run = function(gamedata, id)
  coroutine.yield()
  local t = gamedata.target[id]
  local h = gamedata.message[id].hit
  if h then
    if hit.ready(gamedata, id) then return hit.run(gamedata, id) end
    gamedata.message[id].hit = nil
  end
  if t and not h then return follow.begin(gamedata, id) end
  return idle.run(gamedata, id)
end

follow.begin = function(gamedata, id)
  gamedata.visual.drawers[id] = createwalkdrawer(gamedata)
  return follow.run(gamedata, id)
end

follow.run = function(gamedata, id)
  local h = gamedata.message[id].hit
  if h then
    if hit.ready(gamedata, id) then return hit.run(gamedata, id) end
    gamedata.message[id].hit = nil
    return idle.begin(gamedata, id)
  end
  local t = gamedata.target[id]
  if not t then return idle.begin(gamedata, id) end
  gamedata.target[id] = nil
  local entity = gamedata.entity[id]
  local s = t.x - entity.x
  if s < 0 then
    gamedata.face[id] = "left"
    entity.vx = -walkspeed
  else
    gamedata.face[id] = "right"
    entity.vx = walkspeed
  end
  coroutine.yield()
  return follow.run(gamedata, id)
end

hit.ready = function(gamedata, id)
  local ustam = gamedata.usedstamina[id] or 0
  local mstam = gamedata.stamina[id]
  return math.ceil(ustam) < mstam
end

hit.run = function(gamedata, id)
  local entity = gamedata.entity[id]
  entity.vx = 0
  local h = gamedata.message[id].hit
  if h.x - entity.x > 0 then
    gamedata.face[id] = "right"
  else
    gamedata.face[id] = "left"
  end
  gamedata.visual.drawers[id] = createprehitdrawer(gamedata)
  local prehittimer = misc.createtimer(gamedata.system.time, prehittime)
  while prehittimer(gamedata.system.time) do
    coroutine.yield()
  end
  gamedata.visual.drawers[id] = createhitdrawer(gamedata)
  local passivetimer = misc.createtimer(
    gamedata.system.time, hitframetime * 2
  )
  while passivetimer(gamedata.system.time) do
    coroutine.yield()
  end
  local dmgfunc = combat.singledamagecall(
    function(this, other)
      if other.applydamage then other.applydamage(this.id, 0, 0, 1) end
      return this, other
    end
  )
  gamedata.hitbox[id].hit = coolision.newAxisBox(
    id, 0, 0, 14, 24, nil, gamedata.hitboxtypes.allybody,
    dmgfunc
  )
  gamedata.hitboxsync[id].hit = {x = 2, y = 14}
  local activetimer = misc.createtimer(
    gamedata.system.time, hitframetime * 2
  )
  while activetimer(gamedata.system.time) do
    coroutine.yield()
  end
  gamedata.hitbox[id].hit = nil
  gamedata.hitboxsync[id].hit = nil
  gamedata.message[id].hit = nil
  gamedata.usedstamina[id] = (gamedata.usedstamina[id] or 0) + 1
  return idle.begin(gamedata, id)
end

dead.run = function(gamedata, id)
  -- Remove hitbox system
  gamedata.hitbox[id] = nil
  gamedata.hitboxsync[id] = nil
  local timer = misc.createtimer(gamedata.system.time, dyingtime)
  gamedata.visual.drawers[id] = dead.drawer(gamedata, id)
  while timer(gamedata.system.time) do
    gamedata.entity[id].vx = 0
    gamedata.entity[id].vy = 0
    coroutine.yield()
  end
  gamedata.cleanup[id] = function(gamedata, id)
    gamedata.control[id] = nil
    gamedata.visual.drawers[id] = nil
    gamedata.entity[id] = nil
  end
end
dead.drawer = function(gamedata, id)
  local anime = newAnimation( -- Place holer
    gamedata.visual.images[ims.idle], 48, 48, 0.1, 2
  )
  local animeco = misc.createrepeatdrawer(anime)
  local explodetime = 0.5
  local f
  f = function(gamedata, id, nextexplode, explosions)
    nextexplode = nextexplode - gamedata.system.dt
    -- If time create the next explostion
    if nextexplode < 0 then
      nextexplode = explodetime
      local e = gamedata.entity[id]
      -- Sample explosion position
      local x = love.math.random(e.x - e.wx, e.x + e.wx)
      local y = love.math.random(e.y - e.wy, e.y + e.wy)
      -- Create explosion sprite
      local exw = 15
      local exh = 18
      local exanime = newAnimation(
        gamedata.visual.images[ims.boom], exw, exh, 0.075, 6
      )
      -- Now declare coroutine which will draw the explosion
      local f
      f = function(gamedata)
        misc.drawsprite(exanime, x, y, "right")
        coroutine.yield()
        exanime:update(gamedata.system.dt)
        if exanime.playing then return f(gamedata) end
      end
      table.insert(explosions, coroutine.create(f))
    end
    coroutine.resume(animeco, gamedata, id)
    -- Now iterate through all explosion coroutines
    -- Discard whatever has finished
    for k, exco in ipairs(explosions) do
      if coroutine.status(exco) ~= "dead" then
        coroutine.resume(exco, gamedata)
      else
        explosions[k] = nil
      end
    end
    coroutine.yield()
    return f(gamedata, id, nextexplode, explosions)
  end
  local init = function(gamedata, id)
    return f(gamedata, id, 0, {})
  end
  return coroutine.create(init)
end
control.begin = function(gamedata, id)
  local co = coroutine.create(idle.begin)
  return control.run(gamedata, id, co)
end
control.run = function(gamedata, id, co)
  coroutine.resume(co, gamedata, id)
  coroutine.yield()
  local d = gamedata.damage[id] or 0
  local h = gamedata.health[id]
  if d < h then
    return control.run(gamedata, id, co)
  else
    return dead.run(gamedata, id)
  end
end
local init = function(gamedata)
  return control.begin
end

actor.mobolee = function(gamedata, id, x, y)
  gamedata.actor[id] = "mobolee"
  gamedata.entity[id] = newEntity(x, y, w, h)
  gamedata.face[id] = "right"
  gamedata.control[id] = coroutine.create(init(gamedata))
  gamedata.message[id] = {}
  gamedata.stamina[id] = 1
  gamedata.hitbox[id] = {
    playersearch = coolision.newAxisBox(
      id, x - psearch.w, y + psearch.h, psearch.w,
      psearch.h, nil, gamedata.hitboxtypes.allybody,
      function(this, other)
        gamedata.target[id] = {
          x = other.x + other.w * 0.5, y = other.y - other.h * 0.5
        }
      end
    ),
    playerhit = coolision.newAxisBox(
      id, x, y, phit.w, phit.h, nil, gamedata.hitboxtypes.allybody,
      function(this, other)
        gamedata.message[id].hit = {
          x = other.x + other.w * 0.5, y = other.y - other.h * 0.5
        }
      end
    ),
    body = coolision.newAxisBox(
      id, x, y, w * 2, h * 2, gamedata.hitboxtypes.enemybody
    )
  }
  gamedata.soak[id] = 0
  gamedata.reduce[id] = 1
  gamedata.invincibility[id] = false
  gamedata.health[id] = 8
  gamedata.hitbox[id].body.applydamage = function(otherid, x, y, damage)
    local s = gamedata.soak[id]
    local r = gamedata.reduce[id]
    local i = gamedata.invincibility[id]
    local d = combat.calculatedamage(damage, s, r, i)
    local e = gamedata.entity[id]
    gamedata.init(gamedata, actor.damagenumber, x, y + 20, d, 0.5)
    gamedata.damage[id] = (gamedata.damage[id] or 0) + d
    return d
  end
  gamedata.hitboxsync[id] = {
    playersearch = {x = -psearch.w * 0.5, y = psearch.h * 0.5},
    playerhit = {x = -phit.w * 0.5, y = phit.h * 0.5},
    body = {x = -w, y = h},
  }
end
