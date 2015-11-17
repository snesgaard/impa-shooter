local duration = 5
local maxbig = 5
local maxsmall = 7
local bsize = 3
local ssize = 2

local active = {}

healthdisplay = {}

function healthdisplay.add(gamedata, id)
  active[id] = gamedata.system.time
end

function healthdisplay.remove(id)
  active[id] = nil
end

function healthdisplay.clear()
  active = {}
end

function healthdisplay.update(gamedata)
  local ct = gamedata.system.time
  for id, t in pairs(active) do
    if ct - t > duration then active[id] = nil end
  end
end

function healthdisplay.draw(gamedata)
  local act = gamedata.actor
  for id, _ in pairs(active) do
    gfx.setColor(138, 7, 7)
    local x = math.floor(act.x[id])
    local y = math.floor(act.y[id])
    local h = math.floor(act.height[id] * 1.4)
    local hp = act.health[id] - (act.damage[id] or 0)
    local srender = math.max(0, math.floor((hp - 1) / maxbig))
    local brender = math.max(0, hp - srender * maxbig)
    for dx = 1, brender do
      local sx = (bsize + 2)
      local tx = x + dx * sx - sx * (maxbig + 1) * 0.5
      gfx.rectangle("fill", tx, y + h, bsize, bsize)
    end
    local remaining = srender > 0 and maxbig - brender or 0
    --gfx.setColor(25, 15, 100)
    gfx.setColor(150, 120, 20)
    for dx = 1, remaining do
      local sx = (bsize + 2)
      local tx = x + (dx + brender) * sx - sx * (maxbig + 1) * 0.5
      gfx.rectangle("fill", tx, y + h, bsize, bsize)
    end
    gfx.setColor(100, 0, 50)
    local sy = y + h + bsize + 2
    local dy = bsize + 2
    while srender >= 0 do
      local count = srender - math.max(0, srender - maxsmall)
      for dx = 1, count do
        local sx = (ssize + 1)
        local tx = x + dx * sx - sx * (maxsmall + 1) * 0.5 + 1
        gfx.rectangle("fill", tx, sy, ssize, ssize)
      end
      srender = srender - maxsmall
      sy = sy + dy
    end
  end
end
