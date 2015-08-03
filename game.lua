-- gameplay related fucitonality
game = {}
game.onground = function(gamedata, id)
  local buffer = 0.1 -- Add to global data if necessary
  local g = gamedata.ground[id]
  local t = gamedata.system.time
  return g and t - g < buffer
end

game.loadimage = function(gamedata, path)
  gamedata.visual.images[path] = love.graphics.newImage(path)
end

return game
