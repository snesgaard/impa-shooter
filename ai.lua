require "math"

ai = {}

function ai.sortclosest(gamedata, id, tofollow)
  local act = gamedata.actor
  local dist = {}
  for _, oid in pairs(tofollow) do
    dist[id] = math.abs(act.x[oid] - act.x[id])
  end
  table.sort(tofollow, function(a, b) return dist[a] < dist[b] end)
end

local function setspeed(gamedata, id, speed, cols)
  local act = gamedata.actor
  local minvx = -math.huge
  local maxvx = math.huge
  for _, oid in ipairs(cols) do
    local dx = act.x[oid] - act.x[id]
    if dx > 0 then maxvx = 0 elseif dx < 0 then minvx = 0 end
  end
  return math.min(maxvx, math.max(minvx, speed))
end

function ai.moveto(gamedata, fid, tid, speed, asid, tol)
  local dx = math.huge
  local act = gamedata.actor
  dx = act.x[tid] - act.x[fid]
  local f = dx / math.abs(dx)
  act.face[fid] = f
  if math.abs(dx) < tol then
    return true
  end
  local do_col = function(gamedata, id)
    return {asid}
  end
  local do_res = function(gamedata, id, res)
    act.vx[fid] = setspeed(gamedata, fid, speed * f, res[asid] or {})
  end
  do_action(gamedata, fid, do_col, do_res)
  --[[
  cols = coroutine.yield({asid})
  act.vx[fid] = setspeed(gamedata, fid, speed * f, cols[asid])
  ]]--
  coroutine.yield()
  return ai.moveto(gamedata, fid, tid, speed, asid, tol)
end
