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
  w = 600, h = 200
}
local followthreshold = 2
local phit = {
  w = 30, h = 60
}

loaders.mobolee = function(gamedata)
  for _, path in pairs(ims) do
    gamedata.resource.images[path] = gamedata.resource.images[path] or loadspriteimage(path)
  end
end

local createidledrawer = function(gamedata)
  local im = gamedata.resource.images[ims.idle]
  return misc.createrepeatdrawer(
    newAnimation(im, 48, 48, 0.4, 2)
  )
end
local createwalkdrawer = function(gamedata)
  local im = gamedata.resource.images[ims.walk]
  return misc.createrepeatdrawer(
    newAnimation(im, 48, 48, 0.2, 0)
  )
end
local createprehitdrawer = function(gamedata)
  local im = gamedata.resource.images[ims.prehit]
  local frames = 4
  local frametime = prehittime / frames
  return misc.createoneshotdrawer(
    newAnimation(im, 48, 48, frametime, frames)
  )
end
local createhitdrawer = function(gamedata)
  local im = gamedata.resource.images[ims.hit]
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
  local rb = gamedata.message[id].rblocked
  local lb = gamedata.message[id].lblocked
  gamedata.message[id].rblocked = nil
  gamedata.message[id].lblocked = nil
  if h then
    if hit.ready(gamedata, id) then return hit.run(gamedata, id) end
    gamedata.message[id].hit = nil
  end
  local e = gamedata.entity[id]
  if t and (t.x > e.x and not rb or t.x < e.x and not lb) then
    return follow.begin(gamedata, id)
  end
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
    --return idle.begin(gamedata, id)
  end
  local t = gamedata.target[id]
  local rb = gamedata.message[id].rblocked
  local lb = gamedata.message[id].lblocked
  gamedata.message[id].rblocked = nil
  gamedata.message[id].lblocked = nil
  local e = gamedata.entity[id]
  if not t or (t.x > e.x and rb) or (t.x < e.x and lb) then
    return idle.begin(gamedata, id)
  end
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
  -- Optional fun mode
  if moboleemaster and gamedata.moboleemaster > -1 then
    moboleemaster.rip(gamedata, gamedata.moboleemaster, id)
  end
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
    gamedata.entity2entity[id] = nil
    gamedata.entity2terrain[id] = nil
  end
end
dead.drawer = function(gamedata, id)
  local anime = newAnimation( -- Place holer
    gamedata.resource.images[ims.idle], 48, 48, 0.1, 2
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
        gamedata.resource.images[ims.boom], exw, exh, 0.075, 6
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
  gamedata.entity2entity[id] = 1
  gamedata.entity2terrain[id] = id
  gamedata.face[id] = "right"
  gamedata.control[id] = coroutine.create(init(gamedata))
  gamedata.message[id] = {}
  gamedata.stamina[id] = 1
  local targettype = gamedata.hitboxtypes.allybody
  gamedata.hitbox[id] = {
    playersearch = coolision.newAxisBox(
      id, x - psearch.w, y + psearch.h, psearch.w,
      psearch.h, nil, targettype,
      function(this, other)
        local px = other.x + other.w * 0.5
        if math.abs(px - this.x - this.w * 0.5) > 10 then
          gamedata.target[id] = {
            x = other.x + other.w * 0.5, y = other.y - other.h * 0.5
          }
        end
      end
    ),
    playerhit = coolision.newAxisBox(
      id, x, y, phit.w, phit.h, nil, targettype,
      function(this, other)
        gamedata.message[id].hit = {
          x = other.x + other.w * 0.5, y = other.y - other.h * 0.5
        }
      end
    ),
    antibunch = coolision.newAxisBox(
      id, x, y, 8, 16, nil, gamedata.hitboxtypes.enemybody,
      function(this, other)
        local tx = this.x + this.w * 0.5
        local ox = other.x + other.w * 0.5
        local d = math.abs(tx - ox)
        if d > 1 then
          if tx < ox and this.id ~= other.id then
            gamedata.message[id].rblocked = true
          elseif tx > ox and this.id ~= other.id then
            gamedata.message[id].lblocked = true
          end
        elseif this.id < other.id then
          gamedata.message[id].rblocked = true
          gamedata.message[id].lblocked = true
        end
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
  gamedata.damage[id] = 0
  gamedata.hitbox[id].body.applydamage = function(otherid, x, y, damage)
    local e = gamedata.entity[id]
    local f = gamedata.face[id] == "right" and 1 or -1
    --local s = (x - e.x) * f > 0 and 1 or 0
    local d = combat.dodamage(gamedata, id, damage)
    return d
  end
  gamedata.hitboxsync[id] = {
    playersearch = {x = -psearch.w * 0.5, y = psearch.h * 0.5},
    playerhit = {x = -phit.w * 0.5, y = phit.h * 0.5},
    antibunch = {x = -4, y = 8},
    body = {x = -w, y = h},
  }
end
