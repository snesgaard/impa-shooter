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

-- Overrule do_action so it always includes body hitbox
local raw_do_action = do_action
local do_action = function(gd, id, col, com)
  local supercol
  if col then
    supercol = function(gd, id)
      local r = col(gd, id)
      table.insert(r, hitbox.body)
      return r
    end
  else
    supercol = function(gd, id)
      return {hitbox.body}
    end
  end
  raw_do_action(gd, id, supercol, com)
end


local action = {}
local control = {}

function control.die(gd, id, fd)
  gd.actor.action[id] = coroutine.create(action.die)
  while true do
    coroutine.yield()
  end
end

local function attacktable(other)
  local ac = action
  return {
    function(gd, id)
      ac.goto(gd, id, other)
      ac.poke(gd, id, other)
      local dx = gd.actor.x[other] - gd.actor.x[id]
      local f = gd.actor.face[id]
      if f * dx < 150 and f * dx > 0 then
        ac.poke(gd, id, other)
      end
      do_action(gd, id)
    end,
    function(gd, id)
      ac.goto(gd, id, other)
      ac.upslash(gd, id, other)
      local dx = gd.actor.x[other] - gd.actor.x[id]
      local f = gd.actor.face[id]
      if f * dx > -150 and f * dx < 0 then
        ac.poke(gd, id, other)
      else
        do_action(gd, id)
        return
      end
      local dx = gd.actor.x[other] - gd.actor.x[id]
      local f = gd.actor.face[id]
      if f * dx < 150 and f * dx > 0 then
        ac.upslash(gd, id, other)
      end
      do_action(gd, id)
    end,
  }
end
function control.decide(gamedata, id, fd)
  local act = gamedata.actor
  act.action[id] = coroutine.create(function(gd, id)
    return action.idle(gd, id)
  end)
  -- Chill first
  local timer = misc.createtimer(gamedata, love.math.random() * 0.5 + 0.2)
  while timer(gamedata) do
    gamedata, id, fd = coroutine.yield()
  end
  -- Do we want to recover stamina first
  local do_recover = act.usedstamina[id] and love.math.random() > 0.1
  if ai.staminaleft(gamedata, id) < 1 or do_recover then
    --act.action[id] = coroutine.create(function(gd, id)
    --  return action.retreat(gd, id, pid)
    --end)
    while act.usedstamina[id] ~= nil do
      gamedata, id, fd = coroutine.yield()
    end
    --act.action[id] = coroutine.create(action.idle)
  end
  while true do
    local pid = fd.playerid
    local dx = math.abs(act.x[pid] - act.x[id])
    local dy = math.abs(act.y[pid] - act.y[id])
    if dy < 300 and dx < 300 and ai.staminaleft(gamedata, id) >= 1 then
      local attack = attacktable(pid)
      local a = attack[love.math.random(#attack)]
      act.usedstamina[id] = (act.usedstamina[id] or 0) + 1
      return control.attack(gamedata, id, fd, a)
    end
    gamedata, id, fd = coroutine.yield()
  end
end
function control.attack(gamedata, id, fd, attack)
  local act = gamedata.actor
  act.action[id] = coroutine.create(attack)
  local do_check = true
  while coroutine.status(act.action[id]) ~= "dead" do
    if do_check and #(fd.combatres[id] or {}) > 0 then
      -- Only evadeslash some times
      if love.math.random() >= 0.25 then
        ai.turn(gamedata, id, fd.combatres[id][1].from)
        return control.evadeattack(gamedata, id, fd)
      end
    end
    gamedata, id, fd = coroutine.yield()
  end
  return control.decide(gamedata, id, fd)
end
function control.evadeattack(gamedata, id, fd)
  local act = gamedata.actor
  act.action[id] = coroutine.create(action.evadeslash)
  while coroutine.status(act.action[id]) ~= "dead" do
    gamedata, id, fd = coroutine.yield()
  end
  return control.decide(gamedata, id, fd)
end

-- Define actions
function action.idle(gamedata, id)
  local act = gamedata.actor
  local timer = misc.createtimer(gamedata, time)
  gamedata.actor.vx[id] = 0
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.idle, 0.2 * 4, "bounce"
  )
  while true do
    do_action(gamedata, id)
    coroutine.yield()
  end
end
function action.retreat(gamedata, id, other)
  local act = gamedata.actor
  local s = 1
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.walk, 0.2 * 4 / s, "repeat"
  )
  ai.movefrom(gamedata, id, other, speed * s, hitbox.antistuck, 35)
end
function action.goto(gamedata, id, other)
  local act = gamedata.actor
  local timer
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.walk, 0.2 * 4 / 1.5, "repeat"
  )
  ai.moveto(gamedata, id, other, speed * 1.5, hitbox.antistuck, 35)
end
function action.poke(gamedata, id, other)
  local act = gamedata.actor
  local timer
  --act.draw[id] = animation.draw(
  --  gamedata, "knight", anime.walk, 0.2 * 4 / 1.5, "repeat"
  --)
  --ai.moveto(gamedata, id, other, speed * 1.5, hitbox.antistuck, 35)
  act.vx[id] = 0
  ai.turn(gamedata, id, other)
  -- Windup
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.poke, poke.wtime, "once", 1, 1
  )
  timer = misc.createtimer(gamedata, poke.wtime)
  while timer(gamedata) do
    do_action(gamedata, id)
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
    do_action(gamedata, id)
    coroutine.yield()
  end
end

function action.upslash(gamedata, id, other)
  local act = gamedata.actor
  local timer
  ai.turn(gamedata, id, other)
  --act.draw[id] = animation.draw(
  --  gamedata, "knight", anime.walk, 0.2 * 4, "repeat"
  --)
  --ai.moveto(gamedata, id, other, speed, hitbox.antistuck, 35)
  act.vx[id] = 0
  -- Windup
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.upslash, upslash.wtime, "once", 1, 1
  )
  timer = misc.createtimer(gamedata, upslash.wtime)
  while timer(gamedata) do
    do_action(gamedata, id)
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
    do_action(gamedata, id)
    coroutine.yield()
  end
end

function action.evadeslash(gd, id)
  local cs = trail.chain(
    trail.color(
      gd, "knight", {50, 200, 200, 100}, {0, 50, 150, 0}
    ),
    trail.scale(1, 1.5)
  )
  local createdraw = function(time, from, to)
    return trail.drawer(
      gd, 0, evdslash.etime * 0.5, "knight", anime.evadeslash,
      time, cs, "once", from, to
    )
  end
  local act = gd.actor
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
    do_action(gd, id)
    coroutine.yield()
  end
  act.invincibility[id] = act.invincibility[id] - 1
  -- Windup state
  act.vx[id] = 0
  act.vy[id] = 0
  act.draw[id] = animation.draw(
    gd, "knight", anime.evadeslash, evdslash.wtime, "once", 3, 4
  )
--  act.draw[id] = createdraw(evdslash.wtime, 3, 4)
  timer = misc.createtimer(gd, evdslash.wtime)
  while timer(gd) do
    do_action(gd, id)
    coroutine.yield()
  end
  -- Attack state
  act.vx[id] = f * evdslash.dist / evdslash.atime
  --act.vy[id] = 30
  act.draw[id] = animation.draw(
    gd, "knight", anime.evadeslash, evdslash.atime, "once", 5, 7
  )
  --act.draw[id] = createdraw(evdslash.atime, 5, 7)
  timer = misc.createtimer(gd, evdslash.atime)
  local seq = combat.hitboxseq(gd, hitbox.evadeslash, 3, evdslash.atime)
  local dmg = combat.createoneshotdamage(hitbox.evadeslash, 1)
  while timer(gd) do
    do_action(gd, id, seq, dmg)
    coroutine.yield()
  end
  -- Recover
  act.vx[id] = 0
  act.vy[id] = 0
  act.draw[id] = animation.draw(
    gd, "knight", anime.evadeslash, evdslash.rtime, "once", 3, 3
  )
  timer = misc.createtimer(gd, evdslash.rtime)
  while timer(gd) do
    do_action(gd, id)
    coroutine.yield()
  end
  do_action(gd, id)
end

function action.die(gamedata, id)
  local act = gamedata.actor
  act.draw[id] = animation.draw(
    gamedata, "knight", anime.dead, 2.0, "once"
  )
  act.vx[id] = 0
  while true do
    raw_do_action(gamedata, id)
    coroutine.yield()
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

    act.health[id] = 10
    act.stamina[id] = 2
    act.recover[id] = 0.3
    act.invincibility[id] = 0
    act.action[id] = coroutine.create(action.idle)
    act.control[id] = coroutine.create(control.decide)
    act.death[id] = control.die
  end)
  table.insert(entities, id)
  return id
end

function knight.control()
  return coroutine.create(control.decide)
end
