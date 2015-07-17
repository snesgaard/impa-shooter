require "math"
require "actor"

local hitbox = {
  callback = {
    create = function(dmgfunc)
      local cache = {}
      local checkcache = function(other, box)
        local id = other.globalid()
        if not cache[id] then return other, box end
      end
      local insertcache = function(other, box)
        local id = other.globalid()
        cache[id] = love.timer.getTime()
        return other, box
      end
      return functional.monadcompose(checkcache, dmgfunc, insertcache)
    end
  }
}

function newMobolee(globaltable, id, sx, sy)
  local mobo = actor.new()

  -- Defines
  local stateid = {
    idle = "idle",
    walk = "walk",
    hit = "hit",
    prehit = "prehit",
    dead = "dead"
  }
  local walkspeed = function() return 25 end
  local walkduration = 2
  local idleduration = 2
  local jumpspeed = 150

  local maxstamina = 10
  local staminaregenrate = 10
  local staminacost = {
    hit = 15,
    jump = 15
  }


  local agro = 1

  -- Idle state
  fsm.vertex(mobo.control, stateid.idle,
    function(c, f)
      local a = c.animations[stateid.idle]
      a:update(f.dt)
    end,
    function(c, f)
      c.entity.vx = 0
      c.idlestart = love.timer.getTime()
    end
  )
  mobo.visual[stateid.idle] = function(c)
    local a = c.animations[stateid.idle]
    actor.drawsprite(c.entity, a)
  end

  -- Walk state
  fsm.vertex(mobo.control, stateid.walk,
    function(c, f)
      local a = c.animations[stateid.walk]
      a:update(f.dt)

      local p = c.pscan
      c.entity.face = "right"
      if p.x - c.entity.x < 0 then c.entity.face = "left" end
      if c.entity.face == "right" then
        c.entity.vx = walkspeed()
      elseif c.entity.face == "left" then
        c.entity.vx = -walkspeed()
      else
        error("Unknown face" .. c.entity.face)
      end
      if c.entity.wall and c.entity.ground and globaltable.stamina[id] > 0 then
        c.entity.vy = jumpspeed
        globaltable.stamina[id] = globaltable.stamina[id] - staminacost.jump
      end
    end,
    function(c, f)
      c.walkstart = love.timer.getTime()
    end
  )
  mobo.visual[stateid.walk] = function(c)
    local a = c.animations[stateid.walk]
    actor.drawsprite(c.entity, a)
  end

  -- Hitboxes for each state
  -- Start by specific state hitboxes
  local hitdamage = function(other, box)
    local x = box.x
    local y = box.y
    if other.applydamage then other.applydamage(x, y, 1) end
    return other, box
  end
  local hitframes = {
    [3] = coolision.newAxisBox(-17, 12, 23, 11, hitcallback),
    [4] = coolision.newAxisBox(2, 14, 14, 24, hitcallback)
  }

  --Hit state
  local function animationdone(c, id)
    return not c.animations[id].playing
  end
  fsm.vertex(mobo.control, stateid.hit,
    function(c, f)
      if not animationdone(c, stateid.prehit) then
        local a = c.animations[stateid.prehit]
        a:update(f.dt)
      else
        local a = c.animations[stateid.hit]
        a:update(f.dt)
      end
    end,
    function(c, f)
      c.entity.vx = 0
      c.entity.face = "right"
      if c.phit.x - c.entity.x < 0 then c.entity.face = "left" end

      local a = c.animations[stateid.hit]
      a:setMode("once")
      a:reset()
      a:play()

      local prea = c.animations[stateid.prehit]
      prea:setMode("once")
      prea:reset()
      prea:play()

      -- Reset hitcache
      local callback = hitbox.callback.create(hitdamage)
      table.foreach(hitframes, function(_, hb)
        hb.hitcallback = callback
      end)
      -- Drain stamina
      globaltable.stamina[id] = globaltable.stamina[id] - staminacost.hit
    end,
    function(c, f)
      local t = love.timer.getTime()
    end
  )
  mobo.visual[stateid.hit] = function(c)
    if not animationdone(c, stateid.prehit) then
      local a = c.animations[stateid.prehit]
      actor.drawsprite(c.entity, a)
    else
      local a = c.animations[stateid.hit]
      actor.drawsprite(c.entity, a)
    end
  end

  fsm.connectall(mobo.control, stateid.walk).except(stateid.hit).when(
    function(c, f)
      local p = c.pscan
      local h = c.phit
      if p and not h then return 1 end
    end
  )
  fsm.connectall(mobo.control, stateid.idle).except(stateid.hit).when(
    function(c, f)
      local p = c.pscan
      local h = c.phit
      if not p or h then return 1 end
    end
  )
  fsm.connectall(mobo.control, stateid.hit).when(
    function(c, f)
      if c.phit and globaltable.stamina[id] > 0 then return 2 end
    end
  )
  fsm.connect(mobo.control, stateid.hit).to(stateid.idle).when(
    function(c, f)
      local a = c.animations[stateid.hit]
      if not a.playing then return 1 end
    end
  )
  fsm.connectall(mobo.control, stateid.dead).when(
    function(c, f)
      local hp = globaltable.health[id]
      if hp <= 0 then return 10 end
    end
  )

  -- Hitbox definitions
  mobo.hitbox[stateid.hit] = function(c)
    local e = c.entity

    --local b = coolision.newAxisBox(e.x - e.wx, e.y + e.wy, e.wx * 2, e.wy * 2)
    local a = c.animations[stateid.hit]
    local b = table.shallowcopy(hitframes[a:getCurrentFrame()])
    if b then
      if e.face == "left" then coolision.vflipaxisbox(b) end
      b.x = b.x + e.x
      b.y = b.y + e.y

      local seek = actor.types.allybody
      local hail = actor.types.enemymelee
      --local b = coolision.newAxisBox(orgb.x + e.x, orgb.y + e.y, orgb.w, orgb.h)
      return actor.taggedbox(b, hail, seek)
    end
  end
  local bodyhitbox = function(c)
    local e = c.entity
    local s
    if e.face == "right" then s = 1 else s = -1 end
    local call = function(other)

    end
    local b = coolision.newAxisBox(e.x - e.wx, e.y + e.wy, e.wx * 2, e.wy * 2, call)
    b.applydamage = function(x, y, d)
      local cx = e.x - x
      local cs
      if e.face == "left" then cs = -1 else cs = 1 end
      local s
      if cx * cs > 0 then s = 2.0 else s = 1.0 end
      local soak = globaltable.soak[id]
      local reduce = globaltable.reduce[id]
      local fd = combat.calculatedamage(d, soak, reduce * s)

      globaltable.health[id] = globaltable.health[id] - fd
      return fd
    end
    local hail = actor.types.enemybody
    return actor.taggedbox(b, hail)
  end
  local playerscanbox = function(c)
    local e = c.entity
    local width = 250 * agro
    local height = 75 * agro
    local call = function(other)
      c.pscan = {
        x = other.x + other.w * 0.5,
        y = other.y + other.h * 0.5
      }
    end

    local b = coolision.newAxisBox(e.x - width, e.y + height, width * 2, height * 2, call)
    local seek = actor.types.allybody
    return actor.taggedbox(b, nil, seek)
  end
  local attackscanbox = function(c)
    local e = c.entity
    local width = 15 * agro
    local height = 15 * agro
    local call = function(other)
      c.phit = {
        x = other.x + other.w * 0.5,
        y = other.y + other.h * 0.5
      }
    end

    local b = coolision.newAxisBox(e.x - width, e.y + height, width * 2, height * 2, call)
    local seek = actor.types.allybody
    return actor.taggedbox(b, nil, seek)
  end

  -- Set all states to generate the body hitbox for mobolee
  table.foreach(stateid, function(k, v)
    local funcs = {bodyhitbox, attackscanbox, playerscanbox, mobo.hitbox[v]}
    mobo.hitbox[v] = functional.invfmap(unpack(funcs))
  end)
  -- Set cleanup function for all one frame data in context
  local function clean(c)
    c.pscan = nil
    c.phit = false
    c.entity.ground = false
    c.entity.wall = false
  end
  -- State update for regenerating stamina
  local stamwavelength = 1.0 / staminaregenrate
  local function updatestamina(c)
    local s = globaltable.stamina[id]
    globaltable.stamina[id] = math.min(maxstamina, s + stamwavelength)
  end
  actor.globalupdate(mobo, updatestamina, clean)

  mobo.context.animations = {
    [stateid.walk] = loadanimation("res/mobolee/walk.png", 48, 48, 0.2, 0),
    [stateid.idle] = loadanimation("res/mobolee/idle.png", 48, 48, 0.4, 2),
    [stateid.hit] = loadanimation("res/mobolee/hit.png", 48, 48, 0.05, 0),
    [stateid.prehit] = loadanimation("res/mobolee/prehit.png", 48, 48, 0.075, 0),
  }
  mobo.context.entity = newEntity(sx, sy, 6, 12)
  mobo.context.entity.face = "left"
  mobo.context.entity.mapCollisionCallback = function(e, _, _, cx, cy)
    e.ground = (cy and cy < e.y)
    e.wall = (cx ~= nil)
  end
  -- TODO: Move this to the global stats table
  --  mobo.context.defense = combat.newdefensetable(0, 1)
  --mobo.context.hp = 8
  --mobo.context.stamina = 0

  globaltable.soak[id] = 0
  globaltable.reduce[id] = 1
  globaltable.health[id] = 8
  globaltable.stamina[id] = 0

  -- As such
  --setdataentry(data, "health", "mobo", 8)

  fsm.traverse(mobo.control, stateid.idle, mobo.context, {})

  return mobo
end
