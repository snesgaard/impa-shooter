require "globaldata" -- THis will generate the global "data" table
require ("modules/fsm")
require "game"

function love.keypressed(key, isrepeat)
  gamedata.system.pressed[key] = gamedata.system.time
end

function love.load()
  -- Set filtering to nearest neighor
  local filter = "nearest"
  love.graphics.setDefaultFilter(filter, filter, 0)
  -- Initialise game control logic
  gameid = gamedata.init(gamedata, game.new)
end

function love.update(dt)
  -- Update time
  gamedata.system.time = love.timer.getTime()
  gamedata.system.dt = dt
  -- Proceed to run the main game script
  local gametype = gamedata.game[gameid]
  local gstate = gamedata.state[gameid]
  local control = gamedata.control[gameid]
  -- Update game fsm
  fsm.update(control, gstate, gamedata)
end

function love.draw()
  local gstate = gamedata.state[gameid]
  local drawgame = gamedata.visual[gameid][gstate]
  drawgame(gamedata, gameid)
end
