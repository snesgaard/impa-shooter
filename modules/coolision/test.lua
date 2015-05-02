package.path = package.path .. ";../?.lua;../?/init.lua"

local kewlision = require 'coolision'

local function makeLabelBox(x, y, w, h, label)
  local box = kewlision.newAxisBox(x, y, w, h)
  box.label = label
  return box
end

    local reference = {makeLabelBox(0, 5, 5, 1, 'a'), makeLabelBox(2, 1, 2, 1, 'b'), makeLabelBox(4, 5, 5, 1, 'c')}
    local sorted = kewlision.sort(reference, 1, 0)
    for k, box in pairs(sorted) do
      print(box.label)
    end

local coltable = kewlision.collisiondetect(reference, 1, 0)

for box, boxtable in pairs(coltable) do
  for _, other in pairs(boxtable) do
    print("col!", box.label, other.label)
  end
end
