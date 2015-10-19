--[[
gamedata = {
  actor = {}, -- Contains the type of all actors, an actor is garuanted to have an entry here
  cleanup = {}, -- Actors will insert a function which will be used to cleanup
  -- Actor specific data
  health = {},
  damage = {},
  stamina = {},
  maxhealth = {},
  maxstamina = {},
  usedstamina = {},
  staminaregen = {},
  soak = {},
  reduce = {},
  invincibility = {},
  speed = {},
  -- Control and hitbox related data
  control = {},
  target = {},
  message = {},
  hitbox = {
    width = {},
    height = {},
    x = {},
    y = {},
    hail = {},
    seek = {}
  },
  -- Graphical data
  visual = {
    scale = 1,
    drawers = {}, -- Rendering functions for actors
    layer = {},
    leveldraw,
    uidrawers = {},
    images = {}, -- Contains all loaded images, indexed by path
    meshes = {},
    shaders = {},
    particles = {},
    basecanvas = 0,
    width = 0,
    height = 0,
    aspect = 0,
    draworder = {},
  },
  light = {
    gamma = {1.0, 1.0, 1.0},--{1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2},
    ambient = {
      color = {0, 0, 0},
      coeffecient = 0,
    },
    point = {
      count = 0,
      pos = {},
      color = {},
      attenuation = {},
    },
    ortho = {
      count = 0,
      dir = {},
      color = {},
      coeffecient = {}
    }
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
  keys = {},
  bullet = {
    lifetime = {},
    damagedealt = {},
  },
  weapons = {
    inuse = {},
    maxammo = {},
    usedammo = {},
    fire = {},
    reload = {},
  },
  rifle = {
    multilevel = {},
    multitimer = {},
  },
  -- Level related data
  tilemaps = {},
  entity = {},
  face = {},
  ground = {},
  -- Input related data
  latch = {},
  -- Horde mode data
  moboleemaster = -1,
  mobolees = {},
  activemobolee = 0,
  score = 0,
  timeleft = 0,
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
function gamedata.softcleanactor(data, id)
  data.control[id] = nil
  data.entity[id] = nil
  data.entity2entity[id] = nil
  data.entity2terrain[id] = nil
  data.visual.drawers[id] = nil
  data.visual.uidrawers[id] = nil
  data.hitbox[id] = nil
  data.hitboxsync[id] = nil
  data.cleanup[id] = nil
  data.damage[id] = 0
end
function gamedata.softreset(data)
  seed = 1
  available_id = {}
  for id, _ in pairs(data.actor) do gamedata.softcleanactor(data, id) end
end
]]--

local function createresource(resource)
  resource.__seed__ = 1
  resource.__available_id__ = {}
end
local function allocid(resource)
  local available_id = resource.__available_id__
  local id = available_id[#available_id]
  if id then
    available_id[#available_id] = nil
    return id
  end
  local s = resource.__seed__
  resource.__seed__ = resource.__seed__ + 1
  return s
end

local function freeid(resource, id)
  table.insert(resource.__available_id__, id)
end

gamedata = {
  system = {
    time = 0,
    dt = 0,
    pressed = {},
    released = {},
  },
  global = {
    playerid,
    level,
  },
  visual = {
    scale = 1,
    draworder = {},
    layer = {},
    basecanvas = 0,
    width = 0,
    height = 0,
    aspect = 0,
  },
  resource = {
    images = {},
    mesh = {},
    shaders = {},
    tilemaps = {},
  },
  actor = createresource({
    claimed = {},
    -- Geometric infomation
    x = {},
    y = {},
    vx = {},
    vy = {},
    width = {},
    height = {},
    face = {},
    -- Combat information
    health = {},
    damage = {},
    stamina = {},
    maxhealth = {},
    maxstamina = {},
    usedstamina = {},
    staminaregen = {},
    soak = {},
    reduce = {},
    invincibility = {},
    speed = {},
    -- Control related scripts
    control = {},
    ground = {},
    -- Input
    latch = {},
  }),
  hitbox = createresource({
    offx = {},
    offy = {},
    width = {},
    height = {},
  }),
  hitboxtypes = {},
  light = {
    point = createresource({
      pos = {},
      color = {},
      attenuation = {},
    }),
    ortho = createresource({
      dir = {},
      color = {},
      coeffecient = {}
    }),
    ambient = {
      color = {0, 0, 0},
      coeffecient = 0,
    }
  },
  drawers = {
    world = createresource({}),
    ui = createresource({}),
    particles = createresource({}),
  },
  mobolee = {
    -- Horde mode data
    master = -1,
    mobolees = {},
    activemobolee = 0,
    score = 0,
    timeleft = 0,
  }
}

local draworder = {
  "box",
  "mobolee",
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
  "allyactive",
}

for id, ent in pairs(hitboxtypes) do
  gamedata.hitboxtypes[ent] = id
end

return data
