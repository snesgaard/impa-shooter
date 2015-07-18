gamedata = {
  actor = {}, -- Contains the type of all actors, an actor is garuanted to have an entry here
  -- Actor specific data
  health = {},
  stamina = {},
  maxhealth = {},
  maxstamina = {},
  staminaregen = {},
  soak = {},
  reduce = {},
  -- Control and hitbox related data
  state = {},
  control = {}, --finite state machine definitions
  hitbox = {}, -- Hitbox generators
  -- Graphical data
  images = {}, -- Contains all loaded images, indexed by path
  shaders = {},
  visual = {}, -- Rendering functions
  -- System related data and functionality
  system = {
    script = {}, -- Global scripts which is tied to the game / level and not a specific actor
    time = 0, -- Time since game began
    dt = 0, -- Time passed since last frame
    pressed = {}, -- Button press time stamps
    released = {}, -- Button release time stamps
  },
  -- Level related data
  levels = {}, -- Contains level type with id as key
  tilemaps = {},
  -- Game related data
  game = {}, -- gameid for state
  -- Input related data
  latch = {},
}

local seed = 1
gamedata.genid = function()
  local s = seed
  seed = seed + 1
  return s
end

gamedata.init = function(data, f, ...)
  local id = data.genid()
  f(data, id, ...)
  return id
end

return gamedata
