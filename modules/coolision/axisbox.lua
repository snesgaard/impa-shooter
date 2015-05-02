local axisbox = {}

axisbox.collisiondetect = function(boxa, boxb)
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

axisbox.getboundx = function(box)
  local lx = box.x
  local hx = box.x + box.w
  return lx, hx
end

axisbox.getboundy = function(box)
  local ly = box.y - box.h
  local hy = box.y
  return ly, hy
end

return axisbox
