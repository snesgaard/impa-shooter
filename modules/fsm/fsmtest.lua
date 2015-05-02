require ("modules/fsm")

sm = fsm.new()
sm.current = "a"

function a2b(context, framedata)
  if framedata.do_stuff then
    return 1
  end
  return -1
end
fsm.connect(sm, "a", "c").to("b").when(a2b)

function a2c(context, framedata)
  if framedata.do_stuff then
    return 2
  end
  return -1
end
fsm.connect(sm, "a").to("c").when(a2c)

function d2(context, framedata)
  if framedata.do_stuff then
    return 3
  end
  return -1
end
fsm.connectall(sm, "d").except("a").when(d2)

--edges = fsm.getedge(sm, {do_stuff = 1})
--table.foreach(edges, function(_, v) print(v.id, v.priority) end)

print(sm.current)
fsm.update(sm, {do_stuff = 1})
print(sm.current)
fsm.update(sm, {do_stuff = 1})
print(sm.current)
