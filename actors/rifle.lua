require "bullet"
require "math"

actors = actors or {}
loaders = loaders or {}

local firetime = 0.6
local fireframes = 6
local fireframetime = firetime / fireframes
local reloadtime = 0.5
local reloadframes = 5
local reloadframettime = reloadtime / (reloadframes * 2)

--UI defines
local bulletscale = 0.001
local bulletframe = {
  w = 50,
  h = 19,
}
local uipos = {x = 24, y = 104}

--
local multiplertime = 1.0
local multiplermax = 3
local multicolor = {
  [0] = {0, 0, 0, 0},
  [1] = {212, 81, 66},
  [2] = {203, 233, 39},
  [3] = {190, 28, 164},
}

local exhaustcoords = {x = 18, y = 1}

local images = {
  riflefire = "res/impa/riflefire.png",
  riflecomboreload = "res/impa/riflecomboreload.png",
  riflebullet = "res/impa/riflebulletui.png",
  btrailim = "res/btrailparticle.png",
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
  local multiplier = gamedata.rifle.multilevel[id] or 0
  local dmg = math.pow(2, multiplier)
  gamedata.init(
    gamedata, actor.gunexhaust, entity.x + exhaustcoords.x * sx,
    entity.y + exhaustcoords.y, face
  )
  gamedata.init(
    gamedata, actor.riflebullet, entity.x + exhaustcoords.x * sx,
    entity.y + exhaustcoords.y, multiplier, face
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
  gamedata.rifle.multitimer[id] = multiplertime
  local multi = gamedata.rifle.multilevel[id] or 0
  gamedata.rifle.multilevel[id] = math.min(multi + 1, multiplermax)
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

local make_uidraw = function(x, y)
  local uidraw = function(gamedata, id)
    while true do
      local riflebullet = newAnimation(
        gamedata.visual.images[images.riflebullet], bulletframe.w, bulletframe.h,
        0, 1
      )
      local maxa = gamedata.weapons.maxammo[id]
      local missa = gamedata.weapons.usedammo[id] or 0
      local renderammo =  maxa - missa
      local offset = 16 * 1.5
      -- Render ammo background
      local bgoff = 8
      local ammoheight = offset * 2 + bulletframe.h + bgoff
      local ammowidth = bulletframe.w + bgoff
      love.graphics.setColor(0, 0, 50, 100)
      love.graphics.rectangle(
        "fill", x - bgoff * 0.5, y - bgoff * 0.5, ammowidth, ammoheight
      )
      -- render actual bullets
      love.graphics.setColor(255, 255, 255)
      for ammo = 1, renderammo do
        riflebullet:draw(
          x, y + offset * (maxa - ammo), 0,
          1, 1
        )
      end
      -- Render multiplier
      local radius = 16
      local timeleft = gamedata.rifle.multitimer[id] or 0
      local multi = gamedata.rifle.multilevel[id] or 0
      local cur_color = multicolor[multi]
      local next_color = multicolor[multi - 1] or {0, 0, 0}
      local multipos = {
        x = x + ammowidth * 0.25, y = y + ammoheight * 1.1 + radius
      }
      -- Draw mulitpler background and timer
      timeleft = timeleft / multiplertime
      local arcstart = math.pi * 1.5
      local arcend = -math.pi * 0.5
      love.graphics.setColor(unpack(cur_color))
      love.graphics.arc(
        "fill", multipos.x, multipos.y,
        radius + 4, arcstart, arcend * timeleft + arcstart * (1 - timeleft),
        100
      )
      if multi > 0 then
        love.graphics.setColor(unpack(next_color))
        love.graphics.arc(
          "fill", multipos.x, multipos.y,
          radius + 4, arcend * timeleft + arcstart * (1 - timeleft) + math.pi * 2, arcstart,
          100
        )
      end
      love.graphics.setColor(0, 0, 50, 255)
      love.graphics.circle(
        "fill", multipos.x, multipos.y, radius, 100
      )
      if multi == 0 then
        love.graphics.setColor(255, 255, 255)
      else
        love.graphics.setColor(unpack(cur_color))
      end
      love.graphics.print(
        multi, multipos.x - ammowidth * 0.125 - 1, multipos.y - 13, 0, 2
      )
      coroutine.yield()
    end
  end
  return uidraw
end

actors.rifle = function(gamedata, id)
  gamedata.weapons.maxammo[id] = 3
  gamedata.weapons.fire[id] = fire.run
  gamedata.weapons.reload[id] = reload.normal
  gamedata.visual.uidrawers[id] = coroutine.create(make_uidraw(uipos.x, uipos.y))
end

local riflebullet_draw = function(basedraw, particles)
  local co = function(gamedata, id)
    while true do
      coroutine.resume(basedraw, gamedata, id)
      if particles then
        local entity = gamedata.entity[id]
        local o = 5
        if entity.vx < 0 then o = -o end
        particles:setPosition(entity.x + o, entity.y)
        particles:update(gamedata.system.dt)
        love.graphics.draw(particles)
      end
      coroutine.yield()
    end
  end
  return co
end

actor.riflebullet = function(gamedata, id, x, y, multi, face)
  local dmg = math.pow(2, multi)
  local speed = 250
  if face == "left" then speed = -speed end
  local color = multicolor[multi]
  actor.bullet(gamedata, id, x, y, speed, gamedata.hitboxtypes.enemybody, dmg)
  local basecontrol = gamedata.control[id]
  local basedraw = gamedata.visual.drawers[id]
  local speed = 0
  local lifetime = 0.1
  local ims = gamedata.visual.images
  local particles
  if multi > 0 then
    particles = love.graphics.newParticleSystem(ims[images.btrailim], 100)
    particles:setSpeed(speed, 3 * speed)
    particles:setEmissionRate(30)
    particles:setSizes(3.0, 5.0, 0)
    particles:setAreaSpread("normal", 0, 1)
    particles:setInsertMode("random")
    particles:setSizeVariation(1)
    particles:setParticleLifetime(lifetime)
    particles:setDirection(math.pi / 2)
    particles:setLinearAcceleration(0, 0, 0, 0)
    local r, g, b = unpack(color)
    particles:setColors(r, g, b, 150)
  end
  gamedata.visual.drawers[id] = coroutine.create(riflebullet_draw(basedraw, particles))
end

rifle = {}
rifle.updatemultipliers = function(gamedata, id)
  for id, multiplier in pairs(gamedata.rifle.multilevel) do
    local timer = gamedata.rifle.multitimer[id] or 0
    timer = timer - gamedata.system.dt
    if timer < 0 then

      if multiplier < 2 then
        gamedata.rifle.multilevel[id] = nil
        timer = 0
      else
        gamedata.rifle.multilevel[id] = multiplier - 1
        timer = multiplertime
      end
    end
    gamedata.rifle.multitimer[id] = timer
  end
end
