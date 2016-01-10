require "ai"

loaders = loaders or {}
knight = knight or {}

local entities = {}

local anime = {}
local hitbox = {}

local width = 5
local height = 22
local speed = 50

local poke = {
  wtime = 0.3,
  atime = 0.4,
  rtime = 0.4
}
local upslash = {
  wtime = 0.5,
  atime = 0.2,
  rtime = 0.4,
}
local evdslash = {
  dist = 40,
  etime = 0.3,
  wtime = 0.5,
  atime = 0.3,
  rtime = 0.3,
}

-- Define actions
local action = {}
local control = {}
local ai = {}

function action.poke(gamedata, id, other)
  local act = gamedata.actor
  local timer
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.walk, 0.2 * 4 / 1.5, "repeat"
  )
  ai.moveto(gamedata, id, other, speed * 1.5, hitbox.antistuck, 35)
  act.vx[id] = 0
  -- Windup
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.poke, poke.wtime, "once", 1, 1
  )
  timer = misc.createtimer(gamedata, poke.wtime)
  while timer(gamedata) do
    do_action()
    coroutine.yield()
  end
  -- Attack
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.poke, poke.atime, "once"
  )
  timer = misc.createtimer(gamedata, poke.atime)
  local seq = combat.hitboxseq(gamedata, hitbox.poke, 4, poke.atime)
  local dmg = combat.createoneshotdamage(hitbox.poke, 1)
  while timer(gamedata) do
    do_action(gamedata, id, seq, dmg)
    coroutine.yield()
  end
  -- Recover
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.poke, poke.rtime, "once", 4, 4
  )
  timer = misc.createtimer(gamedata, poke.rtime)
  while timer(gamedata) do
    do_action()
    coroutine.yield()
  end
  -- Stub
  do_action()
end

function action.upslash(gamedata, id, other)
  local act = gamedata.actor
  local timer
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.walk, 0.2 * 4, "repeat"
  )
  ai.moveto(gamedata, id, other, speed, hitbox.antistuck, 35)
  act.vx[id] = 0
  -- Windup
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.upslash, upslash.wtime, "once", 1, 1
  )
  timer = misc.createtimer(gamedata, upslash.wtime)
  while timer(gamedata) do
    do_action()
    coroutine.yield()
  end
  -- Attack
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.upslash, upslash.atime, "once"
  )
  timer = misc.createtimer(gamedata, upslash.atime)
  local seq = combat.hitboxseq(
    gamedata, hitbox.upslash, 5, upslash.atime
  )
  local dmg = combat.createoneshotdamage(hitbox.upslash, 1)
  while timer(gamedata) do
    do_action(gamedata, id, seq, dmg)
    coroutine.yield()
  end
  -- Recover
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.upslash, upslash.rtime, "once", 5, 5
  )
  timer = misc.createtimer(gamedata, upslash.rtime)
  while timer(gamedata) do
    do_action()
    coroutine.yield()
  end
  -- Stub
  do_action()
end

function action.evadeslash(gd, id)
  local cs = trail.chain(
    trail.color(
      gamedata, "knight", {50, 200, 200, 100}, {0, 50, 150, 0}
    ),
    trail.scale(1, 1.5)
  )
  local createdraw = function(time, from, to)
    return trail.drawer(
      gamedata, 0, evdslash.etime * 0.5, "knight", anime.evadeslash,
      time, cs, "once", from, to
    )
  end
  local act = gamedata.actor
  local f = act.face[id]
  local timer
  -- Evade state
  act.vx[id] = -f * 0.8 * evdslash.dist / evdslash.etime
  --act.vy[id] = 55
  --act.draw[id] = animation.draw(
  --  gamedata, "knight", anime.evadeslash, evdslash.etime, "once", 1, 1
  --)
  act.draw[id] = createdraw(evdslash.etime, 1, 1)
  timer = misc.createtimer(gd, evdslash.etime)
  act.invincibility[id] = act.invincibility[id] + 1
  while timer(gd) do
    do_action()
    coroutine.yield()
  end
  act.invincibility[id] = act.invincibility[id] - 1
  -- Windup state
  act.vx[id] = 0
  act.vy[id] = 0
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.evadeslash, evdslash.wtime, "once", 3, 4
  )
--  act.draw[id] = createdraw(evdslash.wtime, 3, 4)
  timer = misc.createtimer(gd, evdslash.wtime)
  while timer(gd) do
    do_action()
    coroutine.yield()
  end
  -- Attack state
  act.vx[id] = f * evdslash.dist / evdslash.atime
  --act.vy[id] = 30
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.evadeslash, evdslash.atime, "once", 5, 7
  )
  --act.draw[id] = createdraw(evdslash.atime, 5, 7)
  timer = misc.createtimer(gd, evdslash.atime)
  local seq = combat.hitboxseq(gamedata, hitbox.evadeslash, 3, evdslash.atime)
  local dmg = combat.createoneshotdamage(hitbox.evadeslash, 1)
  while timer(gd) do
    do_action(gamedata, id, seq, dmg)
    coroutine.yield()
  end
  -- Recover
  act.vx[id] = 0
  act.vy[id] = 0
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.evadeslash, evdslash.rtime, "once", 3, 3
  )
  timer = misc.createtimer(gd, evdslash.rtime)
  while timer(gd) do
    do_action()
    coroutine.yield()
  end
  do_action()
end

-- Define actions
function action.idle(gamedata, id)
  local act = gamedata.actor
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.idle, 0.2 * 4, "bounce"
  )
  act.vx[id] = 0
  local next_action
  while not next_action do
    next_action = do_action(gamedata, id)
    coroutine.yield()
  end
  return next_action
end

-- Define global meta function

function control.begin(gamedata, id)
  return control.run(gamedata, id)
end
function control.run(gamedata, id)
  local act = gamedata.actor
  -- Obtain hitboxes
  local colreq = {}
  for _, eid in pairs(entities) do
    local state, cr = coroutine.resume(act.action[eid], gamedata, eid)
    colreq[eid] = cr or {}
  end
  -- Add compulsory hitboxes
  for id, cr in pairs(colreq) do
    table.insert(cr, hitbox.body)
    --table.insert(cr, hitbox.antistuck)
    table.insert(cr, hitbox.follow)
  end
  -- Submit for collision detection
  local colres = coroutine.yield(colreq)
  -- Give hitbox results to each entity and obtain combat requests
  local combatreq = {}
  for _, entid in pairs(entities) do
    local _, cr = coroutine.resume(act.action[entid], colres)
    if cr then combatreq[entid] = cr end
  end
  local combatres = coroutine.yield(combatreq)
  -- Now decide course of action based on the previous frame data
  -- FIX: DOES nothing
  for _, eid in pairs(entities) do
    local state, accept = coroutine.resume(act.action[eid], combatres)
  end
  -- HACK
  -- Release and prepare for next fram
  -- Finally run drawers
  for _, eid in pairs(entities) do
    --coroutine.resume(act.draw[eid], gamedata.system.dt, act.x[eid], act.y[eid])
    animation.entitydraw(gamedata, eid, act.draw[eid])
  end
  return control.run(coroutine.yield())
end

-- AI
function ai.knight(gd, id, col, com, pid)
  local act = gamedata.actor
  local bias = {
    poke = {},
    upslash = {},
  }
  local stamcost = {
    poke = 1,
    upslash = 1,
  }
  local attacks = {
    poke = action.poke,
    upslash = action.upslash,
  }
  while true do
    for _, id in pairs(entities) do
      if coroutine.status(act.action[id]) == "dead" then
        -- Roll for action
        
      end
    end
    gd, id, col, com = coroutine.yield()
  end
end

function loaders.knight(gamedata)
  -- Create atlas
  local im = gfx.newImage("res/knight.png")
  gamedata.resource.atlas.knight = gfx.newSpriteBatch(im, 200, "stream")
  local index = require "res/knight"
  local initanime = function(key, frames, ox, oy)
    anime[key] = initresource(
      gamedata.animations, animation.init, im, index[key], frames, ox, oy
    )
  end
  -- Initialize animation frames
  initanime("walk", 4, 27, 26)
  initanime("idle", 3, 24, 26)
  initanime("dead", 4, 48, 25)
  initanime("poke", 4, 48, 26)
  initanime("evadeslash", 7, 48, 74)
  initanime("upslash", 5, 51, 74)
  -- Create hitboxes
  local ht = gamedata.hitboxtypes
  hitbox.follow = initresource(
    gamedata.hitbox, coolision.createcenterbox, 600, 5, nil, ht.allybody
  )
  hitbox.body = initresource(
    gamedata.hitbox, coolision.createcenterbox, width * 2, height * 2,
    ht.enemybody
  )
  hitbox.poke = {
    [2] = initresource(
      gamedata.hitbox, coolision.createaxisbox, -14, 3, 52, 3 , nil, ht.allybody
    ),
  }
  hitbox.upslash = {
    [2] = initresource(
      gamedata.hitbox, coolision.createaxisbox, 16, -10, 20, 31, nil,
      ht.allybody
    ),
    [3] = initresource(
      gamedata.hitbox, coolision.createaxisbox, -16, 17, 45, 19, nil,
      ht.allybody
    ),
  }
  -- Begins with frame 5
  hitbox.evadeslash = {
    [1] = initresource(
      gamedata.hitbox, coolision.createaxisbox, -23, 20, 25, 20, nil, ht.allybody
    ),
    [2] = initresource(
      gamedata.hitbox, coolision.createaxisbox, 10, -6, 22, 32, nil, ht.allybody
    ),
    [3] = initresource(
      gamedata.hitbox, coolision.createaxisbox, 10, -6, 10, 16, nil, ht.allybody
    )
  }
  hitbox.antistuck = initresource(
    gamedata.hitbox, coolision.createcenterbox, 30, height * 2,
    nil, {gamedata.hitboxtypes.enemybody, gamedata.hitboxtypes.allybody}
  )
  -- Set control script
  gamedata.global.control.knight = coroutine.create(control.begin)
end

-- Define global APIs
function knight.add(gamedata, x, y)
  local id = initresource(gamedata.actor, function(act, id)
    act.x[id] = x
    act.y[id] = y
    act.width[id] = width
    act.height[id] = height
    act.vx[id] = 0
    act.vy[id] = 0
    act.face[id] = 1

    act.health[id] = 20
    act.stamina[id] = 2
    act.invincibility[id] = 0
    act.action[id] = coroutine.create(action.idle)
  end)
  print("create", id)
  table.insert(entities, id)
  return id
end

knight.action = action
