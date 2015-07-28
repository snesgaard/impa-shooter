gamedata = {
  actor = {}, -- Contains the type of all actors, an actor is garuanted to have an entry here
  cleanup = {}, -- Actors will insert a function which will be used to cleanup
  -- Actor specific data
  health = {},
  stamina = {},
  maxhealth = {},
  maxstamina = {},
  staminaregen = {},
  soak = {},
  reduce = {},
  invincibility = {},
  -- Control and hitbox related data
  control = {},
  hitbox = {},
  hitboxtypes = {},
  -- Graphical data
  visual = {
    scale = 1,
    drawers = {}, -- Rendering functions for actors
    layer = {},
    leveldraw,
    uidrawers = {},
    images = {}, -- Contains all loaded images, indexed by path
    shaders = {},
    width = 0,
    height = 0,
    aspect = 0,
    draworder = {},
  },
  -- System related data and functionality
  system = {
    script = {}, -- Global scripts which is tied to the game / level and not a specific actor
    time = 0, -- Time since game began
    dt = 0, -- Time passed since last frame
    pressed = {}, -- Button press time stamps
    released = {}, -- Button release time stamps
    buffer = {},
  },
  game = {
    activelevel = "",
    playerid,
    maxammunition = {},
    missingammunition = {},
  },
  -- Level related data
  tilemaps = {},
  entity = {},
  face = {},
  ground = {},
  -- Input related data
  latch = {},
}

local seed = 1
local available_id = {}
gamedata.genid = function()
  local id = available_id[#available_id]
  if id then
    available_id[#available_id] = nil
    return id
  end
  local s = seed
  seed = seed + 1
  return s
end
gamedata.unregister = function(id)
  table.insert(available_id, id)
end

gamedata.init = function(data, f, ...)
  local id = data.genid()
  f(data, id, ...)
  return id
end

local draworder = {
  "box",
  "damagenumber",
  "fire",
  "bullet",
  "evadetrail",
  "player",
}

for ord, ent in pairs(draworder) do
  gamedata.visual.draworder[ent] = ord
end

local hitboxtypes = {
  "enemybody",
  "allybody",
  "allyprojectile",
}

for id, ent in pairs(hitboxtypes) do
  gamedata.hitboxtypes[ent] = id
end

return gamedata
