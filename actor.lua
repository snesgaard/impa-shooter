require ("modules/fsm")

actor = {}

function actor.new()
  return {control = fsm.new(), visual = {}, context = {}, hitbox = function(stateid, context) end}
end

function actor.update(a, framedata)
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

actor.types = {
  enemybody = 0,
  allybody = 1,
  neutralbody = 2,
  enemyprojectile = 3,
  allyprojectile = 4,
}

actor.taggedbox = function(box, hail, seek)
  --if type(seek) ~= "table" then seek = {seek} end
  --if type(hail) ~= "table" then hail = {hail} end

  return {seek = seek, hail = hail, box = box}
end
