require "math"
local path = ... .. "."
local axisbox = require (path .. "axisbox")

coolision = {}

local function sort(axisboxtable, x, y)
  local projectspan = function(box)
    local lx, hx = axisbox.getboundx(box)
    local ly, hy = axisbox.getboundy(box)
    local lp = lx * x + ly * y
    local hp = hx * x + hy * y
    return math.min(lp, hp), math.max(lp, hp)
  end

  local axiscompare = function(boxa, boxb)
    local la, ha = projectspan(boxa)
    local lb, hb = projectspan(boxb)
    return la < lb
  end

  table.sort(axisboxtable, axiscompare)

  return axisboxtable
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
  local sortedtable = sort(axisboxtable, x, y)

  local collisiontable = {}

  for k, boxa in pairs(axisboxtable) do
    local potentialcol = {}
    for _, boxb in next, axisboxtable, k do
      if xoverlaptest(boxa, boxb) then
        table.insert(potentialcol, boxb)
      else
        break
      end
    end
    -- check for y collision and register
    local cola = {}
    for _, boxb in pairs(potentialcol) do
      if yoverlaptest(boxa, boxb) then
        table.insert(cola, boxb)
      end
    end
    if #cola > 0 then
      collisiontable[boxa] = cola
    end
  end

  return collisiontable
end

coolision.newAxisBox = function(x, y, w, h, callback)
  local box = {}

  box.x = x
  box.y = y
  box.w = w
  box.h = h
  box.hitcallback = callback

  return box
end
