actor = actor or {}
loaders = loaders or {}

local time = 0.15
local frames = 3
local frametime = time / frames

local type = "fire"

local images = {
  exhaust = "res/gunexhaust.png"
}

loaders.gunexhaust = function(gamedata)
  for _, path in pairs(images) do
    gamedata.resource.images[path] = love.graphics.newImage(path)
  end
end

local cleanup = function(gamedata, id)
  gamedata.visual.drawers[id] = nil
end

local visual = function(x, y, face, anime)
  local co = function(gamedata, id)
    local timer = misc.createtimer(gamedata.system.time, time)
    local entity = newEntity(x, y, 0, 0)
    while timer(gamedata.system.time) do
      anime:update(gamedata.system.dt)
      misc.draw_sprite_entity(anime, entity, face)
      coroutine.yield()
    end
    gamedata.cleanup[id] = cleanup
    coroutine.yield()
  end
  return co
end

actor.gunexhaust = function(gamedata, id, x, y, face)
  gamedata.actor[id] = type
  local ims = gamedata.resource.images
  local anime = newAnimation(ims[images.exhaust], 10, 9, frametime, frames)
  gamedata.visual.drawers[id] = coroutine.create(visual(x, y, face, anime))
end
