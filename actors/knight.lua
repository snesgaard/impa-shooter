local fun = require "modules/functional"
require "ai"

actor = actor or {}
loaders = loaders or {}

local w = 5
local h = 22
local speed = 80
local pfollow = {w = 600, h = 5}
local phit = {w = 40, h = 22}
local stamregen = 0.5


local function createdrawer(gamedata, id, name, mode)
  local act = gamedata.actor
  return misc.createdrawer(
    act.claimed[id].anime[name], mode, 0, 2
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
}

loaders.knight = function(gamedata)
  for _, path in pairs(ims) do
    gamedata.resource.images[path] = gamedata.resource.images[path] or loadspriteimage(path)
  end
end

local control = {}
local idle = {}
local follow = {}
local prepoke = {}
local poke = {}
local postpoke = {}
local attackb = {}
local attackc = {}

function idle.begin(gamedata, id)
  return idle.run(gamedata, id)
end

--[[
function idle.run(gamedata, id)
  local fid = fetchhitbox(gamedata, id, "follow")
  local cols = coroutine.yield({fid})
  local tofollow = cols[fid]
  if #tofollow > 0 then
    ai.sortclosest(gamedata, id, tofollow)
    if tofollow[1] ~= id then
      return follow.begin(tofollow[1], coroutine.yield())
    end
  end
  return idle.run(coroutine.yield())
end
--]]

local function canattack(gamedata, id)
  local s = gamedata.actor.stamina[id]
  local u = gamedata.actor.usedstamina[id] or 0
  return s - u >= 1
end

function idle.run(gamedata, id, dco)
  local fid = fetchhitbox(gamedata, id, "follow")
  local hid = fetchhitbox(gamedata, id, "pokescan")
  local sid = fetchhitbox(gamedata, id, "antistuck")
  local cols = coroutine.yield({fid, hid, sid})
  local act = gamedata.actor
  local tohit = cols[hid]
  if #tohit > 0 and canattack(gamedata, id) then
    ai.sortclosest(gamedata, id, tohit)
    gamedata, id = coroutine.yield()
    return prepoke.run(gamedata, id, tohit[1])
  end
  local tofollow = cols[fid]
  if #tofollow > 0 then
    ai.sortclosest(gamedata, id, tofollow)
    local follow = tofollow[1]
    local minvx = -math.huge
    local maxvx = math.huge
    for _, oid in ipairs(cols[sid]) do
      local dx = act.x[oid] - act.x[id]
      if dx > 0 then maxvx = 0 elseif dx < 0 then minvx = 0 end
    end
    local dx = act.x[follow] - act.x[id]
    dx = dx > 0 and 1 or -1
    act.vx[id] = math.max(minvx, math.min(maxvx, dx * speed))
    act.face[id] = dx
  end
  dco = dco or coroutine.create(defaultdrawer)
  gamedata.actor.draw[id] = dco
  gamedata, id = coroutine.yield()
  return idle.run(gamedata, id, dco)
end

prepoke.time = 0.3
function prepoke.run(gamedata, id, tid)
  local act = gamedata.actor
  act.draw[id] = createdrawer(gamedata, id, "prepoke", "once")
  act.vx[id] = 0
  local dx = act.x[tid] - act.x[id]
  act.face[id] = dx / math.abs(dx)
  local timer = misc.createtimer(gamedata, prepoke.time)
  while timer(gamedata) do
    coroutine.yield()
  end
  return poke.run(gamedata, id)
end

poke.time = 0.4
poke.frames = 4
poke.ftime = poke.time / poke.frames
function poke.run(gamedata, id)
  gamedata.actor.draw[id] = createdrawer(gamedata, id, "poke", "once")
  local timer = misc.createtimer(gamedata, poke.time)
  gamedata.actor.usedstamina[id] = (gamedata.actor.usedstamina[id] or 0) + 1
  while timer(gamedata) do
    coroutine.yield()
  end
  return postpoke.run(gamedata, id)
end

postpoke.time = 0.2
postpoke.frames = 1
postpoke.ftime = postpoke.time / postpoke.frames
function postpoke.run(gamedata, id)
  gamedata.actor.draw[id] = createdrawer(gamedata, id, "postpoke", "once")
  local timer = misc.createtimer(gamedata, postpoke.time)
  while timer(gamedata) do
    coroutine.yield()
  end
  return idle.begin(gamedata, id)
end

function control.begin(gamedata, id)
  local co = coroutine.create(idle.begin)
  return control.run(co, gamedata, id)
end

function control.run(co, gamedata, id)
  local _, colreq = coroutine.resume(co, gamedata, id)
  colreq = colreq or {}
  local do_resume = #colreq > 0
  table.insert(colreq, fetchhitbox(gamedata, id, "body"))
  local colres = coroutine.yield(colreq)
  local ustam = gamedata.actor.usedstamina[id] or 0
  ustam = ustam - stamregen * gamedata.system.dt
  if ustam < 0 then
    gamedata.actor.usedstamina[id] = nil
  else
    gamedata.actor.usedstamina[id] = ustam
  end
  if do_resume then coroutine.resume(co, colres) end
  return control.run(co, coroutine.yield())
end

function actor.knight(gamedata, id, x, y)
  local resim = gamedata.resource.images
  gamedata.actor.claimed[id] = {
    anime = {
      walk = initanimation(gamedata, resim[ims.walk], 48, 48, 0.2, 4),
      idle = initanimation(gamedata, resim[ims.idle], 48, 48, 0.2, 3),
      poke = initanimation(
        gamedata, resim[ims.poke], 96, 48, poke.ftime, poke.frames
      ),
      prepoke = initanimation(gamedata, resim[ims.prepoke], 96, 48, 0.2, 1),
      postpoke = initanimation(
        gamedata, resim[ims.postpoke], 96, 48, postpoke.ftime, postpoke.frames
      ),
    },
    hitbox = {
      follow = initresource(
        gamedata.hitbox, coolision.createaxisbox, -pfollow.w, -pfollow.h,
        pfollow.w * 2, pfollow.h * 2, nil, gamedata.hitboxtypes.allybody
      ),
      pokescan = initresource(
        gamedata.hitbox, coolision.createaxisbox, -phit.w, -phit.h,
        phit.w * 2, phit.h * 2, nil, gamedata.hitboxtypes.allybody
      ),
      body = initresource(
        gamedata.hitbox, coolision.createaxisbox, -w, -h, w * 2, h * 2,
        gamedata.hitboxtypes.enemybody
      ),
      antistuck = initresource(
        gamedata.hitbox, coolision.createaxisbox, -20, -h, 40, h * 2,
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
  act.stamina[id] = 1

  act.control[id] = coroutine.create(control.begin)
end
