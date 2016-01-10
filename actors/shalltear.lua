loaders = loaders or {}
shalltear = shalltear or {}

local entities = {}
local beasttimer = {}

local anime = {}
local hitbox = {}

-- Defines
local width = 6
local height = 16
local speed = 100
local jumpspeed = 200

local arial = {
  mtime = 0.15
}
local clawa = {
  atime = 0.2,
  rtime = 0.4,
}
local clawb = {
  atime = 0.2,
  rtime = 0.4,
}
local clawc = {
  atime = 0.3,
  rtime = 0.5,
}
local evade = {
  dist = 40,
  maxtime = 0.2,
  mintime = 0.1
}

local key = {
  left = "left",
  right = "right",
  attack = "f",
  dodge = "lshift",
  jump = "space",
}

-- Utility
local function isbeast(gamedata, id)
  local bt = beasttimer[id] or -1000000000
  if gamedata.system.time - bt > 3 then return true end
  return false
end

-- Sets jump speed and latches ground
local function dojump(gamedata, id)
  gamedata.actor.vy[id] = jumpspeed
  gamedata.actor.ground[id] = nil
end

local function doturn(gd, id)
  local r = input.isdown(gd, key.right)
  local l = input.isdown(gd, key.left)
  local sp = gd.system.pressed
  local gr = (sp[key.right] or 0) > (sp[key.left] or 0)
  if r and (not l or gr) then
     gd.actor.face[id] = 1
   elseif l then
     gd.actor.face[id] = -1
   end
end
-- Functional tables
local action = {}
local control = {}
local draw = {}


-- Special drawers
function beastdraw(gamedata, time, atid, beastid, normid, ft, mode)
  local bd = animation.draw(gamedata, atid, beastid, ft, mode)
  local nd = animation.draw(gamedata, atid, normid, ft, mode)
  local f = function(dt, x, y, r, sx, sy)
    while time > 0 do
      coroutine.resume(bd, dt, x, y, r, sx, sy)
      -- Hack to update without doing the actual drawing
      coroutine.resume(nd, dt, x, y, r, 0, sy)
      time = time - dt
      dt, x, y, r, sx, sy = coroutine.yield()
    end
    while true do
      coroutine.resume(nd, dt, x, y, r, sx, sy)
      dt, x, y, r, sx, sy = coroutine.yield()
    end
  end
  return coroutine.create(f)
end

-- Control
function control.idle(gd, id, col, com)
  gd.actor.action[id] = coroutine.create(action.idle)
  while true do
    local rd = input.isdown(gd, key.right)
    local ld = input.isdown(gd, key.left)
    local p = gd.system.pressed
    local gr = (p[key.right] or 0) > (p[key.left] or 0)
    if not on_ground(gd, id) then
      return control.arial(gd, id, col, com)
    elseif input.ispressed(gd, key.dodge) then
      input.latch(gd, key.dodge)
      return control.evade(gd, id, col, com)
    elseif input.ispressed(gd, key.attack) then
      input.latch(gd, key.attack)
      return control.clawa(gd, id, col, com)
    elseif input.ispressed(gd, key.jump) then
      input.latch(gd, key.jump)
      dojump(gamedata, id)
      return control.arial(gd, id, col, com)
    elseif not rd and not ld then
      gd.actor.vx[id] = 0
    elseif rd and (not ld or gr) then
      gd.actor.face[id] = 1
      gd.actor.vx[id] = speed
    elseif ld then
      gd.actor.face[id] = -1
      gd.actor.vx[id] = -speed
    end
    gd, id, col, com = coroutine.yield()
  end
end
function control.arial(gd, id, col, com)
  gd.actor.action[id] = coroutine.create(action.arial)
  while true do
    local rd = input.isdown(gd, key.right)
    local ld = input.isdown(gd, key.left)
    local p = gd.system.pressed
    local gr = (p[key.right] or 0) > (p[key.left] or 0)
    if on_ground(gd, id) then
      return control.idle(gd, id, col, com)
    elseif not rd and not ld then
      gd.actor.vx[id] = 0
    elseif rd and (not ld or gr) then
      gd.actor.face[id] = 1
      gd.actor.vx[id] = speed
    elseif ld then
      gd.actor.face[id] = -1
      gd.actor.vx[id] = -speed
    end
    gd, id, col, com = coroutine.yield()
  end
end
function control.clawa(gd, id, col, com)
  gd.actor.action[id] = coroutine.create(action.clawa)
  local atimer = misc.createtimer(gd, clawa.atime)
  doturn(gd, id)
  while atimer(gd) do gd, id, col, com = coroutine.yield() end
  local rtimer = misc.createtimer(gd, clawa.rtime)
  while rtimer(gd) do
    if input.ispressed(gd, key.jump) then
      return control.idle(gd, id, col, com)
    elseif input.ispressed(gd, key.dodge) then
      input.latch(gd, key.dodge)
      return control.evade(gd, id, col, com)
    elseif input.ispressed(gd, key.attack) then
      input.latch(gd, key.attack)
      return control.clawb(gd, id, col, com)
    end
    gd, id, col, com = coroutine.yield()
  end
  return control.idle(gd, id, col, com)
end
function control.clawb(gd, id, col, com)
  gd.actor.action[id] = coroutine.create(action.clawb)
  local atimer = misc.createtimer(gd, clawb.atime)
  doturn(gd, id)
  while atimer(gd) do gd, id, col, com = coroutine.yield() end
  local rtimer = misc.createtimer(gd, clawb.rtime)
  while rtimer(gd) do
    -- Chain to next attack
    -- Jump cancelling
    if input.ispressed(gd, key.jump) then
      return control.idle(gd, id, col, com)
    -- Evade cancelling
    elseif input.ispressed(gd, key.dodge) then
      input.latch(gd, key.dodge)
      return control.evade(gd, id, col, com)
    elseif input.ispressed(gd, key.attack) then
      input.latch(gd, key.attack)
      return control.clawc(gd, id, col, com)
    end
    gd, id, col, com = coroutine.yield()
  end
  return control.idle(gd, id, col, com)
end
function control.clawc(gd, id, col, com)
  gd.actor.action[id] = coroutine.create(action.clawc)
  local atimer = misc.createtimer(gd, clawc.atime)
  doturn(gd, id)
  while atimer(gd) do gd, id, col, com = coroutine.yield() end
  local rtimer = misc.createtimer(gd, clawc.rtime)
  while rtimer(gd) do
    -- Jump cancelling
    if input.ispressed(gd, key.jump) then
      return control.idle(gd, id, col, com)
    elseif input.ispressed(gd, key.dodge) then
      input.latch(gd, key.dodge)
      return control.evade(gd, id, col, com)
    end
    gd, id, col, com = coroutine.yield()
  end
  return control.idle(gd, id, col, com)
end
function control.evade(gd, id, col, com)
  local act = gamedata.actor
  gd.actor.action[id] = coroutine.create(action.evade)
  local timer = misc.createtimer(gd, evade.maxtime)
  local exit_ctrl = control.idle
  doturn(gd, id)
  act.invincibility[id] = act.invincibility[id] + 1
  while timer(gd) do
    if input.ispressed(gd, key.jump) then
      input.latch(gd, key.jump)
      exit_ctrl = control.arial
    end
    gd, id, col, com = coroutine.yield()
  end
  act.invincibility[id] = act.invincibility[id] - 1
  if exit_ctrl == control.arial then
    dojump(gd, id)
  end
  return exit_ctrl(gd, id, col, com)
end
-- Actions
function action.idle(gd, id)
  while true do
    gd.actor.draw[id] = beastdraw(
      gamedata, 3.0, "shalltear", anime.beastidle, anime.idle, 0.8, "repeat"
    )
    while math.abs(gd.actor.vx[id]) < 1 do
      do_action()
      coroutine.yield()
    end
    gd.actor.draw[id] = beastdraw(
      gamedata, 3.0, "shalltear", anime.beastrun, anime.run, 0.8, "repeat"
    )
    while math.abs(gd.actor.vx[id]) >= 1 do
      do_action()
      coroutine.yield()
    end
  end
end
function action.arial(gd, id)
  while true do
    gd.actor.draw[id] = beastdraw(
      gd, 3.0, "shalltear", anime.beastascend, anime.ascend, 0.2, "repeat"
    )
    while gd.actor.vy[id] > 0 do
      do_action()
      gd, id = coroutine.yield()
    end
    local timer = misc.createtimer(gd, arial.mtime)
    gd.actor.draw[id] = beastdraw(
      gd, 3.0, "shalltear", anime.beastmidair, anime.midair, arial.mtime, "once"
    )
    while timer(gd) do
      do_action()
      gd, id = coroutine.yield()
    end
    gd.actor.draw[id] = beastdraw(
      gd, 3.0, "shalltear", anime.beastdescend, anime.descend, 0.2, "repeat"
    )
    while gd.actor.vy[id] < 0 do
      do_action()
      gd, id = coroutine.yield()
    end
  end
end
function action.clawa(gamedata, id)
  local act = gamedata.actor
  act.vx[id] = 0
  local atimer = misc.createtimer(gamedata, clawa.atime)
  act.draw[id] = animation.draw(
    gamedata, "shalltear", anime.clawa, clawa.atime, "once"
  )
  local boxids = {[3] = hitbox.clawa}
  local seq = combat.hitboxseq(
    gamedata, boxids, 4, clawa.atime
  )
  local dmg = combat.createoneshotdamage(boxids, 1)
  while atimer(gamedata) do
    do_action(gamedata, id, seq, dmg)
    gamedata, id = coroutine.yield()
  end
  act.draw[id] = animation.draw(
    gamedata, "shalltear", anime.clawa_recov, clawa.rtime, "once"
  )
  while true do
    do_action()
    gamedata, id = coroutine.yield()
  end
end
function action.clawb(gamedata, id)
  local act = gamedata.actor
  act.vx[id] = 0
  local atimer = misc.createtimer(gamedata, clawb.atime)
  act.draw[id] = animation.draw(
    gamedata, "shalltear", anime.clawb, clawb.atime, "once"
  )
  local boxids = {[3] = hitbox.clawb}
  local seq = combat.hitboxseq(
    gamedata, boxids, 4, clawb.atime
  )
  local dmg = combat.createoneshotdamage(boxids, 1)
  while atimer(gamedata) do
    do_action(gamedata, id, seq, dmg)
    gamedata, id = coroutine.yield()
  end
  act.draw[id] = animation.draw(
    gamedata, "shalltear", anime.clawb_recov, clawb.rtime, "once"
  )
  while true do
    do_action()
    gamedata, id = coroutine.yield()
  end
end
function action.clawc(gamedata, id)
  local act = gamedata.actor
  act.vx[id] = 0
  local atimer = misc.createtimer(gamedata, clawc.atime)
  act.draw[id] = animation.draw(
    gamedata, "shalltear", anime.clawc, clawc.atime, "once"
  )
  local boxids = {[3] = hitbox.clawc}
  local seq = combat.hitboxseq(gamedata, boxids, 4, clawc.atime)
  local dmg = combat.createoneshotdamage(boxids, 2)
  while atimer(gamedata) do
    do_action(gamedata, id, seq, dmg)
    gamedata, id = coroutine.yield()
  end
  act.draw[id] = animation.draw(
    gamedata, "shalltear", anime.clawc_recov, clawc.rtime, "once"
  )
  while true do
    do_action()
    gamedata, id = coroutine.yield()
  end
end
function action.evade(gamedata, id)
  local act = gamedata.actor
  act.vx[id] = act.face[id] * evade.dist / evade.maxtime
  local timer = misc.createtimer(gamedata, evade.maxtime)
  --[[
  act.draw[id] = animation.draw(
    gamedata, "shalltear", anime.evade, evade.time, "once"
  )
  --]]
  local cs = trail.chain(
    trail.color(
      gamedata, "shalltear", {255, 50, 100, 100}, {200, 0, 200, 0}
    ),
    trail.scale(1, 1.35)
  )
  act.draw[id] = trail.drawer(
    gamedata, evade.maxtime * 0.35, evade.maxtime * 0.75, "shalltear",
    anime.evade, evade.maxtime, cs, "once"
  )
  while timer(gamedata) do
    act.vy[id] = 0
    do_action()
    gamedata, id = coroutine.yield()
  end
  act.vx[id] = 0
  act.ground[id] = gamedata.system.time
  while true do
    do_action()
    gamedata, id = coroutine.yield()
  end
end

-- General overall control
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
  end
  -- Submit for collision detection
  local colres = coroutine.yield(colreq)
  -- Give hitbox results to each entity and obtain combat results
  --[[
  local combatreq = fun.fmap(function(entid)
    local state, cr = coroutine.resume(act.action[entid], colres)
    return cr or {}
  end, entities)
  --]]
  local combatreq = {}
  for _, entid in pairs(entities) do
    local _, cr = coroutine.resume(act.action[entid], colres)
    if cr then combatreq[entid] = cr end
  end
  local combatres = coroutine.yield(combatreq)
  -- Now decide course of action based on the previous frame data
  -- FIX: DOES nothing
  for _, eid in pairs(entities) do
    local state, accept = coroutine.resume(act.action[eid])
  end
  -- Release and prepare for next fram
  -- Finally run drawers
  for _, eid in pairs(entities) do
    --coroutine.resume(act.draw[eid], gamedata.system.dt, act.x[eid], act.y[eid])
    animation.entitydraw(gamedata, eid, act.draw[eid])
  end
  return control.run(coroutine.yield())
end
-- Loader function
function loaders.shalltear(gamedata)
  -- Load Atlas
  local im = gfx.newImage("res/shalltear.png")
  gamedata.resource.atlas.shalltear = gfx.newSpriteBatch(im, 200, "stream")
  -- Initialize animation frames
  local index = require "res/shalltear"
  local initanime = function(key, frames, ox, oy)
    anime[key] = initresource(
      gamedata.animations, animation.init, im, index[key], frames, ox, oy
    )
  end
  initanime("ascend", 2, 24, 24)
  initanime("beastascend", 2, 24, 24)
  initanime("beastdescend", 2, 24, 24)
  initanime("beastidle", 3, 24, 24)
  initanime("beastmidair", 2, 24, 24)
  initanime("beastrun", 8, 26, 24)
  initanime("clawa", 4, 24, 24)
  initanime("clawa_recov", 7, 24, 24)
  initanime("clawb", 4, 24, 24)
  initanime("clawb_recov", 3, 24, 24)
  initanime("clawc", 4, 48, 24)
  initanime("clawc_recov", 3, 48, 24)
  initanime("dead", 10, 24, 24)
  initanime("descend", 2, 24, 23)
  initanime("evade", 1, 24, 24)
  initanime("idle", 4, 24, 24)
  initanime("midair", 2, 24, 24)
  initanime("run", 8, 24, 24)
  -- Create hitboxes
  hitbox = {
    body = initresource(
      gamedata.hitbox, coolision.createaxisbox, -width, -height, width * 2,
      height * 2, gamedata.hitboxtypes.allybody
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
  }
  gamedata.global.control.shalltear = coroutine.create(control.begin)
end

-- Global API
function shalltear.add(gamedata, x, y)
  local id = initresource(gamedata.actor, function(act, id)
    act.x[id] = x
    act.y[id] = y
    act.width[id] = width
    act.height[id] = height
    act.vx[id] = 0
    act.vy[id] = 0
    act.face[id] = 1

    act.health[id] = 8
    act.stamina[id] = 0
    act.invincibility[id] = 0
    act.action[id] = coroutine.create(action.idle)
  end)
  table.insert(entities, id)
  return id
end

function shalltear.control()
  return coroutine.create(control.idle)
end
