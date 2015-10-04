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

local function mainlogic(gamedata)
  -- Move all entities
  local tmap = gamedata.tilemaps[gamedata.game.activelevel]
  for _, e in pairs(gamedata.entity) do
    mapAdvanceEntity(tmap, "game", e, gamedata.system.dt)
  end
  resolveoverlap(tmap, "game", gamedata.entity2entity, gamedata.entity)
  -- Sync all hitboxes to entities, if possible
  for id, synctable in pairs(gamedata.hitboxsync) do
    -- Assume that entity is set, otherwise provoke an error
    local entity = gamedata.entity[id]
    local face = gamedata.face[id]
    local s
    if face == "right" then s = 1 else s = -1 end
    for boxid, syncoff in pairs(synctable) do
      local box = gamedata.hitbox[id][boxid]
      box.x = syncoff.x * s - 0.5 * (1 - s) * box.w + entity.x
      box.y = syncoff.y + entity.y
    end
  end
  -- Now hit detection on all registered hitboxes
  local seekers, hailers = coolision.sortcollisiongroups(gamedata.hitbox)
  -- Should be fixed
  -- if drawboxes then drawhailers = hailers end
  coolision.docollisiongroups(seekers, hailers)
  -- Update weapon data
  rifle.updatemultipliers(gamedata)
  -- Update stamina: HACK Rate is not real
  local rate = 1
  for id, usedstam in pairs(gamedata.usedstamina) do
    local nextstam = usedstam - rate * gamedata.system.dt
    if nextstam < 0 then
      gamedata.usedstamina[id] = nil
    else
      gamedata.usedstamina[id] = nextstam
    end
  end
  -- Update control state for all actors
  for id, cont in pairs(gamedata.control) do
    coroutine.resume(cont, gamedata, id)
  end
  for id, clean in pairs(gamedata.cleanup) do
    clean(gamedata, id)
    gamedata.unregister(id)
  end
  gamedata.cleanup = {}
end

function game.init(gamedata)
  -- Do soft initialization here
  gamedata.init(gamedata, actor.statsui)
  gamedata.game.playerid = gamedata.init(gamedata, actor.shalltear, 100, -100)
  gamedata.init(gamedata, actor.mobolee, 400, -100)
  gamedata.init(gamedata, actor.mobolee, 500, -100)
  return game.run(gamedata)
end

function game.run(gamedata)
  -- Main game logic here
  mainlogic(gamedata)
  local pid = gamedata.game.playerid
  local phealth = gamedata.health[pid]
  local pdmg = gamedata.damage[pid] or 0
  if not (phealth > pdmg)  then
    --return game.done(coroutine.yield())
    gamedata.softreset(gamedata)
    return game.init(coroutine.yield())
  else
    return game.run(coroutine.yield())
  end
end

function game.done(gamedata, playerid)
  mainlogic(gamedata)
  -- Game logic here
  if player_exit then
    -- throw exit event
  end
  if player_reset then
    return game.init(coroutine.yield())
  else
    return game.done(coroutine.yield())
  end
end
return game
