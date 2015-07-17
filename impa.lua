require "actor"
require "entity"
require "bullet"

local keybuffer = {
  [" "] = 0.15
}

local latchtable = {

}

local function pressed(f, k)
  local t = f.keyboard[k] or -1e300
  local l = latchtable[k] or -1e300
  local buffer = keybuffer[k] or 0.1
  return (t > l) and (f.time - t < buffer)
end

local function latch(k)
  latchtable[k] = love.timer.getTime()
end

-- Utility
local function turnface(c, f)
  local r = love.keyboard.isDown("right")
  local l = love.keyboard.isDown("left")
  if r and not l then return "right" end
  if l and not r then return "left" end
  return c.entity.face
end

-- Defines
local groundbuffer = 0.10
local hurtduration = 0.30
local evadesampleperiod = 0.025
local evadeduration = 0.2
local movespeed = 75
local evadespeed = 150
local stateid = {
  idle = "idle",
  walk = "walk",
  fire = "fire",
  arialfire = "arialfire",
  jump = "jump",
  ascend = "ascend",
  descend = "descend",
  evade = "evade",
  hurt = "hurt",
}
local maxhealth = 4

function newimpa(globaldata, id, x, y)
  --Impa
  impa = actor.new()

  --Idle state
  fsm.vertex(impa.control, stateid.idle,
    function(context, framedata)
      local a = context.animations[stateid.idle]
      a:update(framedata.dt)
    end,
    function(c)
      c.entity.vx = 0
    end
  )
  impa.visual[stateid.idle] = function(context)
    local a = context.animations[stateid.idle]
    actor.drawsprite(context.entity, a)
    --drawcentered(context, a)
    --a:draw(context.entity.x, context.entity.y, 0, 1, -1)
  end
  --Walk state
  fsm.vertex(impa.control, stateid.walk,
    function(c, f)
      local a = c.animations[stateid.walk]
      a:update(f.dt)

      local r = love.keyboard.isDown("right")
      if r then
        c.entity.vx = movespeed
        c.entity.face = "right"
      else
        c.entity.vx = -movespeed
        c.entity.face = "left"
      end
     end,
    function(c)
      local a = c.animations[stateid.walk]
      a:reset()
    end
  )
  impa.visual[stateid.walk] = function(c)
    local a = c.animations[stateid.walk]
    local w = a:getWidth()
    local h = a:getHeight()
    actor.drawsprite(c.entity, a)
    --drawcentered(c, a)
    --a:draw(c.entity.x - w / 2, - c.entity.y - h / 2)
  end
  --Fire state
  fsm.vertex(impa.control, stateid.fire,
    function(c, f)
      local a = c.animations[stateid.fire]
      a:update(f.dt)
      if a:getCurrentFrame() > 1 and c._do_fire then
        c._do_fire = false
        local e = c.entity
        if e.face == "right" then
          table.insert(_global.actors, newBullet(e.x + 15, e.y + 1, 1, "right"))
          table.insert(_global.actors, newGunExhaust(e.x + 15, e.y + 1, "right"))
        elseif e.face == "left" then
          table.insert(_global.actors, newBullet(e.x - 15, e.y + 1, -1, "left"))
          table.insert(_global.actors, newGunExhaust(e.x - 15, e.y + 1, "left"))
        else
          error("Face not defined")
        end
      elseif a:getCurrentFrame() <= 1 then
        c.entity.face = turnface(c, f)
      end
    end,
    function(c, f)
      local a = c.animations[stateid.fire]
      c._do_fire = true
      a:setMode("once")
      a:reset()
      a:play()
      c.entity.vx = 0
      c.entity.face = turnface(c, f)
    end
  )
  impa.visual[stateid.fire] = function(c)
    local a = c.animations[stateid.fire]
    actor.drawsprite(c.entity, a)
  end

  -- Arial fire state
  fsm.vertex(impa.control, stateid.arialfire,
    function(c, f)
      local a = c.animations[stateid.arialfire]
      a:update(f.dt)
      if a:getCurrentFrame() > 1 and c._do_fire then
        c._do_fire = false
        local e = c.entity
        if e.face == "right" then
          table.insert(_global.actors, newBullet(e.x + 15, e.y + 1, 1, "right"))
          table.insert(_global.actors, newGunExhaust(e.x + 15, e.y + 1, "right"))
        elseif e.face == "left" then
          table.insert(_global.actors, newBullet(e.x - 15, e.y + 1, -1, "left"))
          table.insert(_global.actors, newGunExhaust(e.x - 15, e.y + 1, "left"))
        else
          error("Face not defined")
        end
      elseif a:getCurrentFrame() <= 1 then
        c.entity.face = turnface(c, f)
      end

      local r = love.keyboard.isDown("right")
      local l = love.keyboard.isDown("left")
      if r and not l then
        c.entity.vx = movespeed
      elseif l and not r then
        c.entity.vx = -movespeed
      else
        c.entity.vx = 0
      end
    end,
    function(c, f)
      local a = c.animations[stateid.arialfire]
      c._do_fire = true
      a:setMode("once")
      a:reset()
      a:play()
      c.entity.face = turnface(c, f)
    end
  )
  impa.visual[stateid.arialfire] = function(c)
    local a = c.animations[stateid.arialfire]
    actor.drawsprite(c.entity, a)
  end

  -- Jump state
  fsm.vertex(impa.control, stateid.jump,
    function(c, f)
      local a = c.animations[stateid.jump]
      a:update(f.dt)
    end,
    function(c)
      c.entity.vy = 200
    end
  )
  impa.visual[stateid.jump] = function(c)
    local a = c.animations[stateid.jump]
    actor.drawsprite(c.entity, a)
  end
  -- Ascend state
  fsm.vertex(impa.control, stateid.ascend,
    function(c, f)
      local a = c.animations[stateid.ascend]
      a:update(f.dt)

      local r = love.keyboard.isDown("right")
      local l = love.keyboard.isDown("left")
      if r and not l then
        c.entity.vx = movespeed
        c.entity.face = "right"
      elseif l and not r then
        c.entity.vx = -movespeed
        c.entity.face = "left"
      else
        c.entity.vx = 0
      end
    end
  )

  impa.visual[stateid.ascend] = function(c)
    local a = c.animations[stateid.ascend]
    actor.drawsprite(c.entity, a)
  end

  -- Descend state
  fsm.vertex(impa.control, stateid.descend,
    function(c, f)
      local a = c.animations[stateid.descend]
      a:update(f.dt)

      local r = love.keyboard.isDown("right")
      local l = love.keyboard.isDown("left")
      if r and not l then
        c.entity.vx = movespeed
        c.entity.face = "right"
      elseif l and not r then
        c.entity.vx = -movespeed
        c.entity.face = "left"
      else
        c.entity.vx = 0
      end
    end
  )

  impa.visual[stateid.descend] = function(c)
    local a = c.animations[stateid.descend]
    actor.drawsprite(c.entity, a)
  end

  -- Evade state
  fsm.vertex(impa.control, stateid.evade,
    function(c, f)
      local a = c.animations[stateid.evade]
      a:update(f.dt)

      local e = c.entity
      if e.face == "right" then
        e.vx = evadespeed
      elseif e.face == "left" then
        e.vx = -evadespeed
      else
        error("Face should be left or right")
      end
      e.vy = 0

      if c.sample() then
        local t = love.timer.getTime()
        c.sample = function() return love.timer.getTime() - t > evadesampleperiod end
        table.insert(c.trail, {face = e.face, x = e.x, y = e.y})
      end
    end,
    function(c, f)
      local t = love.timer.getTime()
      c.evade_done = function() return love.timer.getTime() - t > evadeduration end

      c.trail = {}
      c.sample = function() return love.timer.getTime() - t > evadesampleperiod end

      c.entity.face = turnface(c, f)

      -- Active invunlerability by
      globaldata.invicibility[id] = globaldata.invicibility[id] + 1
    end,
    function(c, f)
      globaldata.invicibility[id] = globaldata.invicibility[id] - 1
    end
  )

  impa.visual[stateid.evade] = function(c)
    local a = c.animations[stateid.evade]
    love.graphics.setColor(120, 0, 120, 200)
    table.foreach(c.trail, function(_, e) actor.drawsprite(e, a) end)
    love.graphics.setColor(255, 255, 255, 255)
    actor.drawsprite(c.entity, a)
  end

  -- Hurt state
  fsm.vertex(impa.control, stateid.hurt,
    function(c, f)
      local a = c.animations[stateid.hurt]
      a:update(f.dt)
    end,
    function(c, f)
      c.hurtstart = love.timer.getTime()
      c.entity.vx = 0
      --c.entity.vy = 0
      c.hit = false
    end
  )
  local hurtblinkfrequency = 10.0 * math.pi * 2
  impa.visual[stateid.hurt] = function(c)
    local dt = love.timer.getTime() - c.hurtstart
    if math.sin(hurtblinkfrequency * dt) > 0 then
      local a = c.animations[stateid.hurt]
      actor.drawsprite(c.entity, a)
    end
  end

  -- Hitbox
  local basehitbox = function(c)
    local e = c.entity
    local applydamage = function(x, y, dmg)
      local soak = globaldata.soak[id]
      local reduce = globaldata.reduce[id]
      local inv = globaldata.invicibility[id]
      local fd = combat.calculatedamage(dmg, soak, reduce, inv)
      if fd > 0 then
        health.reduce(fd)
        c.hit = true
      end
      return fd
    end
    local b = coolision.newAxisBox(e.x - e.wx, e.y + e.wy, e.wx * 2, e.wy * 2, call)
    b.applydamage = applydamage
    local hail = actor.types.allybody

    return {actor.taggedbox(b, hail)}
  end
  table.foreach(stateid,
  function(_, id)
    impa.hitbox[id] = basehitbox
  end
  )

  --Edges
  fsm.connect(impa.control, stateid.idle).to(stateid.walk).when(
    function(c, f)
      local l = love.keyboard.isDown("left")
      local r = love.keyboard.isDown("right")
      if xor(l, r) then return 1 end
    end
  )
  fsm.connect(impa.control, stateid.walk).to(stateid.idle).when(
    function(c, f)
      local l = love.keyboard.isDown("left")
      local r = love.keyboard.isDown("right")
      if not xor(l, r) then return 1 end
    end
  )
  fsm.connect(impa.control, stateid.walk, stateid.idle).to(stateid.fire).when(
    function(c, f)
      if pressed(f, "a") then
        latch("a")
        return 2
      end
    end
  )

  fsm.connect(impa.control, stateid.fire).to(stateid.idle).when(
    function(c, f)
      local a = c.animations[stateid.fire]
      if not a.playing then return 4 end
    end
  )

  fsm.connect(impa.control, stateid.idle, stateid.walk).to(stateid.jump).when(
    function(c, f)
      if pressed(f, ' ') then
        latch(' ')
        c.entity.onground = function() return false end
        return 3
      end
    end
  )

  fsm.connectall(impa.control, stateid.ascend).except(stateid.descend, stateid.evade, stateid.arialfire, stateid.hurt).when(
    function(c, f)
      if not c.entity.onground() and c.entity.vy > 0 then
        return 10
      end
    end
  )

  fsm.connectall(impa.control, stateid.descend).except(stateid.ascend, stateid.evade, stateid.arialfire, stateid.hurt).when(
    function(c, f)
      if not c.entity.onground() and c.entity.vy <= 0 then
        return 10
      end
    end
  )

  fsm.connect(impa.control, stateid.ascend, stateid.descend).to(stateid.idle).when(
    function(c, f)
      if c.entity.onground() then
        return 2
      end
    end
  )

  fsm.connect(impa.control, stateid.ascend).to(stateid.descend).when(
    function(c, f)
      if c.entity.vy < 0 then return 1 end
    end
  )

  fsm.connectall(impa.control, stateid.evade).except(stateid.hurt).when(
    function(c, f)
      if pressed(f, 'lshift') and (not actioncharges or actioncharges.usecharge(1)) then
        latch('lshift')
        return 20
      end
    end
  )

  fsm.connect(impa.control, stateid.evade).to(stateid.idle).when(
    function(c, f)
      if not c.evade_done or c.evade_done() then return 1 end
    end
  )

  fsm.connect(impa.control, stateid.ascend, stateid.descend).to(stateid.arialfire).when(
    function(c, f)
      if pressed(f, "a") then
        latch("a")
        return 2
      end
    end
  )

  fsm.connect(impa.control, stateid.arialfire).to(stateid.ascend).when(
    function(c, f)
      local a = c.animations[stateid.arialfire]
      local e = c.entity
      if not a.playing and not e.onground() then return 1 end
    end
  )

  fsm.connect(impa.control, stateid.arialfire).to(stateid.idle).when(
    function(c, f)
      local a = c.animations[stateid.arialfire]
      local e = c.entity
      if not a.playing and e.onground() then return 1 end
    end
  )

  fsm.connectall(impa.control, stateid.hurt).when(
    function(c, f)
      if c.hit then return 5 end
    end
  )
  fsm.connect(impa.control, stateid.hurt).to(stateid.idle).when(
    function(c, f)
      if love.timer.getTime() - c.hurtstart > hurtduration then return 1 end
    end
  )

  --Init
  impa.context.animations = {
    [stateid.idle] = loadanimation("res/idle.png", 48, 48, 0.2, 0),
    [stateid.walk] = loadanimation("res/walk.png", 48, 48, 0.15, 0),
    [stateid.fire] = loadanimation("res/fire.png", 48, 48, 0.05, 0),
    [stateid.jump] = loadanimation("res/idle.png", 48, 48, 0.2, 0),
    [stateid.ascend] = loadanimation("res/ascend.png", 48, 48, 0.15, 2),
    [stateid.descend] = loadanimation("res/descend.png", 48, 48, 0.15, 2),
    [stateid.evade] = loadanimation("res/evade.png", 48, 48, 0.15, 2),
    [stateid.arialfire] = loadanimation("res/arialfire.png", 48, 48, 0.05, 0),
    [stateid.hurt] = loadanimation("res/hurt.png", 48, 48, 0.05, 0),
  }
  impa.context.entity = newEntity(x, y, 4, 12)

  impa.control.current = stateid.idle

  impa.context.entity.ground = false
  impa.context.entity.onground = function() return false end
  impa.context.entity.mapCollisionCallback = function(e, _, _, cx, cy)
    e.ground = (cy and cy < e.y)
    if cy and cy < e.y then
      local t = love.timer.getTime()
      e.onground = function() return love.timer.getTime() - t < groundbuffer end
    end
  end

  globaldata.health[id] = maxhealth
  globaldata.maxhealth[id] = maxhealth
  globaldata.soak[id] = 0
  globaldata.reduce[id] = 1
  globaldata.invicibility[id] = 0

  return impa
end
