game = {}

local typeid = "impa"

local state = {
  runlevel = "runlevel",
  B = "stateB"
}

local function generate_fsm()
  local control = fsm.new()

  -- Vertex
  fsm.vertex(control, state.runlevel,
    function(data, id)

    end
  )

  -- Edges
  local key = 'b'
  fsm.connect(control, state.runlevel).to(state.B).when(
    function(data, id)
      local p = data.system.pressed[key] or 0
      local r = data.system.released[key] or 0
      if p > r then return 1 end
    end
  )
  fsm.connect(control, state.B).to(state.runlevel).when(
    function(data, id)
      local p = data.system.pressed[key] or 0
      local r = data.system.released[key] or 0
      if p < r then return 1 end
    end
  )

  return control
end

local function generate_visual()
  local visual = {}

  visual[state.runlevel] = function(data, id)
    love.graphics.print("yo running level")
  end
  visual[state.B] = function(data, id)
    love.graphics.print("B state")
  end

  return visual
end

game.new = function(data, id)
  data.game[id] = typeid

  data.control[id] = data.control[id] or generate_fsm()
  data.visual[id] = data.visual[id] or generate_visual()
  data.state[id] = state.runlevel
  data.latch[id] = {}
end

return game
