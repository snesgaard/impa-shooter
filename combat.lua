require "math"

-- Table which will contain values related to the combat engine
combat = {}

-- Damange is calcuated based on defensive values
combat.calculatedamage = function(damage, soak, reduce, invicibility)
  if invicibility and invicibility > 0 then return 0 end

  local d = damage
  local s = soak
  local r = reduce
  return math.floor(math.max(0, (d - s)) * r)
 end

-- General update routine for combat related events
combat.setstat = function(current, max)
  return math.min(max, current)
end

combat.singledamagecall = function(dmgfunc)
  local cache = {}
  local checkcache = function(this, other)
    if not cache[other] then return this, other end
  end
  local insertcache = function(this, other)
    cache[other] = love.timer.getTime()
    return this, other
  end
  return functional.monadcompose(checkcache, dmgfunc, insertcache)
end

combat.activeboxsequence = function(
  gamedata, id, boxid, dmg, x, y, w, h, pretime, attime, posttime
)
  -- Create timers
  local pretimer = misc.createtimer(gamedata.system.time, pretime)
  local hittimer = misc.createtimer(gamedata.system.time, attime)
  local posttimer = misc.createtimer(gamedata.system.time, posttime)
  while pretimer(gamedata.system.time) do coroutine.yield() end
  -- Register hitbox
  local dmgfunc = combat.singledamagecall(
    function(this, other)
      if other.applydamage then
        local x = this.x + this.w * 0.5
        local y = this.y - this.h * 0.5
        other.applydamage(this.id, x, y, dmg)
      end
      return this, other
    end
  )
  gamedata.hitbox[id][boxid] = coolision.newAxisBox(
    id, 0, 0, w, h, gamedata.hitboxtypes.allyactive,
    gamedata.hitboxtypes.enemybody, dmgfunc
  )
  gamedata.hitboxsync[id][boxid] = {
    x = x, y = y
  }
  while hittimer(gamedata.system.time) do coroutine.yield() end
  -- Clean hitbox
  gamedata.hitbox[id][boxid] = nil
  gamedata.hitboxsync[id][boxid] = nil
  while posttimer(gamedata.system.time) do coroutine.yield() end
end

return combat
