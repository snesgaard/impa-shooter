require "math"
local path = ... .. "."
local axisbox = require (path .. "axisbox")

coolision = {}

local projectspan = function(box, x, y)
  local lx, hx = axisbox.getboundx(box)
  local ly, hy = axisbox.getboundy(box)
  local lp = lx * x + ly * y
  local hp = hx * x + hy * y
  return math.min(lp, hp), math.max(lp, hp)
end

local function sort(idtable, axisboxtable, x, y)
  local axiscompare = function(ida, idb)
    local boxa = axisboxtable[ida]
    local boxb = axisboxtable[idb]
    local la, ha = projectspan(boxa, x, y)
    local lb, hb = projectspan(boxb, x, y)
    return la < lb
  end

  table.sort(idtable, axiscompare)

  return idtable
end

local function groupedsort(axisboxtable, x, y)
  local axiscompare = function(gboxa, gboxb)
    local la, ha = projectspan(gboxa.box, x, y)
    local lb, hb = projectspan(gboxb.box, x, y)
    return la < lb
  end

  table.sort(axisboxtable, axiscompare)
end

local function xoverlaptest(boxa, boxb)
  local lxa, hxa = axisbox.getboundx(boxa)
  local lxb, hxb = axisbox.getboundx(boxb)

  return not (hxa < lxb or hxb < lxa)
end

local function yoverlaptest(boxa, boxb)
  local lya, hya = axisbox.getboundy(boxa)
  local lyb, hyb = axisbox.getboundy(boxb)

  return not (hya < lyb or hyb < lya)
end

coolision.collisiondetect = function(axisboxtable, x, y)
  local idtable = {}
  for id, _ in pairs(axisboxtable) do
    table.insert(idtable, id)
  end
  local sortedidtable = sort(idtable, axisboxtable, x, y)

  local collisiontable = {}

  for ka, ida in pairs(sortedidtable) do
    local potentialcol = {}
    local boxa = axisboxtable[ida]
    for kb, idb in next, sortedidtable, ka do
      local boxb = axisboxtable[idb]
      if xoverlaptest(boxa, boxb) then
        table.insert(potentialcol, idb)
      else
        break
      end
    end
    -- check for y collision and register
    local cola = {}
    for _, idb in pairs(potentialcol) do
      local boxb = axisboxtable[idb]
      if yoverlaptest(boxa, boxb) then
        table.insert(cola, idb)
      end
    end
    if #cola > 0 then
      collisiontable[ida] = cola
    end
  end

  return collisiontable
end

coolision.groupedcd = function(
  seekers, hailers, owner, xlow, xup, ylow, yup, collisions
)
  local isseeker = {}
  local boxids = {}
  for _, bid in pairs(seekers) do
    isseeker[bid] = true
    table.insert(boxids, bid)
  end
  for _, bid in pairs(hailers) do
    isseeker[bid] = false
    table.insert(boxids, bid)
  end
  --[[
  print("wut?")
  print("xlow")
  table.foreach(xlow, print)
  print("xup")
  table.foreach(xup, print)
  print("ylow")
  table.foreach(ylow, print)
  print("yup")
  table.foreach(yup, print)
  print("isseeker")
  table.foreach(isseeker, print)
  ]]--
  -- Sort by x-axis
  table.sort(boxids, function(a, b) return xlow[a] < xlow[b] end)
  for _, sid in pairs(seekers) do
    collisions[sid] = collisions[sid] or {}
  end
  for k, ida in pairs(boxids) do
    local potentialcol = {}
    for _, idb in next, boxids, k do
      if isseeker[ida] == not isseeker[idb] then
        if not (xup[ida] < xlow[idb]) then
          table.insert(potentialcol, idb)
        else
          break
        end
      end
    end
    for _, idb in pairs(potentialcol) do
      if not (yup[ida] < ylow[idb] or yup[idb] < ylow[ida]) and owner[ida].master ~= owner[idb].master then
        local sid = isseeker[ida] and ida or idb
        local hid = sid == ida and idb or ida
        table.insert(collisions[sid], owner[hid].master)
      end
    end
    --collisions[ida] = cols
  end
  return collisions
end
coolision.sortcoolisiongroups = function(gamedata, colrequests)
  -- Before sorting let us calculate the borders and limits of each box
  -- The structure of the code is intended to emulate SOA, cache-friendly coding
  -- style
  -- Assign spatial data
  local xlower = {}
  local xupper = {}
  for id, boxids in pairs(colrequests) do
    local ax = gamedata.actor.x[id] or 0
    local f = gamedata.actor.face[id]
    for _, bid in ipairs(boxids) do
      local lx = f * gamedata.hitbox.x[bid] + ax
      local hx = lx + f * gamedata.hitbox.width[bid]
      --xlower[bid] = math.min(lx, hx)
      --xupper[bid] = math.max(lx, hx)
      table.insert(xlower, math.min(lx, hx))
      table.insert(xupper, math.max(lx, hx))
    end
  end
  local ylower = {}
  local yupper = {}
  for id, boxids in pairs(colrequests) do
    local ay = gamedata.actor.y[id] or 0
    for _, bid in ipairs(boxids) do
      local ly = gamedata.hitbox.y[bid] + ay
      local hy = ly + gamedata.hitbox.height[bid]
      --ylower[bid] = ly
      --yupper[bid] = hy
      table.insert(ylower, ly)
      table.insert(yupper, hy)
    end
  end
  -- Next divide into groups of seekers and hailers for easier matching
  local seekers = {}
  local hailers = {}
  local owner = {}
  local idcount = 0
  for id, boxids in pairs(colrequests) do
    for _, bid in ipairs(boxids) do
      idcount = idcount + 1
      --owner[bid] = id
      owner[idcount] = {master = id, box = bid}
      --local s = gamedata.hitbox.seek[bid]
      --if s then
      --print(#gamedata.hitbox.seek[bid])
      for _, s in pairs(gamedata.hitbox.seek[bid]) do
        --print("seek plza", bid, s)
        local seektable = seekers[s] or {}
        table.insert(seektable, idcount)
        seekers[s] = seektable
      end
      --local h = gamedata.hitbox.hail[bid]
      --if h then
      for _, h in pairs(gamedata.hitbox.hail[bid]) do
        local hailtable = hailers[h] or {}
        table.insert(hailtable, idcount)
        hailers[h] = hailtable
      end
    end
  end
  return seekers, hailers, owner, xlower, xupper, ylower, yupper
end
coolision.docollisiondetections = function(gamedata, colrequests)
  local s, h, o, xlow, xup, ylow, yup = coolision.sortcoolisiongroups(
    gamedata, colrequests
  )
  local allcols = {}
  -- Ensure that all seekers have at least an empty coolision table
  for type, subseekers in pairs(s) do
    for _, sid in pairs(subseekers) do
      --print("seek", type)
      local master = o[sid].master
      local box = o[sid].box
      allcols[master] = {}
      allcols[master][box] = {}
    end
  end
  local collisions = {}
  for type, subhailers in pairs(h) do
    --print("hail", type)
    local subseekers = s[type]
    if subseekers then
      coolision.groupedcd(
        subseekers, subhailers, o, xlow, xup, ylow, yup, collisions
      )
    end
  end
  for bid, coltable in pairs(collisions) do
    local master = o[bid].master
    local box = o[bid].box
    local owntable = allcols[master]
    owntable[box] = coltable
  end
  return allcols
end
function coolision.fetchres(colres, id, boxids)
  local res = {}
  local rid = colres[id] or {}
  for _, bid in pairs(boxids) do
    local r = rid[bid] or {}
    for _, otherid in ipairs(r) do
      table.insert(res, otherid)
    end
  end
  return res
end

coolision.newAxisBox = function(id, x, y, w, h, hail, seek, callback)
  local box = {}
  if type(seek) ~= "table" then seek = {seek} end
  if type(hail) ~= "table" then hail = {hail} end

  box.id = id
  box.x = x
  box.y = y
  box.w = w
  box.h = h
  box.hitcallback = callback
  box.seek = seek
  box.hail = hail

  return box
end

coolision.createaxisbox = function(hitbox, id, x, y, w, h, hail, seek)
  hitbox.x[id] = x
  hitbox.y[id] = y
  hitbox.width[id] = w
  hitbox.height[id] = h
  if type(hail) ~= "table" then hail = {hail} end
  if type(seek) ~= "table" then seek = {seek} end
  hitbox.hail[id] = hail
  hitbox.seek[id] = seek
end

coolision.createcenterbox = function(hitbox, id, w, h, hail, seek)
  coolision.createaxisbox(hitbox, id, -w * 0.5, -h * 0.5, w, h, hail, seek)
end

coolision.setcallback = function(box, callback)
  box.hitcallback = callback
end

coolision.vflipaxisbox = function(box)
  box.x = -box.x - box.w
end
