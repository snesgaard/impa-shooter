loaders = loaders or {}

local shaderpath = "res/shaders/monosprite.glsl"

local function inittrail(td, id, time, draw)
  td.time[id] = time
  td.draw[id] = draw
end
local function interpolate(a, b, t)
  return a * (1 - t) + b * t
end
local function vec_interpolate(c1, c2, t)
  local count = math.min(#c1, #c2)
  local c = {}
  for i = 1, count do
    table.insert(c, c1[i] * (1 - t) + c2[i] * t)
  end
  return c
end
function loaders.trail(gamedata)
  local f = io.open(shaderpath, "rb")
  local fstring = f:read("*all")
  f:close()
  gamedata.resource.shaders.monosprite = gfx.newShader(fstring)
end
-- Global API
trail = {}
function trail.update(gamedata)
  for id, time in pairs(gamedata.trail.time) do
    time = time - gamedata.system.dt
    if time < 0 then
      freeresource(gamedata.trail, id)
    else
      gamedata.trail.time[id] = time
    end
  end
end
function trail.add(gamedata, time, draw)
  initresource(gamedata.trail, inittrail, time, draw)
end
function trail.draw(gamedata)
  for id, draw in pairs(gamedata.trail.draw) do
    draw(gamedata.trail.time[id])
  end
end
function trail.chain(...)
  local funtab = {...}
  local f = function(t, x, y, r, sx, sy)
    for _, funk in ipairs(funtab) do
      x, y, r, sx, sy = funk(t, x, y, r, sx, sy)
    end
    return x, y, r, sx, sy
  end
  return f
end
function trail.color(gamedata, atid, ...)
  local atlas = gamedata.resource.atlas[atid]
  local colortab = {...}
  local pc = #colortab - 1 -- Phase count
  local f
  if pc == 0 then
    f = function(t, ...)
      atlas:setColor(unpack(colortab[1]))
      return ...
    end
  else
    f = function(t, ...)
      local p = t * pc
      -- Clamp
      local i = math.max(1, math.min(pc, math.ceil(p)))
      local c1 = colortab[i]
      local c2 = colortab[i + 1]
      local fc = vec_interpolate(c1, c2, p - math.floor(p))
      atlas:setColor(unpack(fc))
      return ...
    end
  end
  return f
end
function trail.scale(...)
  local atlas = gamedata.resource.atlas[atid]
  local stab = {...}
  local pc = #stab - 1
  local f
  if pc == 0 then
    f = function(t, x, y, r, sx, sy)
      local s = stab[1]
      return x, y, r, sx * s, sy * s
    end
  else
    f = function(t, x, y, r, sx, sy)
      local p = t * pc
      -- Clamp
      local i = math.max(1, math.min(pc, math.ceil(p)))
      local s1 = stab[i]
      local s2 = stab[i + 1]
      local fs = interpolate(s1, s2, p - math.floor(p))
      return x, y, r, sx * fs, sy * fs
    end
  end
  return f
end
function trail.drawer(gamedata, sr, life, atid, anid, ft, modfun, mode, to, from)
  local d = animation.draw(gamedata, atid, anid, ft, mode, to, from)
  modfun = modfun or function(t, ...) return ... end
  local f = function(dt, x, y, r, sx, sy)
    local t = sr
    while true do
      local pf
      t = t - dt
      _, pf = coroutine.resume(d, dt, x, y, r, sx, sy)
      local tx, ty, tr, tsx, tsy = x, y, r, sx, sy
      local drawer = function(t)
        pf(modfun(1 - t / life, tx, ty, tr, tsx, tsy))
      end
      dt, x, y, r, sx, sy = coroutine.yield()
      t = sr + t
      trail.add(gamedata, life, drawer)
    end
  end
  return coroutine.create(f)
end
