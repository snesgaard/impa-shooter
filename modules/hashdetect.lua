require "math"

local floor = math.floor

local function AABBColDetect(boxa, boxb)
  local lxa = boxa.x
  local hxa = boxa.x + boxa.w
  local lxb = boxb.x
  local hxb = boxb.x + boxb.w

  local lya = boxa.y - boxa.h
  local hya = boxa.y
  local lyb = boxb.y - boxb.h
  local hyb = boxb.y

  local separated = hxa < lxb or hxb < lxa or hya < lyb or hyb < lya

  return not separated
end

local hash = {}

hash.init = function(binsize)
  return {binsize = binsize, spatial = {}, shapes = {}}
end

hash.insert = function(spatialhash, aabb)
  local bsize = spatialhash.binsize
  local spatial = spatialhash.spatial

  local lx = floor(aabb.x / bsize)
  local hx = floor((aabb.x + aabb.w) / bsize)
  local ly = floor((aabb.y - h) / bsize)
  local hy = floor(aabb.y / bsize)

  local key = #spatialhash.shapes + 1
  spatialhash.shapes[key] = aabb

  for x = lx, hx do
    for y = ly, hy do
      spatial[x] = spatial[x] or {}
      spatial[x][y] = spatial[x][y] or {}
      table.insert(spatial[x][y], key)
    end
  end

  return hash
end

hash.detect = function(spatialhash, oncollision)
  colres = {}
  local skip = function(key, otherkey)
    return key == otherkey or (colres[key] and colres[key][otherkey])
  end

  for x, col in pairs(spatialhash) do
    for y, bin in pairs(spatialhash) do
      table.sort(bin)
      for k, shapekey in pairs(bin) do
        local shape = spatialhash.shapes[shapekey]
        for _, otherkey in next, bin, k do
          if not skip(shapekey, otherkey) then
            local othershape = spatialhash.shapes[otherkey]
            if AABBColDetect(shape, othershape) then
              oncollision(shape, othershape)
            end
          end
        end
      end
    end
  end
end

return hash
