local fun = require "modules/functional"
require "ai"

actor = actor or {}
loaders = loaders or {}

local w = 5
local h = 22
local speed = 80
local pfollow = {w = 600, h = 5}
local phit = {w = 52, h = 3}
local stamregen = 0.5

local function animedata(frames, time)
  return {f = frames, t = time, ft = time / frames}
end
local function createdrawer(gamedata, id, name, mode, ox, oy)
  local act = gamedata.actor
  ox = ox or 0
  oy = oy or 0
  oy = oy + 2
  return misc.createdrawer(
    act.claimed[id].anime[name], mode, ox, oy
  )
end
local function fetchhitbox(gamedata, id, name)
  local act = gamedata.actor
  return act.claimed[id].hitbox[name]
end
local function defaultdrawer(gamedata, id)
  local idledrawer = createdrawer(gamedata, id, "idle", "bounce")
  local walkdrawer = createdrawer(gamedata, id, "walk")
  local act = gamedata.actor
  while true do
    local vx = act.vx[id]
    if math.abs(vx) > 1 then
      coroutine.resume(walkdrawer, gamedata, id)
    else
      coroutine.resume(idledrawer, gamedata, id)
    end
    coroutine.yield()
  end
end

local imroot = "res/knight"
local function impather(name)
  return imroot .. "/" .. name
end

local ims = {
  idle = impather("idle.png"),
  walk = impather("walk.png"),
  poke = impather("poke.png"),
  prepoke = impather("poke.png"),
  postpoke = impather("postpoke.png"),
  upslash = impather("upslash.png"),
  preupslash = impather("upslash_pre.png"),
  postupslash = impather("upslash_post.png"),
  dead = impather("dead.png"),
  evadeslash = impather("evadeslash.png"),
}

loaders.knight = function(gamedata)
  for _, path in pairs(ims) do
    gamedata.resource.images[path] = gamedata.resource.images[path] or loadspriteimage(path)
  end
end

local function canattack(gamedata, id)
  local s = gamedata.actor.stamina[id]
  local u = gamedata.actor.usedstamina[id] or 0
  return s - u >= 1
end

local control = {}
local idle = {}
local follow = {}
local prepoke = {}
local poke = {}
local postpoke = {}
local upslash = {}
local evadeslash = {}
local dead = {}

idle.pokebias = 0.75
function idle.run(gamedata, id, co)
  local fbid = fetchhitbox(gamedata, id, "follow")
  local colres = coroutine.yield({fbid})
  local tohit = colres[fbid]
  if #tohit > 0 then
    ai.sortclosest(gamedata, id, tohit)
    gamedata, id = coroutine.yield()
    local attacks = {poke, upslash}
    local p = love.math.random()
    local aid = p < idle.pokebias and 1 or 2
    return attacks[aid].run(gamedata, id, tohit[1])
  end
  co = co or coroutine.create(defaultdrawer)
  gamedata.actor.draw[id] = co
  gamedata.actor.vx[id] = 0
  gamedata, id = coroutine.yield()
  return idle.run(gamedata, id, co)
end


poke.windup = animedata(1, 0.4)
poke.attack = animedata(4, 0.4)
poke.recover = animedata(1, 0.3)

function poke.run(gamedata, id, tid)
  gamedata.actor.draw[id] = coroutine.create(defaultdrawer)
  local asid = fetchhitbox(gamedata, id, "antistuck")
  local tol = 40
  local reached = ai.moveto(gamedata, id, tid, speed, asid, tol)
  gamedata.actor.vx[id] = 0
  if not reached or not canattack(gamedata, id) then return idle.run(gamedata, id) end
  local timer = misc.createtimer(gamedata, poke.windup.t)
  gamedata.actor.draw[id] = createdrawer(gamedata, id, "prepoke", "once")
  while timer(gamedata) do
    coroutine.yield()
  end
  timer = misc.createtimer(gamedata, poke.attack.t)
  gamedata.actor.draw[id] = createdrawer(gamedata, id, "poke", "once")
  local hid = fetchhitbox(gamedata, id, "poke")
  local boxtimer = misc.createinterval(
    gamedata, poke.attack.ft, poke.attack.ft * 2
  )
  local dmgfunc = combat.createoneshotdamage(id, 2)
  while timer(gamedata) do
    if boxtimer(gamedata) then
      local cols = coroutine.yield({hid})
      for _, otherid in ipairs(cols[hid]) do
        dmgfunc(gamedata, otherid)
      end
    end
    coroutine.yield()
  end
  gamedata.actor.usedstamina[id] = (gamedata.actor.usedstamina[id] or 0) + 1
  timer = misc.createtimer(gamedata, poke.recover.t)
  gamedata.actor.draw[id] = createdrawer(gamedata, id, "postpoke", "once")
  while timer(gamedata) do
    coroutine.yield()
  end
  return upslash.run(gamedata, id, tid)
end

upslash.windup = animedata(1, 0.4)
upslash.attack = animedata(5, 0.3)
upslash.recover = animedata(1, 0.3)
function upslash.run(gamedata, id, tid)
  gamedata.actor.draw[id] = coroutine.create(defaultdrawer)
  local asid = fetchhitbox(gamedata, id, "antistuck")
  local tol = 40
  local reached = ai.moveto(gamedata, id, tid, speed, asid, tol)
  gamedata.actor.vx[id] = 0
  if not reached or not canattack(gamedata, id) then return idle.run(gamedata, id) end
  -- Windup state
  local timer = misc.createtimer(gamedata, upslash.windup.t)
  gamedata.actor.draw[id] = createdrawer(
    gamedata, id, "preupslash", "once", 0, 24
  )
  while timer(gamedata) do
    coroutine.yield()
  end
  timer = misc.createtimer(gamedata, upslash.attack.t)
  gamedata.actor.draw[id] = createdrawer(
    gamedata, id, "upslash", "once", 0, 24
  )
  --[[
  local hid = fetchhitbox(gamedata, id, "poke")
  local boxtimer = misc.createinterval(
    gamedata, poke.attack.ft, poke.attack.ft * 2
  )
  ]]--
  local dmgfunc = combat.createoneshotdamage(id, 2)
  local hid2 = fetchhitbox(gamedata, id, "upslash_f2")
  local hid3 = fetchhitbox(gamedata, id, "upslash_f3")
  local timerf2 = misc.createinterval(
    gamedata, upslash.attack.ft, upslash.attack.ft
  )
  local timerf3 = misc.createinterval(
    gamedata, upslash.attack.ft * 2, upslash.attack.ft
  )
  while timer(gamedata) do
    local hid
    if timerf2(gamedata) then
      hid = hid2
    elseif timerf3(gamedata) then
      hid = hid3
    end
    if hid then
      local cols = coroutine.yield({hid})
      for _, otherid in ipairs(cols[hid]) do
        dmgfunc(gamedata, otherid)
      end
    end
    coroutine.yield()
  end
  gamedata.actor.usedstamina[id] = (gamedata.actor.usedstamina[id] or 0) + 1
  timer = misc.createtimer(gamedata, upslash.recover.t)
  gamedata.actor.draw[id] = createdrawer(
    gamedata, id, "postupslash", "once", 0, 24
  )
  while timer(gamedata) do
    coroutine.yield()
  end
  return idle.run(gamedata, id)
end

evadeslash.backdist = 40
evadeslash.backtime = 0.4
evadeslash.windup = 0.2
evadeslash.fwddist = 40
evadeslash.fwdtime = 0.4
function evadeslash.run(gamedata, id)
  local act = gamedata.actor
  local evds = evadeslash
  act.draw[id] = createdrawer(
    gamedata, id, "evadeslash", "loop", 0, 24
  )
  local f = act.face[id]
  act.vx[id] = -f * evds.backdist / evds.backtime
  local timer = misc.createtimer(gamedata, evadeslash.backtime)
  while timer(gamedata) do
    coroutine.yield()
  end
  act.vx[id] = f * evds.fwddist / evds.fwdtime
  timer = misc.createtimer(gamedata, evadeslash.fwdtime)
  while timer(gamedata) do
    coroutine.yield()
  end
  return evadeslash.run(gamedata, id)
end

function dead.run(gamedata, id)
  gamedata.actor.draw[id] = createdrawer(gamedata, id, "dead", "once", 0, -1)
  gamedata.actor.vx[id] = 0
  while true do
    coroutine.yield()
  end
end

function control.update(gamedata, id, colreq)
  local ustam = gamedata.actor.usedstamina[id] or 0
  ustam = ustam - stamregen * gamedata.system.dt
  if ustam < 0 then
    gamedata.actor.usedstamina[id] = nil
  else
    gamedata.actor.usedstamina[id] = ustam
  end
  colreq = colreq or {}
  table.insert(colreq, fetchhitbox(gamedata, id, "body"))
  return coroutine.yield(colreq)
end

function control.begin(gamedata, id)
  --local co = coroutine.create(idle.run)
  local co = coroutine.create(evadeslash.run)
  return control.run(co, gamedata, id)
end

function control.run(co, gamedata, id)
  local actor = gamedata.actor
  local hp = actor.health[id]
  local dmg = actor.damage[id] or 0
  if hp <= dmg then return dead.run(gamedata, id) end
  local status, colreq = coroutine.resume(co, gamedata, id)
  colreq = colreq or {}
  local do_resume = #colreq > 0
  local colres = control.update(gamedata, id, colreq)
  if do_resume then status = coroutine.resume(co, colres) end
  return control.run(co, coroutine.yield())
end

function actor.knight(gamedata, id, x, y)
  local resim = gamedata.resource.images
  gamedata.actor.claimed[id] = {
    anime = {
      walk = initanimation(gamedata, resim[ims.walk], 48, 48, 0.2, 4),
      idle = initanimation(gamedata, resim[ims.idle], 48, 48, 0.2, 3),
      poke = initanimation(
        gamedata, resim[ims.poke], 96, 48, poke.attack.ft, poke.attack.f
      ),
      prepoke = initanimation(
        gamedata, resim[ims.prepoke], 96, 48, poke.windup.ft, poke.windup.f
      ),
      postpoke = initanimation(
        gamedata, resim[ims.postpoke], 96, 48, poke.recover.ft, poke.recover.f
      ),
      upslash = initanimation(
        gamedata, resim[ims.upslash], 96, 96, upslash.attack.ft,
        upslash.attack.f
      ),
      preupslash = initanimation(
        gamedata, resim[ims.preupslash], 96, 96, upslash.windup.ft,
        upslash.windup.f
      ),
      postupslash = initanimation(
        gamedata, resim[ims.postupslash], 96, 96, upslash.recover.ft,
        upslash.recover.f
      ),
      evadeslash = initanimation(
        gamedata, resim[ims.evadeslash], 96, 96, 0.1, 7 -- Insert proper defines
      ),
      dead = initanimation(
        gamedata, resim[ims.dead], 96, 48, 0.5, 4
      ),
    },
    hitbox = {
      follow = initresource(
        gamedata.hitbox, coolision.createaxisbox, -pfollow.w, -pfollow.h,
        pfollow.w * 2, pfollow.h * 2, nil, gamedata.hitboxtypes.allybody
      ),
      poke = initresource(
        gamedata.hitbox, coolision.createaxisbox, -14, 3,
        phit.w, phit.h , nil, gamedata.hitboxtypes.allybody
      ),
      upslash_f2 = initresource(
        gamedata.hitbox, coolision.createaxisbox, 16, -10,
        20, 31, nil, gamedata.hitboxtypes.allybody
      ),
      upslash_f3 = initresource(
        gamedata.hitbox, coolision.createaxisbox, -16, 17,
        45, 19, nil, gamedata.hitboxtypes.allybody
      ),
      body = initresource(
        gamedata.hitbox, coolision.createaxisbox, -w, -h, w * 2, h * 2,
        gamedata.hitboxtypes.enemybody
      ),
      antistuck = initresource(
        gamedata.hitbox, coolision.createaxisbox, -15, -h, 30, h * 2,
        nil, {gamedata.hitboxtypes.enemybody, gamedata.hitboxtypes.allybody}
      ),
    }
  }

  local act = gamedata.actor
  act.x[id] = x
  act.y[id] = y
  act.width[id] = w
  act.height[id] = h
  act.vx[id] = 0
  act.vy[id] = 0
  act.face[id] = 1

  act.health[id] = 20
  act.stamina[id] = 2

  act.control[id] = coroutine.create(control.begin)
end
