require "actor"
require "entity"
require "bullet"

local keybuffer = {
  [" "] = 0.3
}

local latchtable = {

}

local function pressed(f, k)
  local t = f.keyboard[k] or -1e300
  local l = latchtable[k] or -1e300
  local buffer = keybuffer[k] or 0.1
  return (t > l) and (love.timer.getTime() - t < buffer)
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

--Impa
impa = actor.new()

--Idle state
local idleid = "idle"
fsm.vertex(impa.control, idleid,
  function(context, framedata)
    local a = context.animations[idleid]
    a:update(framedata.dt)
  end,
  function(c)
    c.entity.vx = 0
  end
)
impa.visual[idleid] = function(context)
  local a = context.animations[idleid]
  actor.drawsprite(context.entity, a)
  --drawcentered(context, a)
  --a:draw(context.entity.x, context.entity.y, 0, 1, -1)
end
--Walk state
local walkid = "walk"
fsm.vertex(impa.control, walkid,
  function(c, f)
    local a = c.animations[walkid]
    a:update(f.dt)

    local r = love.keyboard.isDown("right")
    if r then
      c.entity.vx = 75
      c.entity.face = "right"
    else
      c.entity.vx = -75
      c.entity.face = "left"
    end
   end,
  function(c)
    local a = c.animations[walkid]
    a:reset()
  end
)
impa.visual[walkid] = function(c)
  local a = c.animations[walkid]
  local w = a:getWidth()
  local h = a:getHeight()
  actor.drawsprite(c.entity, a)
  --drawcentered(c, a)
  --a:draw(c.entity.x - w / 2, - c.entity.y - h / 2)
end
--Fire state
local fireid = "fire"

fsm.vertex(impa.control, fireid,
  function(c, f)
    local a = c.animations[fireid]
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
    local a = c.animations[fireid]
    c._do_fire = true
    a:setMode("once")
    a:reset()
    a:play()
    c.entity.vx = 0
    c.entity.face = turnface(c, f)
  end
)
impa.visual[fireid] = function(c)
  local a = c.animations[fireid]
  actor.drawsprite(c.entity, a)
end

-- Arial fire state
local arialfireid = "arialfire"
fsm.vertex(impa.control, arialfireid,
  function(c, f)
    local a = c.animations[arialfireid]
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
    end

    local r = love.keyboard.isDown("right")
    local l = love.keyboard.isDown("left")
    if r and not l then
      c.entity.vx = 50
    elseif l and not r then
      c.entity.vx = -50
    else
      c.entity.vx = 0
    end
  end,
  function(c, f)
    local a = c.animations[arialfireid]
    c._do_fire = true
    a:setMode("once")
    a:reset()
    a:play()
    c.entity.face = turnface(c, f)
  end
)
impa.visual[arialfireid] = function(c)
  local a = c.animations[arialfireid]
  actor.drawsprite(c.entity, a)
end

-- Jump state
local jumpid = "jump"
fsm.vertex(impa.control, jumpid,
  function(c, f)
    local a = c.animations[jumpid]
    a:update(f.dt)
  end,
  function(c)
    c.entity.vy = 200
  end
)
impa.visual[jumpid] = function(c)
  local a = c.animations[jumpid]
  actor.drawsprite(c.entity, a)
end
-- Ascend state
local ascendid = "ascend"
fsm.vertex(impa.control, ascendid,
  function(c, f)
    local a = c.animations[ascendid]
    a:update(f.dt)

    local r = love.keyboard.isDown("right")
    local l = love.keyboard.isDown("left")
    if r and not l then
      c.entity.vx = 50
      c.entity.face = "right"
    elseif l and not r then
      c.entity.vx = -50
      c.entity.face = "left"
    else
      c.entity.vx = 0
    end
  end
)

impa.visual[ascendid] = function(c)
  local a = c.animations[ascendid]
  actor.drawsprite(c.entity, a)
end

-- Descend state
local descendid = "descend"
fsm.vertex(impa.control, descendid,
  function(c, f)
    local a = c.animations[descendid]
    a:update(f.dt)

    local r = love.keyboard.isDown("right")
    local l = love.keyboard.isDown("left")
    if r and not l then
      c.entity.vx = 50
      c.entity.face = "right"
    elseif l and not r then
      c.entity.vx = -50
      c.entity.face = "left"
    else
      c.entity.vx = 0
    end
  end
)

impa.visual[descendid] = function(c)
  local a = c.animations[descendid]
  actor.drawsprite(c.entity, a)
end

-- Evade state
local evadeid = "evade"
fsm.vertex(impa.control, evadeid,
  function(c, f)
    local a = c.animations[evadeid]
    a:update(f.dt)

    local e = c.entity
    if e.face == "right" then
      e.vx = 200
    elseif e.face == "left" then
      e.vx = -200
    else
      error("Face should be left or right")
    end
    e.vy = 0

    if c.sample() then
      local t = love.timer.getTime()
      c.sample = function() return love.timer.getTime() - t > 0.05 end
      table.insert(c.trail, {face = e.face, x = e.x, y = e.y})
    end
  end,
  function(c, f)
    local t = love.timer.getTime()
    c.evade_done = function() return love.timer.getTime() - t > 0.2 end

    c.trail = {}
    c.sample = function() return love.timer.getTime() - t > 0.05 end

    c.entity.face = turnface(c, f)
  end
)

impa.visual[evadeid] = function(c)
  local a = c.animations[evadeid]
  love.graphics.setColor(120, 0, 120, 200)
  table.foreach(c.trail, function(_, e) actor.drawsprite(e, a) end)
  love.graphics.setColor(255, 255, 255, 255)
  actor.drawsprite(c.entity, a)
end

--Edges
fsm.connect(impa.control, idleid).to(walkid).when(
  function(c, f)
    local l = love.keyboard.isDown("left")
    local r = love.keyboard.isDown("right")
    if xor(l, r) then return 1 end
  end
)
fsm.connect(impa.control, walkid).to(idleid).when(
  function(c, f)
    local l = love.keyboard.isDown("left")
    local r = love.keyboard.isDown("right")
    if not xor(l, r) then return 1 end
  end
)
fsm.connect(impa.control, walkid, idleid).to(fireid).when(
  function(c, f)
    if pressed(f, "a") then
      latch("a")
      return 2
    end
  end
)

fsm.connect(impa.control, fireid).to(idleid).when(
  function(c, f)
    local a = c.animations[fireid]
    if not a.playing then return 4 end
  end
)

fsm.connect(impa.control, idleid, walkid).to(jumpid).when(
  function(c, f)
    if pressed(f, ' ') then
      latch(' ')
      return 3
    end
  end
)

fsm.connectall(impa.control, ascendid).except(descendid, evadeid, arialfireid).when(
  function(c, f)
    if not c.entity.ground and c.entity.vy > 0 then
      return 10
    end
  end
)

fsm.connectall(impa.control, descendid).except(ascendid, evadeid, arialfireid).when(
  function(c, f)
    if not c.entity.ground and c.entity.vy <= 0 then
      return 10
    end
  end
)

fsm.connect(impa.control, ascendid, descendid).to(idleid).when(
  function(c, f)
    if c.entity.ground then
      return 2
    end
  end
)

fsm.connect(impa.control, ascendid).to(descendid).when(
  function(c, f)
    if c.entity.vy < 0 then return 1 end
  end
)

fsm.connectall(impa.control, evadeid).when(
  function(c, f)
    if pressed(f, 'lshift') then
      latch('lshift')
      return 20
    end
  end
)

fsm.connect(impa.control, evadeid).to(idleid).when(
  function(c, f)
    if not c.evade_done or c.evade_done() then return 1 end
  end
)

fsm.connect(impa.control, ascendid, descendid).to(arialfireid).when(
  function(c, f)
    if pressed(f, "a") then
      latch("a")
      return 2
    end
  end
)

fsm.connect(impa.control, arialfireid).to(ascendid).when(
  function(c, f)
    local a = c.animations[arialfireid]
    local e = c.entity
    if not a.playing and not e.ground then return 1 end
  end
)

fsm.connect(impa.control, arialfireid).to(idleid).when(
  function(c, f)
    local a = c.animations[arialfireid]
    local e = c.entity
    if not a.playing and e.ground then return 1 end
  end
)

--Init
impa.context.animations = {
  idle = loadanimation("res/idle.png", 48, 48, 0.2, 0),
  walk = loadanimation("res/walk.png", 48, 48, 0.15, 0),
  fire = loadanimation("res/fire.png", 48, 48, 0.05, 0),
  jump = loadanimation("res/idle.png", 48, 48, 0.2, 0), -- Should be jump.png when ready
  ascend = loadanimation("res/ascend.png", 48, 48, 0.15, 2),
  descend = loadanimation("res/descend.png", 48, 48, 0.15, 2),
  evade = loadanimation("res/evade.png", 48, 48, 0.15, 2),
  arialfire = loadanimation("res/arialfire.png", 48, 48, 0.05, 0),
}
impa.context.entity = newEntity(100, -100, 4, 12)

impa.control.current = idleid

impa.context.entity.ground = false
impa.context.entity.mapCollisionCallback = function(e, _, _, cx, cy)
  e.ground = (cy and cy < e.y)
end

return impa
