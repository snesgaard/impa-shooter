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

coolision.groupedcd = function(seekers, hailers, x, y)
  if #seekers == 0 or #hailers == 0 then return {} end
  -- Concatenate tables and assign labels
  local groupboxtable = {}
  table.foreach(seekers,
    function(k, v)
      table.insert(groupboxtable, {isseeker = true, box = v})
    end
  )
  table.foreach(hailers,
    function(k, v)
      table.insert(groupboxtable, {isseeker = false, box = v})
    end
  )
  -- Sort with respect to specified axis
  groupedsort(groupboxtable, x, y)
  -- Seek collisions along sorted axis
  local collisiontable = {}
  for k, groupa in pairs(groupboxtable) do
    local potentialcol = {}
    for _, groupb in next, groupboxtable, k do
      if xoverlaptest(groupa.box, groupb.box) then
        -- Only add if grouping was different
        if groupa.isseeker == not groupb.isseeker then
          table.insert(potentialcol, groupb)
        end
      else
        break
      end
    end
    -- check for y collision and register
    local cola = {}
    for _, groupb in pairs(potentialcol) do
      if yoverlaptest(groupa.box, groupb.box) then
        table.insert(cola, groupb.box)
      end
    end
    if #cola > 0 then
      collisiontable[groupa.box] = cola
    end
  end

  return collisiontable
end
coolision.sortcollisiongroups = function(hitboxes)
  local seekers = {}
  local hailers = {}
  for _, boxgroup in pairs(hitboxes) do
    for _, box in pairs(boxgroup) do
      for _, seek in pairs(box.seek) do
        local seektable = seekers[seek] or {}
        table.insert(seektable, box)
        seekers[seek] = seektable
      end
      for _, hail in pairs(box.hail) do
        local hailtable = hailers[hail] or {}
        table.insert(hailtable, box)
        hailers[hail] = hailtable
      end
    end
  end
  return seekers, hailers
end
coolision.docollisiongroups = function(seekers, hailers)
  for type, subhailers in pairs(hailers) do
    local subseekers = seekers[type] or {}
    local collisiontable = coolision.groupedcd(subseekers, subhailers, 1, 0)
    for boxa, coolisions in pairs(collisiontable) do
      for _, boxb in pairs(coolisions) do
        if boxa.hitcallback then boxa.hitcallback(boxa, boxb) end
        if boxb.hitcallback then boxb.hitcallback(boxb, boxa) end
      end
    end
  end
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

coolision.setcallback = function(box, callback)
  box.hitcallback = callback
end

coolision.vflipaxisbox = function(box)
  box.x = -box.x - box.w
end
