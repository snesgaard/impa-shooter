loaders = loaders or {}

camera = {}

function loaders.camera(gamedata)
  --gamedata.global.control.camera
end

function camera.setpos(gamedata, x, y)
  gamedata.visual.x = x
  gamedata.visual.y = y
end

local duration = 0.1
local amp = 1
local freq = 160
function camera.hitshaker(pid)
  return coroutine.create(function(gamedata, combatreq)
    while true do
      while true do
        local c = combatreq[pid] or {}
        local b = false
        for _, v in pairs(c) do
          if v.dmg > 1 then
            amp = 2
            duration = 0.15
            b = true
          else
            amp = 1
            duration = 0.1
            b = true
          end
        end
        if b then break end
        gamedata, combatreq = coroutine.yield(0, 0)
      end
      local t = gamedata.system.time
      local timer = misc.createtimer(gamedata, duration)
      local dy = -amp
      local ddy = amp * 0.5
      while timer(gamedata) do
        dy = dy + ddy
        if math.abs(dy) >= amp then ddy = -ddy end
        gamedata, combatreq = coroutine.yield(0, dy)
      end
    end
  end)
end

function camera.track(pid)
  local x = 0
  local y = 0
  return coroutine.create(function(gamedata)
    while true do
      x = gamedata.actor.x[pid]
      y = gamedata.actor.y[pid]
      coroutine.yield(x, y)
    end
  end)
end
