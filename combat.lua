require "math"

-- Table which will contain values related to the combat engine
combat = {}

combat.createoneshotdamage = function(boxids, dmg)
  local cache = {}
  local f = function(gamedata, id, colres)
    local res = coolision.fetchres(colres, id, boxids)
    if #res == 0 then return end
    local req = {}
    for k, v in pairs(res) do
      if not cache[k] then
        req[k] = combat.request(v, dmg)
        cache[k] = true
      end
    end
    return req
  end
  return f
end

local function _do_nothing(_, _, _, dmg)
  return dmg
end

function combat.damage(gamedata, tid, dmg)
  local act = gamedata.actor
  local s = act.soak[tid] or 0
  local r = act.reduce[tid] or 1
  local i = act.invincibility[tid] or 0
  if i > 0 then return 0 end
  local predmg = math.max(0, r * (dmg - s))
  return predmg
end

function combat.hitboxseq(gamedata, boxids, frames, time, dolerp)
  local t = gamedata.system.time
  local ft = time / frames
  local f = function(gamedata, id)
    local dt = gamedata.system.time - t
    local frame = math.ceil(dt / time * frames)
    frame = math.max(1, frame)
    local box = boxids[frame]
    return {box}
  end
  return f
end

function combat.dorequests(gamedata, requests)
  local res = {}
  for id, reqs in pairs(requests) do
    for _, r in pairs(reqs) do
      local to = r.to
      local d = r.dmg
      local dmg = combat.damage(gamedata, to, d)
      local subres = res[to] or {}
      table.insert(subres, combat.result(id, dmg))
      res[to] = subres
    end
  end
  return res
end

function combat.request(toid, damage)
  return {to = toid, dmg = damage}
end

function combat.result(fromid, damage)
  return {from = fromid, dmg = damage}
end

return combat
