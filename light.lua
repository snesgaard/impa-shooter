require "io"

loaders = loaders or {}

local shaderpath = "res/shaders/lightshader.frag"
local normalmap = "res/normals.png"

loaders.light = function(gamedata)
  local f = io.open(shaderpath, "rb")
  local fstring = f:read("*all")
  f:close()
  gamedata.resource.shaders[shaderpath] = gfx.newShader(fstring)
  local im = gfx.newImage(normalmap)
  im:setFilter("linear", "linear")
  im:setWrap("repeat", "repeat")
  gamedata.resource.images[normalmap] = im
end

light = {}
light.draw = function(gamedata, canvas, x, y)
  local light = gamedata.light
  love.graphics.setColor(255, 255, 255)
  local shader = gamedata.resource.shaders[shaderpath]
  gfx.setShader(shader)
  shader:send("normalmap", gamedata.resource.images[normalmap])
  shader:send(
    "campos", {math.floor(-x),
    math.floor(y - gamedata.visual.height / gamedata.visual.scale)}
  )
  shader:send("scale", 1.0 / gamedata.visual.scale)
  shader:send("ambientcoeffecient", light.ambient.coeffecient)
  shader:send("ambientcolor", light.ambient.color)
  shader:send("gamma", light.gamma)
  -- Send a light source
  local lp = light.point
  local lpdata = {
    color = {},
    pos = {},
    att = {},
    count = 0,
  }
  for id, a in ipairs(attenuation) do
    table.insert(lpdata.color, {lp.red[id], lp.green[id], lp.blue[id]})
    table.insert(lpdata.pos, {lp.x[id], lp.y[id], lp.z[id]})
    table.insert(lpdata.att, a)
    lpdata.count = lpdata.count + 1
  end
  shader:sendInt("lights", lpdata.count)
  if light.point.count > 0 then
    shader:send("lightcolor", unpack(lpdata.color))
    shader:send("lightpos", unpack(lpdata.pos))
    shader:send("attenuation", unpack(lpdata.att))
  end
  -- Submit orthogonal light sources
  shader:sendInt("ortholights", light.ortho.count)
  if light.ortho.count > 0 then
    shader:send("orthocolor", unpack(light.ortho.color))
    shader:send("orthodir", unpack(light.ortho.dir))
    shader:send("orthocoeffecient", unpack(light.ortho.coeffecient))
  end
  gfx.draw(canvas, 0, 0, 0, gamedata.visual.scale)
  gfx.setShader()
end

local function setuppointlight(gamedata, color, pos, atten)
  local lp = gamedata.light.point
  local id = allocresource(lp)
  lp.red[id] = color[0]
  lp.green[id] = color[1]
  lp.blue[id] = color[2]
  lp.x[id] = pos[0]
  lp.y[id] = pos[1]
  lp.y[id] = pos[2]
  lp.attenuation[id] = atten
  return id
end

local function setuportholight(gamedata, color, dir, coeff)
  local lo = gamedata.light.ortho
  local id = allocresource(lo)
  lo.red[id] = color[0]
  lo.green[id] = color[1]
  lo.blue[id] = color[2]
  lo.dx[id] = dir[0]
  lo.dy[id] = dir[1]
  lo.dz[id] = dir[2]
  lo.coeffecient[id] = coeff
end

light.testsetup = function(gamedata)
  setuppointlight(gamedata, {1.0, 0.3, 0.3}, {200, -200, 30}, 1e-4)
  setuppointlight(gamedata, {0.0, 0.1, 0.0}, {400, -200, 60}, 1e-5)
  setuppointlight(gamedata, {0.0, 0.0, 0.1}, {600, -200, 60}, 1e-5)

  setuportholight(gamedata, {1, 1, 1}, {-1, 1, 1}, 0.5)

  gamedata.light.ambient.coeffecient = 0.5
  gamedata.light.ambient.color = {1, 1, 1}
end
