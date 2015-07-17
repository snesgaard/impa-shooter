require ("modules/fsm")

actor = {}

function actor.new()
  local a = {
    control = fsm.new(),
    visual = {},
    context = {},
    hitbox = {},
  }
  return a
end

function actor.update(a, gframedata)
  fsm.update(a.control, a.context, framedata)
end

function actor.draw(a)
  local v = a.visual[a.control.current] or function() end
  v(a.context)
end

function actor.drawsprite(entity, animation)
  local e = entity
  local a = animation
  local w = a:getWidth()
  local h = a:getHeight()
  if e.face == "right" then
    animation:draw(e.x - w / 2, e.y + h / 2, 0, 1, -1)
  elseif e.face == "left" then
    animation:draw(e.x + w / 2, e.y + h / 2, 0, -1, -1)
  else
    error("Face not defined in entity")
  end
end
-- Takes a collection of functions and combines them with all current updates
-- If they are declared
function actor.globalupdate(a, ...)
  local funcs = {...}
  table.foreach(a.control.vertex, function(k, v)
    local u = a.control.vertex[k].update
    if u then
      a.control.vertex[k].update = functional.invfmap(u, unpack(funcs))
    end
  end)
end

actor.types = {
  enemybody = 0,
  allybody = 1,
  neutralbody = 2,
  enemyprojectile = 3,
  allyprojectile = 4,
  enemymelee = 5,
  allymelee = 6,
}

actor.taggedbox = function(box, hail, seek)
  if type(seek) ~= "table" then seek = {seek} end
  if type(hail) ~= "table" then hail = {hail} end

  return {seek = seek, hail = hail, box = box}
end
