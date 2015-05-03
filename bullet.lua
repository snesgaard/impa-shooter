require "actor"

function newBullet(x, y, sx, face)
  sx = sx or 1
  -- Bullet
  local bullet = actor.new()
  -- Live state
  local liveid = "live"
  fsm.vertex(bullet.control, liveid,
  function(c, f)
    local a = c.animations[liveid]
    a:update(f.dt)
  end)
  bullet.visual[liveid] = function(c)
    local e = c.entity
    --love.graphics.polygon("fill", p)
    local a = actor.drawsprite(e, c.animations[liveid])
  end
  -- Impact state
  local impactid = "impact"
  fsm.vertex(bullet.control, impactid,
    function(c, f)
      local a = c.animations[impactid]
      a:update(f.dt)
      c.entity.vx = 0
    end,
    function(c, f)
      local a = c.animations[impactid]
      a:setMode("once")
      a:reset()
      a:play()
    end
  )
  bullet.visual[impactid] = function(c)
    local e = c.entity
    --love.graphics.polygon("fill", p)
    local a = actor.drawsprite(e, c.animations[impactid])
  end
  -- Dead state
  local deadid = "dead"
  fsm.connect(bullet.control, liveid).to(impactid).when(function(c, f)
    if love.timer.getTime() - c.spawntime > 1.0 then return 1 end
  end)
  fsm.connect(bullet.control, impactid).to(deadid).when(
    function(c, f)
      local a = c.animations[impactid]
      if not a.playing then return 1 end
    end
  )

  --Init
  bullet.control.current = liveid
  bullet.context.animations = {
    [liveid] = loadanimation("res/bullet.png", 5, 3, 0.05, 0),
    [impactid] = loadanimation("res/bulletimpact.png", 15, 9, 0.025, 0)
  }
  bullet.context.entity = newEntity(x, y, 2.5 * sx, 1, "false")
  bullet.context.entity.face = face
  bullet.context.entity.mapCollisionCallback = function(e, _, _, cx, cy)
    e._do_gravity = (cx or cy)
    if (cx or cy) then bullet.context.spawntime = -100000 end
  end
  bullet.context.spawntime = love.timer.getTime()
  bullet.context.entity.vx = 250 * sx
  bullet.hitbox = function(id, c)
    local e = c.entity
    local call = function()
      c.spawntime = -100000
      print "impact"
    end
    return {coolision.newAxisBox(e.x - e.wx, e.y + e.wy, e.wx * 2, e.wy * 2, call)}
  end
  return bullet
end


function newGunExhaust(x, y, face)
  local ge = actor.new()

  local dx = 5
  if face == "left" then
    dx = -dx
  end

  -- Live state
  local liveid = "live"
  fsm.vertex(ge.control, liveid,
    function(c, f)
      local a = c.animations[liveid]
      a:update(f.dt)
    end,
    function(c, f)
      local a = c.animations[liveid]
      a:setMode("once")
      a:reset()
      a:play()
    end
  )
  ge.visual[liveid] = function(c)
    local a = c.animations[liveid]
    actor.drawsprite({x = x + dx, y = y, face = face}, a)
  end

  -- Dead state
  local deadid = "dead"

  --Edges
  fsm.connect(ge.control, liveid).to(deadid).when(
    function(c, f)
      local a = c.animations[liveid]
      if not a.playing then return 4 end
    end
  )

  --Init
  ge.context.animations = {
    [liveid] = loadanimation("res/gunexhaust.png", 10, 9, 0.05, 0)
  }

  fsm.traverse(ge.control, liveid, ge.context, {})
  return ge
end
