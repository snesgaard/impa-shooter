function newEntity(x, y, width, height, _do_gravity)
  if _do_gravity == nil then _do_gravity = true end
  e = {}
  e.x = x
  e.y = y
  e.wx = width
  e.wy = height
  e.vx = 0
  e.vy = 0
  e.ax = 0
  e.ay = 0
  e._do_gravity = _do_gravity
  e.face = "right"
  e.mapCollisionCallback = function(entity, map, collisionMap, cx, cy) end

  return e
end
