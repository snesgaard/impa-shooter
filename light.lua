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
  shader:send("campos", {math.floor(-x), math.floor(y - gamedata.visual.height / gamedata.visual.scale)})
  shader:send("scale", 1.0 / gamedata.visual.scale)
  shader:send("ambientcoeffecient", light.ambient.coeffecient)
  shader:send("ambientcolor", light.ambient.color)
  shader:send("gamma", light.gamma)
  -- Send a light source
  shader:sendInt("lights", light.point.count)
  if light.point.count > 0 then
    shader:send("lightcolor", unpack(light.point.color))
    shader:send("lightpos", unpack(light.point.pos))
    shader:send("attenuation", unpack(light.point.attenuation))
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
  lp.color[id] = color
  lp.pos[id] = pos
  lp.attenuation[id] = atten
  return id
end

local function setuportholight(gamedata, color, dir, coeff)
  local lo = gamedata.light.ortho
  local id = allocresource(lo)
  lo.color[id] = color
  lo.dir[id] = dir
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
