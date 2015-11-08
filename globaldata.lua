local function createresource(resource)
  resource.__seed__ = 1
  resource.__available_id__ = {}
  return resource
end
function allocresource(resource)
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
function freeresource(resource, id)
  table.insert(resource.__available_id__, id)
end

gamedata = {
  system = {
    time = 0,
    dt = 0,
    pressed = {},
    released = {},
    buffer = {},
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
    terrainco = {},
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
    -- Call back for damage reaction
    ondamagetaken = {},
    -- Control related scripts
    ground = {},
    -- Input
    latch = {},
    control = {},
    draw = {},
    drawtype = {},
  }),
  hitbox = createresource({
    x = {},
    y = {},
    width = {},
    height = {},
    seek = {},
    hail = {},
  }),
  hitboxtypes = {},
  particles = createresource({
    x = {},
    y = {},
    system = {},
  }),
  animations = createresource({}),
  light = {
    point = createresource({
      x = {},
      y = {},
      z = {},
      red = {},
      green = {},
      blue = {},
      attenuation = {},
    }),
    ortho = createresource({
      dx = {},
      dy = {},
      dz = {},
      red = {},
      green = {},
      blue = {},
      coeffecient = {}
    }),
    ambient = {
      color = {0, 0, 0},
      coeffecient = 0,
    },
    gamma = {1, 1, 1},
  },
  ui = createresource({
    x = {},
    y = {},
    draw = {},
  }),
  mobolee = {
    -- Horde mode data
    master = -1,
    mobolees = {},
    activemobolee = 0,
    score = 0,
    timeleft = 0,
  }
}

function initactor(gamedata, f, ...)
  local id = allocresource(gamedata.actor)
  f(gamedata, id, ...)
  return id
end

function initanimation(gamedata, ...)
  local id = allocresource(gamedata.animations)
  gamedata.animations[id] = newAnimation(...)
  return id
end

function initresource(resource, f, ...)
  local id = allocresource(resource)
  f(resource, id, ...)
  return id
end

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
