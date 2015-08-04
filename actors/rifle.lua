actors = actors or {}
loaders = loaders or {}

local firetime = 0.6
local fireframes = 6
local fireframetime = firetime / fireframes
local reloadtime = 0.5
local reloadframes = 5
local reloadframettime = reloadtime / (reloadframes * 2)

local exhaustcoords = {x = 18, y = 1}

local images = {
  riflefire = "res/impa/riflefire.png",
  riflecomboreload = "res/impa/riflecomboreload.png",
}

loaders.rifle = function(gamedata)
  for _, path in pairs(images) do
    gamedata.visual.images[path] = love.graphics.newImage(path)
  end
end

local fire = {}
local reload = {}

fire.run = function(gamedata, id, masterid)
  local maxa = gamedata.weapons.maxammo[id]
  local useda = gamedata.weapons.usedammo[id] or 0
  if useda >= maxa then -- play botched fire animation / state here
    return
  end
  local anime = newAnimation(
    gamedata.visual.images[images.riflefire], 48, 48, fireframetime,
    fireframes
  )
  gamedata.visual.drawers[masterid] = misc.createoneshotdrawer(anime)
  local pretimer = misc.createtimer(gamedata.system.time, fireframetime)
  while pretimer(gamedata.system.time) do
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
  local posttimer = misc.createtimer(inittime, fireframetime * (fireframes - 1))
  local waittimer = misc.createtimer(inittime, fireframetime)
  while posttimer(gamedata.system.time) do
    local reloadkey = gamedata.keys.reload
    local firekey = gamedata.keys.fire
    local r = input.ispressed(gamedata, reloadkey)
    local a = input.ispressed(gamedata, firekey)
    local w = waittimer(gamedata.system.time)
    if not w then
      if a then
        input.latch(gamedata, firekey)
        return fire.run(gamedata, id, masterid)
      elseif r then
        input.latch(gamedata, reloadkey)
        return reload.combo(gamedata, id, masterid)

      end
    end
    coroutine.yield()
  end
end

reload.combo = function(gamedata, id, masterid)
  local usedammo = gamedata.weapons.usedammo[id] or 0
  if usedammo <= 1 then
    gamedata.weapons.usedammo[id] = nil
  else
    gamedata.weapons.usedammo[id] = usedammo - 1
  end
  local reloadtimer = misc.createtimer(gamedata.system.time, reloadtime)
  local im = gamedata.visual.images[images.riflecomboreload]
  local anime = newAnimation(
    im, 48, 48, reloadframettime, reloadframes
  )
  gamedata.visual.drawers[masterid] = misc.createbouncedrawer(anime)
  local nextrun
  while reloadtimer(gamedata.system.time) do
    local firekey = gamedata.keys.fire
    if input.ispressed(gamedata, firekey) then
      input.latch(gamedata, firekey)
      nextrun = fire.run
    end
    coroutine.yield()
  end
  if nextrun then return nextrun(gamedata, id, masterid) end
end
reload.normal = reload.combo -- Should be its own thing

actors.rifle = function(gamedata, id)
  gamedata.weapons.maxammo[id] = 3
  gamedata.weapons.fire[id] = fire.run
  gamedata.weapons.reload[id] = reload.normal
end
