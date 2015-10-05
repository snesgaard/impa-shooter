actor = actor or {}

local control = {}
function control.make(xmin, xmax, ymin, ymax, maxcount, rate)
  return function(gamedata, id)
    return control.run(
      gamedata, id, xmin, xmax, ymin, ymax, maxcount, rate, rate
    )
  end
end
function control.run(
gamedata, id, xmin, xmax, ymin, ymax, maxcount, rate, spawntimer
)
  if spawntimer < 0 then
    if gamedata.activemobolee < maxcount then
      local x = love.math.random(xmin, xmax)
      local y = love.math.random(ymin, ymax)
      gamedata.init(gamedata, actor.mobolee, x, y)
      gamedata.activemobolee = gamedata.activemobolee + 1
    end
    spawntimer = rate
  end
  coroutine.yield()
  return control.run(
    gamedata, id, xmin, xmax, ymin, ymax, maxcount, rate,
    spawntimer - gamedata.system.dt
  )
end

local render = {}

function render.ui(gamedata, id)
  gfx.print(
    gamedata.score, gamedata.visual.width / gamedata.visual.scale - 20, 10
  )
  return render.ui(coroutine.yield())
end


function actor.moboleemaster(
gamedata, id, xmin, xmax, ymin, ymax, maxcount, rate
)
  gamedata.score = 0
  gamedata.visual.uidrawers[id] = coroutine.create(render.ui)
  gamedata.control[id] = coroutine.create(control.make(
    xmin, xmax, ymin, ymax, maxcount, rate
  ))
  gamedata.activemobolee = 0
end

moboleemaster = {}
function moboleemaster.rip(gamedata, id, mid)
  gamedata.score = gamedata.score + 1
  gamedata.activemobolee = gamedata.activemobolee - 1
end
