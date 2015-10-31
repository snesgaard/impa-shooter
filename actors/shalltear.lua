actor = actor or {}
loaders = loaders or {}

local imroot = "res/shalltear"
local function impather(name)
  return imroot .. "/" .. name
end

local ims = {
  beastidle = impather("Beastmode.png"),
  clawa = impather("clawa1.png"),
  clawarec = impather("clawa_recov.png"),
  clawb = impather("clawb.png"),
  clawbrec = impather("clawb_recov.png"),
  clawc = impather("clawc.png"),
  clawcrec = impather("clawc_recov.png"),
  move = impather("idle.png"), --Placeholder sprite
  idle = impather("idle.png"),
  run = impather("run3.png"),
  beastrun = impather("beastrun.png"),
  eparticle = impather("evadeparticle.png"),
  evade = impather("evade.png"),
  descend = impather("arialdescend.png"),
  ascend = impather("ascend.png"),
  midair = impather("midair.png"),
  beastdescend = impather("beastdescend.png"),
  beastmidair = impather("beastmidair.png"),
  beastascend = impather("beastascend.png"),
  dead = impather("dead.png")
}

local w = 6
local h = 16
local runspeed = 100
local keys = {
  attack = "f",
  dash = "lshift",
  jump = " ",
  left = "left",
  right = "right",
}
local jumpspeed = 200
local midairtime = 0.1

loaders.shalltear = function(gamedata)
  for _, path in pairs(ims) do
    gamedata.resource.images[path] = loadspriteimage(path)
  end
end

local function isbeast(gamedata, id)
  local bstart = gamedata.message[id].beast
  local duration = 3.0
  if not bstart then
    return false
  else
    return gamedata.system.time - bstart < duration
  end
end

local function turn(gamedata, id)
  local l = input.isdown(gamedata, keys.left)
  local r = input.isdown(gamedata, keys.right)
  if l and not r then
    gamedata.actor.face[id] = -1
  elseif not l and r then
    gamedata.actor.face[id] = 1
  end
end

local control = {}
local normal = {}
local dead = {}
local evade = {}
local clawa = {}
local clawb = {}
local clawc = {}

function normal.begin(gamedata, id)
  -- Set drawing coroutine
  gamedata.actor.draw[id] = control.createdrawer(coroutine.create(normal.draw))
  return normal.run(gamedata, id)
end

function normal.run(gamedata, id)
  local sx = (
    (input.isdown(gamedata, keys.right) and 1 or 0)
    + (input.isdown(gamedata, keys.left) and -1 or 0)
  )
  gamedata.actor.vx[id] = sx * runspeed
  if sx ~= 0 then gamedata.actor.face[id] = sx end
  if input.ispressed(gamedata, keys.jump) and game.onground(gamedata, id) then
    input.latch(gamedata, keys.jump)
    gamedata.actor.ground[id] = nil
    gamedata.actor.vy[id] = jumpspeed
  end
  return normal.run(coroutine.yield())
end

function normal.draw(gamedata, id)
  local function creategroundco(idleid, runid)
    local run
    local begin = function(gamedata, id)
      idleco = misc.createdrawer(idleid)
      runco = misc.createdrawer(runid)
      return run(idleco, runco, gamedata, id)
    end
    run = function(idleco, runco, gamedata, id)
      if math.abs(gamedata.actor.vx[id]) > 1 then
        coroutine.resume(runco, gamedata, id)
      else
        coroutine.resume(idleco, gamedata, id)
      end
      return run(idleco, runco, coroutine.yield())
    end
    return coroutine.create(begin)
  end
  local function createairco(ascend, mid, descend)
    return coroutine.create(function(gamedata, id)
      local aco = misc.createdrawer(ascend)
      local dco = misc.createdrawer(descend)
      while true do
        while gamedata.actor.vy[id] > 0 do
          coroutine.resume(aco, gamedata, id)
          coroutine.yield()
        end
        local timer = misc.createtimer(gamedata, midairtime)
        local mco = misc.createdrawer(mid, "once")
        while timer(gamedata) and gamedata.actor.vy[id] <= 0 do
          coroutine.resume(mco, gamedata, id)
          coroutine.yield()
        end
        while gamedata.actor.vy[id] <= 0 do
          coroutine.resume(dco, gamedata, id)
          coroutine.yield()
        end
      end
    end)
  end
  local anime = gamedata.actor.claimed[id].animations
  local calmground = creategroundco(anime.idle, anime.run)
  local calmair = createairco(anime.ascend, anime.midair, anime.descend)
  local beastground
  local beastair
  while true do
    if game.onground(gamedata, id) then
      coroutine.resume(calmground, gamedata, id)
    else
      coroutine.resume(calmair, gamedata, id)
    end
    coroutine.yield()
  end
end

local evadetime = 0.1
local evadedist = 40
function evade.run(gamedata, id)
  local anime = gamedata.actor.claimed[id].animations
  gamedata.actor.draw[id] = control.createdrawer(
    misc.createdrawer(anime.evade)
  )
  turn(gamedata, id)
  local f = gamedata.actor.face[id]
  gamedata.actor.vx[id] = f * evadedist / evadetime
  local timer = misc.createtimer(gamedata, evadetime)
  while timer(gamedata) do
    gamedata.actor.vy[id] = 0
    coroutine.yield()
  end
  return normal.begin(gamedata, id)
end

function control.begin(gamedata, id)
  local co = coroutine.create(normal.begin)
  return control.run(co, gamedata, id)
end

function control.run(co, gamedata, id)
  if input.ispressed(gamedata, keys.dash) then
    input.latch(gamedata, keys.dash)
    co = coroutine.create(evade.run)
  end
  coroutine.resume(co, gamedata, id)
  return control.run(co, coroutine.yield())
end

function control.createdrawer(co)
  --local co = coroutine.create(f)
  local draw
  draw = function(gamedata, id)
    -- TODO: Draw global effects such as dash trail
    coroutine.resume(co, gamedata, id)
    return draw(coroutine.yield())
  end
  return coroutine.create(draw)
end

function actor.shalltear(gamedata, id, x, y)
  -- Allocate table resources
  -- Setup debug rendering info
  local resim = gamedata.resource.images
  local claimed = gamedata.actor.claimed
  claimed[id] = {
    animations = {
      idle = initanimation(gamedata, resim[ims.idle], 48, 48, 0.3, 4),
      run = initanimation(gamedata, resim[ims.run], 48, 48, 0.1, 8),
      descend = initanimation(gamedata, resim[ims.descend], 48, 48, 0.1, 2),
      ascend = initanimation(gamedata, resim[ims.ascend], 48, 48, 0.1, 2),
      midair = initanimation(gamedata, resim[ims.midair], 48, 48, 0.05, 2),
      evade = initanimation(gamedata, resim[ims.evade], 48, 48, 1, 1),
    },
    evadeparticle = initresource(
      gamedata.particles, gfx.newParticleSystem, resim[ims.evade], 20
    )
  }
  -- Setup spatial info
  local act = gamedata.actor
  gamedata.actor.x[id] = x
  gamedata.actor.y[id] = y
  gamedata.actor.width[id] = w
  gamedata.actor.height[id] = h
  gamedata.actor.vx[id] = 0
  gamedata.actor.vy[id] = 0
  gamedata.actor.face[id] = 1
  --gamedata.actor.draw[id] = misc.createdrawer(
  --  claimed[id].animations.idle
  --)
  --gamedata.actor.draw[id] = coroutine.create(normal.draw)
  gamedata.actor.control[id] = coroutine.create(control.begin)
  --[[
  gamedata.control[id] = coroutine.create(control.begin)
  gamedata.entity[id] = newEntity(x, y, w, h)
  gamedata.entity[id].mapCollisionCallback = function(e, _, _, cx, cy)
    if cy and cy < e.y then
      gamedata.ground[id] = gamedata.system.time
    end
  end
  gamedata.actor[id] = "player"
  gamedata.face[id] = "right"
  gamedata.message[id] = {}
  gamedata.hitbox[id] = {
    body = coolision.newAxisBox(
      id, x - w, y + h, w * 2, h * 2, gamedata.hitboxtypes.allybody
    )
  }
  gamedata.hitbox[id].body.applydamage = function(otherid, x, y, dmg)
    return combat.dodamage(gamedata, id, dmg)
  end
  gamedata.hitboxsync[id] = {
    body = {x = -w, y = h}
  }
  gamedata.health[id] = 8
  gamedata.reduce[id] = 1
  gamedata.soak[id] = 0
  gamedata.invincibility[id] = 0
  ]]--
end
