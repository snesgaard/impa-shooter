actor = actor or {}

-- Defines
local linger = 0.1
local layer = 1

local cleanup = function(gamedata, id)
  gamedata.visual.drawers[id] = nil
end

local create_visual = function(gamedata, id, trailpoints)
  local visual
  visual = function(gamedata, id, starti)
    -- Check for the end of the trail visualisation
    if starti > #trailpoints then
      gamedata.cleanup[id] = cleanup
      return
    end
    love.graphics.setColor(50, 0, 255, 75)
    for i = starti, #trailpoints do
      local t = trailpoints[i]
      misc.draw_sprite_entity(t.anime, t.entity, t.face)
    end
    love.graphics.setColor(255, 255, 255)
    coroutine.yield()
    local time = gamedata.system.time
    local t = trailpoints[starti]
    if t.time + linger < time then starti = starti + 1 end
    return visual(gamedata, id, starti)
  end
  local init = function(gamedata, id)
    return visual(gamedata, id, 1)
  end
  return init
end

local type = "evadetrail"
actor.evadetrail = function(gamedata, id, trailpoints)
  gamedata.actor[id] = type
  gamedata.visual.drawers[id] = coroutine.create(create_visual(gamedata, id, trailpoints))
end

local create_entry = function(entity, face, time, anim)
  return {entity = table.shallowcopy(entity), face = face, time = time, anime = anim}
end

return create_entry
