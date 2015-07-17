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
    function(gdata, id)

    end
  )

  -- Edges
  fsm.connect(control, state.runlevel).to(state.B).when(
    function(gdata, id)
      if 
    end
  )

  return control
end

local function generate_visual()
  local visual = {}

  visual[state.runlevel] = function(data, id)
    love.graphics.print("yo running level")
  end

  return visual
end

game.new = function(data, id)
  data.game[id] = typeid

  data.control[id] = data.control[id] or generate_fsm()
  data.visual[id] = data.visual[id] or generate_visual()
  data.state[id] = state.runlevel
end

return game
