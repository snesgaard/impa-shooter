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
}

local w = 6
local h = 16
local runspeed = 100
local evadekey = "lshift"
local jumpspeed = 200

loaders.shalltear = function(gamedata)
  for _, path in pairs(ims) do
    gamedata.visual.images[path] = loadspriteimage(path)
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

local control = {}
local normal = {}
local evade = {}
local clawa = {}
local clawb = {}

local arialanimation = {}
arialanimation.midairtime = 0.1
function arialanimation.ascend(gamedata, id, ascend, descend, midair)
  coroutine.resume(ascend, gamedata, id)
  if gamedata.entity[id].vy > 0 then
    return arialanimation.ascend(coroutine.yield())
  else
    return arialanimation.mid(coroutine.yield())
  end
end
function arialanimation.mid(gamedata, id, ascend, descend, midair, timer)
  timer = timer or misc.createtimer(gamedata.system.time, arialanimation.midairtime)
  coroutine.resume(midair, gamedata, id)
  if timer(gamedata.system.time) then
    coroutine.yield()
    return arialanimation.mid(gamedata, id, ascend, descend, midair, timer)
  else
    return arialanimation.descend(coroutine.yield())
  end
end
function arialanimation.descend(gamedata, id, ascend, descend, midair)
  coroutine.resume(descend, gamedata, id)
  if gamedata.entity[id].vy > 0 then
    return arialanimation.ascend(coroutine.yield())
  else
    return arialanimation.descend(coroutine.yield())
  end
end
local function groundanimation(gamedata, id, idle, run)
  if math.abs(gamedata.entity[id].vx) < 1 then
    coroutine.resume(idle, gamedata, id)
  else
    coroutine.resume(run, gamedata, id)
  end
  return groundanimation(coroutine.yield())
end
function normal.drawer(gamedata, id)
  local normalidleco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.idle], 48, 48, 0.3, 4)
  )
  local normaldescendco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.descend], 48, 48, 0.1, 2)
  )
  local normalascendco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.ascend], 48, 48, 0.1, 2)
  )
  local makenormalmidco = function()
    return misc.createoneshotdrawer(
      newAnimation(
        gamedata.visual.images[ims.midair], 48, 48,
        arialanimation.midairtime / 2, 2
      )
    )
  end
  local beastdescendco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.beastdescend], 48, 48, 0.1, 2)
  )
  local beastascendco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.beastascend], 48, 48, 0.1, 2)
  )
  local makebeastmidco = function()
    return misc.createoneshotdrawer(
      newAnimation(
        gamedata.visual.images[ims.beastmidair], 48, 48,
        arialanimation.midairtime / 2, 2
      )
    )
  end
  local beastidleco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.beastidle], 48, 48, 0.2, 3)
  )
  local normalrunco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.run], 48, 48, 1.0/10.0, 8)
  )
  local beastrunco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.beastrun], 48, 48, 1.0/10.0, 8)
  )
  local groundco = coroutine.create(groundanimation)
  while true do
    while game.onground(gamedata, id) do
      if isbeast(gamedata, id) then
        coroutine.resume(groundco, gamedata, id, beastidleco, beastrunco)
      else
        coroutine.resume(groundco, gamedata, id, normalidleco, normalrunco)
      end
      coroutine.yield()
    end
    local arialco = coroutine.create(arialanimation.ascend)
    local midco = makenormalmidco()
    local bmidco = makebeastmidco()
    while not game.onground(gamedata, id) do
      if isbeast(gamedata, id) then
        coroutine.resume(
          arialco, gamedata, id, beastascendco, beastdescendco, bmidco
        )
      else
        coroutine.resume(
          arialco, gamedata, id, normalascendco, normaldescendco, midco
        )
      end
      coroutine.yield()
    end
  end
end
function normal.begin(gamedata, id)
  control.drawer.main = coroutine.create(normal.drawer)
  return normal.run(gamedata, id)
end
function normal.run(gamedata, id)
  if input.ispressed(gamedata, evadekey) then
    input.latch(gamedata, evadekey)
    return evade.run(gamedata, id)
  end
  local e = gamedata.entity[id]
  if input.isdown(gamedata, "right") then
    gamedata.face[id] = "right"
    e.vx = runspeed
  elseif input.isdown(gamedata, "left") then
    gamedata.face[id] = "left"
    e.vx = -runspeed
  else
    e.vx = 0
  end
  if input.ispressed(gamedata, " ") and game.onground(gamedata, id) then
    input.latch(gamedata, " ")
    gamedata.ground[id] = nil
    e.vy = jumpspeed
  end
  coroutine.yield()
  if input.ispressed(gamedata, "f") then
    input.latch(gamedata, "f")
    return clawa.run(gamedata, id)
  end
  return normal.run(gamedata, id)
end

evade.time = 0.1
evade.dist = 40
function evade.drawer(gamedata, id, vx)
  local speed = 20
  local lifetime = 0.1
  local spray = love.graphics.newParticleSystem(
    gamedata.visual.images[ims.evade], 100
  )
  local sx = gamedata.face[id] == "right" and 1 or -1
  local vx = -sx * gamedata.entity[id].vx
  spray:setSpeed(vx)
  spray:setEmissionRate(30)
  spray:setSizes(1.0)
  spray:setAreaSpread("normal", 0, 0)
  spray:setInsertMode("random")
  spray:setSizeVariation(0)
  spray:setParticleLifetime(lifetime, lifetime)
  spray:setDirection(0)
  spray:setLinearAcceleration(0, 0, 0, 0)
  spray:setColors(255, 50, 50, 200, 255, 50, 100, 100)
  local timer = misc.createtimer(gamedata.system.time, evade.time)
  local entity = gamedata.entity[id]
  local o = -5 * sx
  while timer(gamedata.system.time) do
    spray:update(gamedata.system.dt)
    love.graphics.draw(spray, entity.x + o, entity.y, 0, sx, -1)
    coroutine.yield()
  end
  spray:setEmissionRate(0)
  local x = entity.x + o
  local y = entity.y
  while spray:getCount() > 0 do
    spray:update(gamedata.system.dt)
    love.graphics.draw(spray, x, y, 0, sx, -1)
    coroutine.yield()
  end
  control.drawer.evade = nil
end
function evade.run(gamedata, id)
  -- Determine evade direction
  local dx = (
    (input.ispressed(gamedata, "left") and -1 or 0)
    + (input.ispressed(gamedata, "right") and 1 or 0)
  )
  if dx == 1 then
    gamedata.face[id] = "right"
  elseif dx == -1 then
    gamedata.face[id] = "left"
  end
  -- If no input provided
  if dx == 0 then
    dx = gamedata.face[id] == "right" and 1 or -1
  end
  -- Set speeds
  local vx = dx * evade.dist / evade.time
  local vy = 0
  gamedata.entity2entity[id] = nil
  control.drawer.main = misc.createrepeatdrawer(newAnimation(
    gamedata.visual.images[ims.evade], 48, 48, 100, 1
  ))
  control.drawer.evade = coroutine.create(evade.drawer)
  local timer = misc.createtimer(gamedata.system.time, evade.time)
  while timer(gamedata.system.time) do
    gamedata.entity[id].vx = vx
    gamedata.entity[id].vy = vy
    coroutine.yield()
  end
  gamedata.entity[id].vx = 0
  gamedata.entity[id].vy = 0
  gamedata.entity2entity[id] = id
  gamedata.message[id].beast = gamedata.system.time
  return normal.begin(gamedata, id)
end

-- Combat utility
local function combatcancel(gamedata, id)
  return (
    (input.ispressed(gamedata, " ") and game.onground(gamedata, id))
    or input.ispressed(gamedata, evadekey)
  )
end

-- Slash time
clawa.time = 0.2
clawa.frames = 4
clawa.recovtime = 0.3
clawa.recovframes = 7
function clawa.run(gamedata, id)
  local ft = clawa.time / clawa.frames
  control.drawer.main = misc.createoneshotdrawer(
    newAnimation(
      gamedata.visual.images[ims.clawa], 48, 48, ft, clawa.frames
    )
  )
  gamedata.entity[id].vx = 0
  combat.activeboxsequence(
    gamedata, id, "hit", 2, 0, 11, 23, 15, ft * 2, ft * 3, clawa.time
  )
  control.drawer.main = misc.createoneshotdrawer(
    newAnimation(
      gamedata.visual.images[ims.clawarec], 48, 48,
      clawa.recovtime / clawa.recovframes, clawa.recovframes
    )
  )
  local recovtimer = misc.createtimer(gamedata.system.time, clawa.recovtime)
  while recovtimer(gamedata.system.time) do

    if combatcancel(gamedata, id) then
      break
    elseif input.ispressed(gamedata, "f") then
      input.latch(gamedata, "f")
      return clawb.run(gamedata, id)
    end
    coroutine.yield()
  end
  gamedata.message[id].beast = gamedata.system.time
  return normal.begin(gamedata, id)
end

clawb.time = 0.2
clawb.frames = 4
clawb.dist = 10
clawb.recovtime = 0.3
clawb.recovframes = 3
function clawb.run(gamedata, id)
  local ft = clawb.time / clawb.frames
  control.drawer.main = misc.createoneshotdrawer(
    newAnimation(
      gamedata.visual.images[ims.clawb], 48, 48, ft, clawb.frames
    )
  )
  local s = gamedata.face[id] == "right" and 1 or -1
  gamedata.entity[id].vx = s * clawb.dist / clawb.time
  combat.activeboxsequence(
    gamedata, id, "hit", 2, -3, 11, 27, 17, ft * 2, ft * 3, clawb.time
  )
  gamedata.entity[id].vx = 0

  control.drawer.main = misc.createoneshotdrawer(
    newAnimation(
      gamedata.visual.images[ims.clawbrec], 48, 48,
      clawb.recovtime / clawb.recovframes, clawb.recovframes
    )
  )

  local recovtimer = misc.createtimer(gamedata.system.time, clawb.recovtime)
  while recovtimer(gamedata.system.time) do

    if combatcancel(gamedata, id) then
      break
    elseif input.ispressed(gamedata, "f") then
      input.latch(gamedata, "f")
      return clawa.run(gamedata, id)
    end
    coroutine.yield()
  end
  gamedata.message[id].beast = gamedata.system.time
  return normal.begin(gamedata, id)
end

control.drawer = {}
control.drawer.main = nil
control.drawer.evade = nil
function control.drawer.co(gamedata, id)
  local d = control.drawer
  if d.evade then coroutine.resume(d.evade, gamedata, id) end
  if d.main then coroutine.resume(d.main, gamedata, id) end
  coroutine.yield()
  return control.drawer.co(gamedata, id)
end
function control.begin(gamedata, id)
  local co = coroutine.create(normal.begin)
  gamedata.visual.drawers[id] = coroutine.create(control.drawer.co)
  return control.run(gamedata, id, co)
end
function control.run(gamedata, id, co)
  --if input.ispressed(gamedata, evadekey) then
  --  input.latch(gamedata, evadekey)
  --  co = coroutine.create(evade.run)
  --end
  coroutine.resume(co, gamedata, id)
  coroutine.yield()
  return control.run(gamedata, id, co)
end

function actor.shalltear(gamedata, id, x, y)
  gamedata.control[id] = coroutine.create(control.begin)
  gamedata.entity[id] = newEntity(x, y, w, h)
  gamedata.entity[id].mapCollisionCallback = function(e, _, _, cx, cy)
    if cy and cy < e.y then
      gamedata.ground[id] = gamedata.system.time
    end
  end
  gamedata.entity2entity[id] = id
  gamedata.entity2terrain[id] = id
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
  -- gamedata.health[id] = 8
  gamedata.health[id] = 8
  gamedata.reduce[id] = 1
  gamedata.soak[id] = 0
  gamedata.invincibility[id] = false
end
