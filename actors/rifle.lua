actors = actors or {}
loaders = loaders or {}

local firetime = 0.6
local fireframes = 6
local fireframetime = firetime / fireframes
local reloadtime = 0.5
local reloadframes = 5
local reloadframettime = reloadtime / (reloadframes * 2)

images = {
  riflefire = "res/impa/riflefire.png",
  riflecomboreload = "res/impa/riflecomboreload.png",
}

loaders.rifle = function(gamedata)
  for _, path in pairs(images) do
    gamedata.visual.images[path] = path
  end
end

local fire = {}
local reload = {}

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
fire.run = function(gamedata, id, masterid)
  local maxa = gamedata.maxammo[id]
  local useda = gamedata.usedammo[id] or 0
  if useda >= maxa then -- play botched fire animation / state here
    return
  end
  local anime = newAnimation(
    gamedata.visual.images[images.riflefire], 48, 48, fireframetime, fireframes
  )
  gamedata.visual.drawers[masterid] = misc.createoneshotdrawer(anime)
  local pretimer = misc.createtimer(gamedata.system.time, riflefireframetime)
  while pretimer(gamedata.system.time) do
    movecontrol(gamedata, id)
    coroutine.yield()
  end
  -- Spawn bullet here
  gamedata.weapons.usedammo[id] = useda + 1
  local entity = gamedata.entity[masterid]
  local face = gamedata.face[masterid]
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
  local posttimer = misc.createtimer(inittime, riflefireframetime * (fireframes - 1))
  while posttimer(gamedata.system.time) do
    gamedata.keys.reload = reloadkey
    fire.movecontrol(gamedata, id)
    local r = input.ispressed(gamedata, reloadkey)
    if r then
      return reload.combo(gamedata, id, masterid)
    end
    coroutine.yield()
  end
end

reload.combo = function(gamedata, id, masterid)
  local usedammo = gamedata.weapons.usedammo[id] or 0
  if missammo <= 1 then
    gamedata.weapons.usedammo[id] = nil
  else
    gamedata.weapons.usedammo[id] = usedammo - 1
  end
  local reloadtimer = misc.createtimer(gamedata.system.time, reloadtime)
  local anime = newAnimation(
    gamedata.visual.images[images.riflecomboreload], 48, 48, reloadframes,
    reloadframettime
  )
  gamedata.visual.drawers[id] = misc.createbouncedrawer(anime)
  local nextrun
  while reloadtimer(gamedata.system.time) do
    local firekey = gamedata.keys.fire
    if input.ispressed(gamedata, firekey) then
      input.latch(gamedata, firekey)
      nextrun = fire.begin
    end
    fire.movecontrol(gamedata, id)
    coroutine.yield()
  end
  if nextrun then return nextrun(gamedata, id, cache) end
end
reload.normal = reload.combo -- Should be its own thing

actors.rifle = function(gamedata, id)
  gamedata.weapons.maxammo[id] = 3
  gamedata.weapons.fire[id] = fire.run
  gamedata.weapons.reload[id] = reload.normal
end
