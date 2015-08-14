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

return combat
