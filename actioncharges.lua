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

local maxcharges = 4
local chargetime = 1
local barh = 5
local barw = 190

local function drawcharges(n, x, y)
  love.graphics.setColor(0, 100, 255, 255)
  for i = 1, n do
    love.graphics.circle("fill", (i - 1) * 50 + x, y, 20, 20)
  end
  love.graphics.setColor(255, 255, 255, 255)
end

local function drawchargeframe(x, y, s)
  love.graphics.setColor(0, 100, 255, 255)
  local w = 2
  love.graphics.translate(x, y)
  love.graphics.rectangle("fill", -w, -w, barw + 2 * w, w)
  love.graphics.rectangle("fill", -w, barh, barw + 2 * w, w)
  love.graphics.rectangle("fill", -w, 0, w, barh)
  love.graphics.rectangle("fill", barw, 0, w, barh)
  love.graphics.rectangle("fill", 0, 0, barw * s, barh)
  love.graphics.origin()
  love.graphics.setColor(255, 255, 255, 255)
end

local ac = actor.new()

local basedraw = function(c)
  love.graphics.push()
  love.graphics.origin()
  drawcharges(c.charges, c.x, c.y)
  drawchargeframe(c.x - 20, c.y + 20 + barh, 0)
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
  drawcharges(c.charges, c.x, c.y)
  local w = barw
  local h = barh
  local y = c.y + 20 + h
  local x = c.x - 20
  local s = (love.timer.getTime() - c.chargestart) / chargetime
  drawchargeframe(x, y, s)
  --love.graphics.rectangle("fill", x, y, w * s, h)
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
--[[
fsm.connect(ac.control, idleid, chargingid).to(dischargeid).when(
  function(c, f)
    if pressed(f, "e") and c.charges > 0 then
      latch("e")
      return 2
    end
  end
)
--]]
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
ac.context.x = 600
ac.context.y = 30


ac.control.current = idleid

-- Global API
actioncharges = {}
actioncharges.usecharge = function(n)
  local c = ac.context
  if c.charges < n then return false end
  c.charges = c.charges - n
  return true
end

return ac
