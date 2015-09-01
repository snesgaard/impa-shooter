require "io"

loaders = loaders or {}

local shaderpath = "res/shaders/lightshader.frag"
local normalmap = "res/normals.png"

loaders.light = function(gamedata)
  local f = io.open(shaderpath, "rb")
  local fstring = f:read("*all")
  f:close()
  gamedata.visual.shaders[shaderpath] = gfx.newShader(fstring)
  local im = gfx.newImage(normalmap)
  im:setFilter("linear", "linear")
  im:setWrap("repeat", "repeat")
  gamedata.visual.images[normalmap] = im
end

light = {}
light.draw = function(gamedata, canvas, x, y)
  local light = gamedata.light
  love.graphics.setColor(255, 255, 255)
  local shader = gamedata.visual.shaders[shaderpath]
  gfx.setShader(shader)
  shader:send("normalmap", gamedata.visual.images[normalmap])
  shader:send("campos", {math.floor(-x), math.floor(y - gamedata.visual.height / gamedata.visual.scale)})
  shader:send("scale", 1.0 / gamedata.visual.scale)
  -- shader:send("ambientcoeffecient", light.ambient.coeffecient)
  -- shader:send("ambientcolor", light.ambient.color)
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
  gfx.draw(basecanvas, 0, 0, 0, gamedata.visual.scale)
  gfx.setShader()
end

light.testsetup = function(gamedata)
  gamedata.light.point.count = 1
  gamedata.light.point.color = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}
  gamedata.light.point.pos = {{200, -200, 60}, {400, -200, 60}, {600, -200, 60}}
  gamedata.light.point.attenuation = {1e-5, 1e-5, 1e-5}

  gamedata.light.ortho.count = 1
  gamedata.light.ortho.dir = {{1, 1, 1}}
  gamedata.light.ortho.color = {{1, 1, 1}}
  gamedata.light.ortho.coeffecient = {1.0}

  gamedata.light.ambient.coeffecient = 0.05
  gamedata.light.ambient.color = {1, 1, 1}
end
