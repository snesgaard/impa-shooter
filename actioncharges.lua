require "math"

require "actor"

-- Utilities
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

local function drawcharges(n)
  love.graphics.setColor(0, 100, 255, 255)
  for x = 1, n do
    love.graphics.circle("fill", (x - 1) * 50 + 30, 30, 20, 20)
  end
  love.graphics.setColor(255, 255, 255, 255)
end

local maxcharges = 4
local chargetime = 1

local ac = actor.new()

local basedraw = function(c)
  love.graphics.push()
  love.graphics.origin()
  drawcharges(c.charges)
  love.graphics.pop()
end

-- Idle state
local idleid = "idle"
ac.visual[idleid] = basedraw

-- Charging state
local chargingid = "charging"
fsm.vertex(ac.control, chargingid,
  function(c, f)
  end,
  function(c, f)
    c.chargestart = love.timer.getTime()
  end
)
ac.visual[chargingid] = function(c)
  love.graphics.push()
  love.graphics.origin()
  drawcharges(c.charges)
  local w = 190
  local h = 5
  local y = 50 + h
  local x = 10
  local s = (love.timer.getTime() - c.chargestart) / chargetime
  love.graphics.rectangle("fill", x, y, w * s, h)
  love.graphics.pop()
end

-- Charge state
local chargeid = "charge"
fsm.vertex(ac.control, chargeid,
  function(c, f)
  end,
  function(c, f)
    local ch = c.charges
    if ch < maxcharges then c.charges = ch + 1 end
  end
)
ac.visual[chargeid] = basedraw

-- Discharge state
local dischargeid = "discharge"
fsm.vertex(ac.control, dischargeid,
  function(c, f)
  end,
  function(c, f)
    c.charges = math.max(c.charges - 1, 0)
  end
)
ac.visual[dischargeid] = basedraw

-- Edges
fsm.connect(ac.control, idleid, chargingid).to(dischargeid).when(
  function(c, f)
    if pressed(f, "e") and c.charges > 0 then
      latch("e")
      return 2
    end
  end
)
fsm.connect(ac.control, dischargeid).to(idleid).when(
  function(c, f)
    return 1
  end
)
fsm.connect(ac.control, idleid).to(chargingid).when(
  function(c, f)
    if c.charges < maxcharges then return 1 end
  end
)
fsm.connect(ac.control, chargingid).to(chargeid).when(
  function(c, f)
    if love.timer.getTime() - c.chargestart > chargetime then return 1 end
  end
)
fsm.connect(ac.control, chargeid).to(idleid).when(
  function(c, f)
    return 1
  end
)

-- Init
ac.context.charges = maxcharges

ac.control.current = idleid

return ac
