local fun = require "modules/functional"
require "ai"

actor = actor or {}
loaders = loaders or {}

local w = 5
local h = 22
local speed = 80
local pfollow = {w = 600, h = 5}

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
}

loaders.knight = function(gamedata)
  for _, path in pairs(ims) do
    gamedata.resource.images[path] = loadspriteimage(path)
  end
end

local control = {}
local idle = {}
local follow = {}
local attacka = {}
local attackb = {}
local attackc = {}

function idle.begin(gamedata, id)
  gamedata.actor.draw[id] = coroutine.create(defaultdrawer)
  return idle.run(gamedata, id)
end

function idle.run(gamedata, id)
  local fid = fetchhitbox(gamedata, id, "follow")
  local cols = coroutine.yield({fid})
  local tofollow = cols[fid]
  print(#tofollow)
  if #tofollow > 0 then
    ai.sortclosest(gamedata, id, tofollow)
    if tofollow[1] ~= id then
      return follow.begin(tofollow[1], coroutine.yield())
    end
  end
  return idle.run(coroutine.yield())
end

function follow.begin(fid, gamedata, id)
  gamedata.actor.draw[id] = coroutine.create(defaultdrawer)
  return follow.run(fid, gamedata, id)
end

function follow.run(fid, gamedata, id)
  local act = gamedata.actor
  local bid = fetchhitbox(gamedata, id, "antistuck")
  local cols = coroutine.yield({bid})
  local minvx = -math.huge
  local maxvx = math.huge
  for _, oid in ipairs(cols[bid]) do
    local dx = act.x[oid] - act.x[id]
    if dx > 0 then maxvx = 0 elseif dx < 0 then minvx = 0 end
  end
  local dx = act.x[fid] - act.x[id]
  dx = dx > 0 and 1 or -1
  act.vx[id] = math.max(minvx, math.min(maxvx, dx * speed))
  act.face[id] = dx
  return follow.run(fid, coroutine.yield())
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
  if do_resume then coroutine.resume(co, colres) end
  return control.run(co, coroutine.yield())
end

function actor.knight(gamedata, id, x, y)
  local resim = gamedata.resource.images
  gamedata.actor.claimed[id] = {
    anime = {
      walk = initanimation(gamedata, resim[ims.walk], 48, 48, 0.2, 4),
      idle = initanimation(gamedata, resim[ims.idle], 48, 48, 0.2, 3),
    },
    hitbox = {
      follow = initresource(
        gamedata.hitbox, coolision.createaxisbox, -pfollow.w, -pfollow.h,
        pfollow.w * 2, pfollow.h * 2, nil, gamedata.hitboxtypes.allybody
      ),
      body = initresource(
        gamedata.hitbox, coolision.createaxisbox, -w, -h, w * 2, h * 2,
        gamedata.hitboxtypes.enemybody
      ),
      antistuck = initresource(
        gamedata.hitbox, coolision.createaxisbox, -24, -h, 48, h * 2,
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

  act.control[id] = coroutine.create(control.begin)
end
