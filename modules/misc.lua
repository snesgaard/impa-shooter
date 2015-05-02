local misc = {
  setPosSTIMap = function(map, x, y)
    for _, layer in pairs(map.layers) do
      layer.x = x
      layer.y = -y
    end
    map.x = x
    map.y = y
    return map
  end
}

return misc
