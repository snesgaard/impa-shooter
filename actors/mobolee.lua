actor = actor or {}
loaders = loaders or {}

local ims = {
  hit = "res/mobolee/hit.png",
  idle = "res/mobolee/idle.png",
  prehit = "res/mobolee/prehit.png",
  walk = "res/mobolee/walk.png",
}

local w = 6
local h = 12

local psearch = {
  w = 100, h = 100
}

loaders.mobolee = function(gamedata)
  for _, path in pairs(ims) do
    gamedata.visual.images[path] = gfx.newImage(path)
  end
end

local createidleanime = function(gamedata)
  print(ims.idle)
  local im = gamedata.visual.images[ims.idle]
  return newAnimation(im, 48, 48, 0.2, 2)
end

-- Control states
local idle = {}
local hit = {}
local follow = {}

idle.begin = function(gamedata, id)
  gamedata.visual.drawers[id] = misc.createbouncedrawer(
    createidleanime(gamedata)
  )
  return idle.run(gamedata, id)
end

idle.run = function()
  coroutine.yield()
  return idle.run()
end

local init = function(gamedata)
  return idle.begin
end

actor.mobolee = function(gamedata, id, x, y)
  gamedata.entity[id] = newEntity(x, y, w, h)
  gamedata.face[id] = "right"
  gamedata.control[id] = coroutine.create(init(gamedata))
  gamedata.hitbox[id] = {
    playersearch = coolision.newAxisBox(
      id, x - psearch.w, y + psearch.h, psearch.w,
      psearch.h, nil, gamedata.hitboxtypes.allybody
    )
  }
  gamedata.hitboxsync[id] = {
    playersearch = {x = -psearch.w, y = psearch.h}
  }
end
