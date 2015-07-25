gamedata = {
  actor = {}, -- Contains the type of all actors, an actor is garuanted to have an entry here
  cleanup = {}, -- Actors will insert a function which will be used to cleanup
  -- Actor specific data
  health = {},
  stamina = {},
  maxhealth = {},
  maxstamina = {},
  staminaregen = {},
  defense = {},
  -- Control and hitbox related data
  control = {},
  hitbox = {},
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

local boxseed = 1
local available_boxid = {}
gamedata.addhitbox = function(box)
  local id = available_boxid[#available_boxid]
  if id then
    available_boxid[#available_boxid] = nil
  else
    id = boxseed
    boxseed = boxseed + 1
  end
  gamedata.hitbox[id] = box
  return id
end
gamedata.freehitbox = function(id)
  gamedata.hitbox[id] = nil
  table.insert(available_boxid, id)
end

local draworder = {
  "fire",
  "bullet",
  "player",
  "evadetrail",
  "box",
}

for ord, ent in pairs(draworder) do
  gamedata.visual.draworder[ent] = ord
end

return gamedata
