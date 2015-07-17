local fun = require ("modules/functional")

fsm = {}

function fsm.new()
  return {vertex = {}, edge = {}, _globaledge = nil}
end

function fsm.update(f, current, context)
  local cid = current
  -- Search for transitions
  local gethighest = fun.compose(
                        fun.head,
                        function(t)
                          if #t > 1 then
                            table.sort(t,
                              function(v1, v2)
                                return v1.priority > v2. priority
                              end
                            )
                          end
                          return t
                        end,
                        fun.curry(fun.filter, 2)(
                          function(_, v)
                            return v.priority >= 0
                          end
                        )
                      )
  local t = gethighest(fsm.getedge(f, cid, context))

  if t then
    fsm.traverse(f, cid, t.id, context)
    cid = t.id
  end

  local s = f.vertex[cid]
  if s and s.update then
    s.update(context, framedata)
  end
  return cid
end

function fsm.traverse(f, previd, newid, context)
  bs = f.vertex[previd]
  ss = f.vertex[newid]
  if bs and bs.stop then bs.stop(context) end
  if ss and ss.begin then ss.begin(context) end
end

function fsm.vertex(sm, n, u, b, s)
  local s = {begin = b, update = u, stop = s, id = n}
  sm.vertex[n] = s
end

function fsm.getedge(f, sid, context)
  local fge = f._globaledge or function() return {} end
  local agg = fge(sid, context, {})
  local e = f.edge[sid] or function(_, agg) return agg end
  return e(context, agg)
end

local function newidpriority(id, p)
  return {id = id, priority = p}
end

local function when(sm, aid, bid, condition)
  --sm.vertex[aid] = A
  --sm.vertex[bid] = B
  local ef = sm.edge[aid] or function(_, agg) return agg end
  local c = function(context, agg)
    local con = condition(context) or -1
    local pri = newidpriority(bid, con)
    table.insert(agg, pri)
    return ef(context, agg)
  end

  sm.edge[aid] = c
end

-- Bottom-up
-- Usage: fsm.connect(A).to(B).when(condition)
function fsm.connect(sm, ...)
  local agg = {...}
  local t = function(B)
      local w = function(condition)
        local _do_when = function(_, A)
          when(sm, A, B, condition)
        end
        table.foreach(agg, _do_when)
      end
      return {when = w}
  end
  return {to  = t}
end

-- Top-down
-- Usage: fsm.connectall(sm, A).except(B, C).when(condition)
--  or
-- Usage: fsm.connectall(sm, A).when(condition)
function fsm.connectall(sm, A)
  local e = function(...)
    local blist = {A, ...}
    local w = function(condition)
      local gf = sm._globaledge or function(_, _, agg) return agg end
      local ngf = function(sid, context, agg)
        local isblack = false
        table.foreach(blist, function(_, v) isblack = isblack or (v == sid ) end)
        if not isblack then
          local con = condition(context) or -1
          table.insert(agg, newidpriority(A, con))
        end
        return gf(sid, context, agg)
      end
      sm._globaledge = ngf
    end
    return {when = w}
  end
  local w = function(condition)
    e().when(condition)
  end
  return {when = w, except = e}
end
