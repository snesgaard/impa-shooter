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
}

local w = 10
local h = 16
local runspeed = 100

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
local clawa = {}
local clawb = {}

function normal.drawer(gamedata, id)
  local normalidleco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.idle], 48, 48, 0.3, 4)
  )
  local beastidleco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.beastidle], 48, 48, 0.2, 3)
  )
  local normalrunco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.run], 48, 48, 1.0/10.0, 8)
  )
  local beastrunco = misc.createrepeatdrawer(
    newAnimation(gamedata.visual.images[ims.beastrun], 48, 48, 1.0/10.0, 8)
  )
  while true do
    local entity = gamedata.entity[id]
    if isbeast(gamedata, id) then
      local vx = entity.vx
      if math.abs(vx) < 1 then
        coroutine.resume(beastidleco, gamedata, id)
      else
        coroutine.resume(beastrunco, gamedata, id)
      end
    else
      local vx = entity.vx
      if math.abs(vx) < 1 then
        coroutine.resume(normalidleco, gamedata, id)
      else
        coroutine.resume(normalrunco, gamedata, id)
      end
    end
    coroutine.yield()
  end
end
function normal.begin(gamedata, id)
  gamedata.visual.drawers[id] = coroutine.create(normal.drawer)
  return normal.run(gamedata, id)
end
function normal.run(gamedata, id)
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
  coroutine.yield()
  if input.ispressed(gamedata, "f") then
    input.latch(gamedata, "f")
    return clawa.run(gamedata, id)
  end
  return normal.run(gamedata, id)
end
-- Slash time
clawa.time = 0.2
clawa.frames = 4
clawa.recovtime = 0.3
clawa.recovframes = 7
function clawa.run(gamedata, id)
  gamedata.visual.drawers[id] = misc.createoneshotdrawer(
    newAnimation(
      gamedata.visual.images[ims.clawa], 48, 48, clawa.time / clawa.frames,
      clawa.frames
    )
  )
  gamedata.entity[id].vx = 0
  local timer = misc.createtimer(gamedata.system.time, clawa.time)
  while timer(gamedata.system.time) do coroutine.yield() end

  gamedata.visual.drawers[id] = misc.createoneshotdrawer(
    newAnimation(
      gamedata.visual.images[ims.clawarec], 48, 48,
      clawa.recovtime / clawa.recovframes, clawa.recovframes
    )
  )
  local recovtimer = misc.createtimer(gamedata.system.time, clawa.recovtime)
  while recovtimer(gamedata.system.time) do
    if input.ispressed(gamedata, "f") then
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
  gamedata.visual.drawers[id] = misc.createoneshotdrawer(
    newAnimation(
      gamedata.visual.images[ims.clawb], 48, 48, clawb.time / clawb.frames,
      clawb.frames
    )
  )
  local s = gamedata.face[id] == "right" and 1 or -1
  gamedata.entity[id].vx = s * clawb.dist / clawb.time
  local timer = misc.createtimer(gamedata.system.time, clawb.time)
  while timer(gamedata.system.time) do coroutine.yield() end
  gamedata.entity[id].vx = 0

  gamedata.visual.drawers[id] = misc.createoneshotdrawer(
    newAnimation(
      gamedata.visual.images[ims.clawbrec], 48, 48,
      clawb.recovtime / clawb.recovframes, clawb.recovframes
    )
  )

  local recovtimer = misc.createtimer(gamedata.system.time, clawb.recovtime)
  while recovtimer(gamedata.system.time) do
    if input.ispressed(gamedata, "f") then
      input.latch(gamedata, "f")
      return clawa.run(gamedata, id)
    end
    coroutine.yield()
  end
  gamedata.message[id].beast = gamedata.system.time
  return normal.begin(gamedata, id)
end

function control.begin(gamedata, id)
  local co = coroutine.create(normal.begin)
  return control.run(gamedata, id, co)
end
function control.run(gamedata, id, co)
  coroutine.resume(co, gamedata, id)
  coroutine.yield()
  return control.run(gamedata, id, co)
end

function actor.shalltear(gamedata, id, x, y)
  gamedata.control[id] = coroutine.create(control.begin)
  gamedata.entity[id] = newEntity(x, y, w, h)
  gamedata.face[id] = "right"
  gamedata.message[id] = {}
end
