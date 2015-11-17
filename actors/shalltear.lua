local fun = require ("modules/functional")

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

-- Attack defines

loaders.shalltear = function(gamedata)
  for _, path in pairs(ims) do
    gamedata.resource.images[path] = loadspriteimage(path)
  end
end

local function isbeast(gamedata, beast)
  local bstart = beast
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
local airevade = {}
local clawa = {}
local clawb = {}
local clawc = {}

function normal.begin(gamedata, id, beast)
  local beast = beast or -1000
  -- Set drawing coroutine
  gamedata.actor.draw[id] = control.createdrawer(coroutine.create(
    function(gamedata, id) return normal.draw(gamedata, id, beast) end
  ))
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
  if input.ispressed(gamedata, keys.attack) then
    input.latch(gamedata, keys.attack)
    return clawa.abegin(coroutine.yield())
  end
  return normal.run(coroutine.yield())
end

function normal.draw(gamedata, id, beast)
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
  local beastground = creategroundco(anime.beastidle, anime.beastrun)
  local beastair = createairco(
    anime.beastascend, anime.beastmidair, anime.beastdescend
  )
  while true do
    if game.onground(gamedata, id) then
      if isbeast(gamedata, beast) then
        coroutine.resume(beastground, gamedata, id)
      else
        coroutine.resume(calmground, gamedata, id)
      end
    else
      if isbeast(gamedata, beast) then
        coroutine.resume(beastair, gamedata, id)
      else
        coroutine.resume(calmair, gamedata, id)
      end
    end
    coroutine.yield()
  end
end

local evadetime = 0.2
local evadedist = 40
function evade.run(gamedata, id)
  local anime = gamedata.actor.claimed[id].animations
  gamedata.actor.draw[id] = control.createdrawer(
    misc.createdrawer(anime.evade)
  )
  turn(gamedata, id)
  local f = gamedata.actor.face[id]
  local vx = f * evadedist / evadetime
  gamedata.actor.vx[id] = vx

  local sid = gamedata.actor.claimed[id].evadeparticle
  local spray = gamedata.particles.system[sid]
  spray:setSizes(f)
  spray:reset()
  spray:start()
  spray:setRotation(0.5 * (f + 1) * math.pi)
  spray:setDirection(0.5 * (f - 1) * math.pi)
  --spray:setSpeed(vx)
  local timer = misc.createtimer(gamedata, evadetime)
  spray:setPosition(0, 0)
  gamedata.actor.invincibility[id] = gamedata.actor.invincibility[id] + 1
  while timer(gamedata) do
    gamedata.actor.vy[id] = 0
    local x = spray:getPosition()
    gamedata.particles.x[id] = gamedata.actor.x[id]
    gamedata.particles.y[id] = gamedata.actor.y[id]
    spray:setPosition(-f * gamedata.actor.x[id], 0)
    coroutine.yield()
  end
  gamedata.actor.invincibility[id] = gamedata.actor.invincibility[id] - 1
  spray:stop()
  return normal.begin(gamedata, id, gamedata.system.time)
end

local evadespeed = 40
function airevade.begin(gamedata, id)
  local anime = gamedata.actor.claimed[id].animations
  gamedata.actor.draw[id] = control.createdrawer(
    misc.createdrawer(anime.beastdescend)
  )
  turn(gamedata, id)
  local f = gamedata.actor.face[id]
  local sid = gamedata.actor.claimed[id].airevadeparticle
  local spray = gamedata.particles.system[sid]
  spray:setSizes(f)
  spray:reset()
  spray:start()
  spray:setRotation(0.5 * (f + 1) * math.pi)
  spray:setDirection(0.5 * (f - 1) * math.pi)
  return airevade.run(sid, gamedata, id)
end
function airevade.run(sid, gamedata, id)
  local act = gamedata.actor
  act.vx[id] = 0
  act.vy[id] = -evadedist / evadetime
  gamedata.particles.x[sid] = act.x[id]
  gamedata.particles.y[sid] = act.y[id]
  local spray = gamedata.particles.system[sid]
  spray:setPosition(0, act.y[id])
  if game.onground(gamedata, id) then
    spray:stop()
    return evade.run(gamedata, id)
  else
    return airevade.run(sid, coroutine.yield())
  end
end

clawa.aframes = 4
clawa.atime = 0.2
clawa.rtime = 0.2
clawa.aframetime = clawa.atime / clawa.aframes
function clawa.abegin(gamedata, id)
  gamedata.actor.draw[id] = control.createdrawer(misc.createdrawer(
    gamedata.actor.claimed[id].animations.clawa, "once"
  ))
  turn(gamedata, id)
  local timer = misc.createtimer(gamedata, clawa.atime)
  local boxtimer = misc.createinterval(
    gamedata, clawa.aframetime * 2, clawa.aframetime
  )
  local dmgfunc = combat.createoneshotdamage(id, 2)
  return clawa.arun(timer, boxtimer, dmgfunc, gamedata, id)
end

function clawa.arun(timer, boxtimer, dmgfunc, gamedata, id)
  gamedata.actor.vx[id] = 0
  local bid = gamedata.actor.claimed[id].hitbox.clawa
  if boxtimer(gamedata) then
    local coolision = coroutine.yield({bid})
    local bcool = coolision[bid]
    for _, otherid in ipairs(bcool) do
      dmgfunc(gamedata, otherid)
    end
  end
  if timer(gamedata) then
    return clawa.arun(timer, boxtimer, dmgfunc, coroutine.yield())
  else
    return clawa.rbegin(coroutine.yield())
  end
end

function clawa.rbegin(gamedata, id)
  gamedata.actor.draw[id] = control.createdrawer(misc.createdrawer(
    gamedata.actor.claimed[id].animations.clawarec, "once"
  ))
  local timer = misc.createtimer(gamedata, clawa.rtime)
  return clawa.rrun(timer, gamedata, id)
end

function clawa.rrun(timer, gamedata, id)
  gamedata.actor.vx[id] = 0
  if not timer(gamedata) or input.ispressed(gamedata, keys.jump) then
    return normal.begin(gamedata, id, gamedata.system.time)
  elseif input.ispressed(gamedata, keys.attack) then
    return clawb.abegin(coroutine.yield())
  else
    return clawa.rrun(timer, coroutine.yield())
  end
end

clawb.aframes = 4
clawb.atime = 0.2
clawb.rtime = 0.3
clawb.aframetime = clawb.atime / clawb.aframes
function clawb.abegin(gamedata, id)
  gamedata.actor.draw[id] = control.createdrawer(misc.createdrawer(
    gamedata.actor.claimed[id].animations.clawb, "once"
  ))
  turn(gamedata, id)
  local timer = misc.createtimer(gamedata, clawb.atime)
  local boxtimer = misc.createinterval(
    gamedata, clawb.aframetime * 2, clawb.aframetime
  )
  local dmgfunc = combat.createoneshotdamage(id, 2)
  return clawb.arun(timer, boxtimer, dmgfunc, gamedata, id)
end

function clawb.arun(timer, boxtimer, dmgfunc, gamedata, id)
  gamedata.actor.vx[id] = 0
  if boxtimer(gamedata) then
    local bid = gamedata.actor.claimed[id].hitbox.clawb
    local coolisions = coroutine.yield({bid})
    local bcool = coolisions[bid]
    for _, otherid in ipairs(bcool) do
      dmgfunc(gamedata, otherid)
    end
  end
  if timer(gamedata) then
    return clawb.arun(timer, boxtimer, dmgfunc, coroutine.yield())
  else
    return clawb.rbegin(coroutine.yield())
  end
end

function clawb.rbegin(gamedata, id)
  gamedata.actor.draw[id] = control.createdrawer(misc.createdrawer(
    gamedata.actor.claimed[id].animations.clawbrec, "once"
  ))
  local timer = misc.createtimer(gamedata, clawb.rtime)
  return clawb.rrun(timer, gamedata, id)
end

function clawb.rrun(timer, gamedata, id)
  gamedata.actor.vx[id] = 0
  if not timer(gamedata) or input.ispressed(gamedata, keys.jump) then
    return normal.begin(gamedata, id, gamedata.system.time)
  elseif input.ispressed(gamedata, keys.attack) then
    return clawc.abegin(coroutine.yield())
  else
    return clawb.rrun(timer, coroutine.yield())
  end
end

clawc.aframes = 4
clawc.atime = 0.4
clawc.rtime = 0.4
clawc.aframetime = clawc.atime / clawc.aframes
function clawc.abegin(gamedata, id)
  gamedata.actor.draw[id] = control.createdrawer(misc.createdrawer(
    gamedata.actor.claimed[id].animations.clawc, "once"
  ))
  turn(gamedata, id)
  local timer = misc.createtimer(gamedata, clawc.atime)
  local boxtimer = misc.createinterval(
    gamedata, clawc.aframetime * 2, clawc.aframetime
  )
  local dmgfunc = combat.createoneshotdamage(id, 4)
  return clawc.arun(timer, boxtimer, dmgfunc, gamedata, id)
end

function clawc.arun(timer, boxtimer, dmgfunc, gamedata, id)
  gamedata.actor.vx[id] = 0
  if boxtimer(gamedata) then
    local bid = gamedata.actor.claimed[id].hitbox.clawc
    local coolisions = coroutine.yield({bid})
    local bcool = coolisions[bid]
    for _, otherid in ipairs(bcool) do
      dmgfunc(gamedata, otherid)
    end
  end
  if timer(gamedata) then
    return clawc.arun(timer, boxtimer, dmgfunc, coroutine.yield())
  else
    return clawc.rbegin(coroutine.yield())
  end
end

function clawc.rbegin(gamedata, id)
  gamedata.actor.draw[id] = control.createdrawer(misc.createdrawer(
    gamedata.actor.claimed[id].animations.clawcrec, "once"
  ))
  local timer = misc.createtimer(gamedata, clawc.rtime)
  return clawc.rrun(timer, gamedata, id)
end

function clawc.rrun(timer, gamedata, id)
  gamedata.actor.vx[id] = 0
  if not timer(gamedata) or input.ispressed(gamedata, keys.jump) then
    if input.ispressed(gamedata, keys.attack) then
      input.latch(gamedata, keys.attack)
      return clawa.abegin(coroutine.yield())
    end
    gamedata, id = coroutine.yield()
    return normal.begin(gamedata, id, gamedata.system.time)
  else
    return clawc.rrun(timer, coroutine.yield())
  end
end

function control.begin(gamedata, id)
  local co = coroutine.create(normal.begin)
  return control.run(co, gamedata, id)
end

function control.run(co, gamedata, id)
  if input.ispressed(gamedata, keys.dash) then
    input.latch(gamedata, keys.dash)
    if game.onground(gamedata, id) then
      co = coroutine.create(evade.run)
    else
      co = coroutine.create(airevade.begin)
    end
  end

  local _, activehitbox = coroutine.resume(co, gamedata, id)
  activehitbox = activehitbox or {}
  local resume_inner = #activehitbox > 0
  local hb = gamedata.actor.claimed[id].hitbox
  table.insert(activehitbox, hb.body)
  local collisions = coroutine.yield(activehitbox)

  local lid = gamedata.actor.claimed[id].light
  gamedata.light.point.x[lid] = gamedata.actor.x[id]
  gamedata.light.point.y[lid] = gamedata.actor.y[id]

  if resume_inner then coroutine.resume(co, collisions) end

  return control.run(co, coroutine.yield())
end

local function drawparticletrail(gamedata, pid, ox, oy)
  ox = ox or 0
  oy = oy or 0
  local trail = gamedata.particles.system[pid]
  local x = gamedata.particles.x[pid]
  local y = gamedata.particles.y[pid]
  local px, py = trail:getPosition()
  local sx = trail:getSizes()
  trail:update(gamedata.system.dt)
  local pot = x + sx * px
  love.graphics.draw(trail, pot + ox * sx, y - py + oy, 0, -sx, 1)
end

function control.createdrawer(co)
  --local co = coroutine.create(f)
  local draw
  draw = function(gamedata, id)
    local act = gamedata.actor
    local eid = act.claimed[id].evadeparticle
    local aid = act.claimed[id].airevadeparticle
    drawparticletrail(gamedata, aid, 24)
    drawparticletrail(gamedata, eid, -5)
    coroutine.resume(co, gamedata, id)
    return draw(coroutine.yield())
  end
  return coroutine.create(draw)
end

local function createevadeparticles(particles, id, im, x ,y)
  local spray = gfx.newParticleSystem(im, 20)
  spray:setEmissionRate(60)
  spray:setSizes(1.0)
  spray:setAreaSpread("normal", 0, 0)
  spray:setInsertMode("random")
  spray:setSizeVariation(0)
  local life = 0.15
  spray:setParticleLifetime(life, life)
  spray:setDirection(0)
  spray:setLinearAcceleration(0, 0, 0, 0)
  spray:setColors(255, 50, 50, 200, 200, 50, 100, 100, 150, 50, 200, 0)
  spray:stop()

  if x and y then
    local q1 = gfx.newQuad(0, 0, x, y, im:getDimensions())
    local q2 = gfx.newQuad(x, 0, x, y, im:getDimensions())
    spray:setQuads(q1, q2)
  end

  particles.system[id] = spray
  particles.x[id] = 0
  particles.y[id] = 0
end

local function setuppointlight(gamedata, color, pos, atten)
  local lp = gamedata.light.point
  local id = allocresource(lp)
  lp.red[id] = color[1]
  lp.green[id] = color[2]
  lp.blue[id] = color[3]
  lp.x[id] = pos[1]
  lp.y[id] = pos[2]
  lp.z[id] = pos[3]
  lp.attenuation[id] = atten
  return id
end

function actor.shalltear(gamedata, id, x, y)
  -- Allocate table resources
  -- Setup debug rendering info
  local resim = gamedata.resource.images
  local claimed = gamedata.actor.claimed
  claimed[id] = {
    animations = {
      -- Ground idle animations
      idle = initanimation(gamedata, resim[ims.idle], 48, 48, 0.3, 4),
      run = initanimation(gamedata, resim[ims.run], 48, 48, 0.1, 8),
      beastidle = initanimation(gamedata, resim[ims.beastidle], 48, 48, 0.2, 3),
      beastrun = initanimation(gamedata, resim[ims.beastrun], 48, 48, 0.1, 8),
      -- Arial animation
      descend = initanimation(gamedata, resim[ims.descend], 48, 48, 0.1, 2),
      ascend = initanimation(gamedata, resim[ims.ascend], 48, 48, 0.1, 2),
      midair = initanimation(gamedata, resim[ims.midair], 48, 48, 0.05, 2),
      evade = initanimation(gamedata, resim[ims.evade], 48, 48, 1, 1),
      beastdescend = initanimation(
        gamedata, resim[ims.beastdescend], 48, 48, 0.1, 2
      ),
      beastmidair = initanimation(
        gamedata, resim[ims.beastmidair], 48, 48, 0.05, 2
      ),
      beastascend = initanimation(
        gamedata, resim[ims.beastascend], 48, 48, 0.1, 2
      ),
      -- Attack animations
      clawa = initanimation(
        gamedata, resim[ims.clawa], 48, 48, clawa.aframetime, clawa.aframes
      ),
      clawarec = initanimation(
        gamedata, resim[ims.clawarec], 48, 48, clawa.rtime / 7, 7
      ),
      clawb = initanimation(
        gamedata, resim[ims.clawb], 48, 48, clawb.aframetime, clawb.aframes
      ),
      clawbrec = initanimation(
        gamedata, resim[ims.clawbrec], 48, 48, clawb.rtime / 3, 3
      ),
      clawc = initanimation(
        gamedata, resim[ims.clawc], 96, 48, clawc.aframetime, clawc.aframes
      ),
      clawcrec = initanimation(
        gamedata, resim[ims.clawcrec], 96, 48, clawc.rtime / 3, 3
      ),
    },
    evadeparticle = initresource(
      gamedata.particles, createevadeparticles, resim[ims.evade]
    ),
    airevadeparticle = initresource(
      gamedata.particles, createevadeparticles, resim[ims.beastdescend], 48, 48
    ),
    hitbox = {
      body = initresource(
        gamedata.hitbox, coolision.createaxisbox, -w, -h, w * 2, h * 2,
        gamedata.hitboxtypes.allybody
      ),
      clawa = initresource(
        gamedata.hitbox, coolision.createaxisbox, 0, -5, 23, 15, nil,
        gamedata.hitboxtypes.enemybody
      ),
      clawb = initresource(
        gamedata.hitbox, coolision.createaxisbox, -3, -5, 27, 17, nil,
        gamedata.hitboxtypes.enemybody
      ),
      clawc = initresource(
        gamedata.hitbox, coolision.createaxisbox, 5, -12, 42, 29, nil,
        gamedata.hitboxtypes.enemybody
      )
    },
    light = setuppointlight(gamedata, {0.8, 0.3, 0.3}, {200, -200, 30}, 1e-4),
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
  gamedata.actor.invincibility[id] = 0
  act.health[id] = 20
  gamedata.actor.control[id] = coroutine.create(control.begin)
end
