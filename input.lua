input = {}

input.pressed = function(keyboard, latch, buffer, time, k)
  local t = keyboard[k]
  local l = latch[k]
  local b = buffer[k]
  return (t > l) and (time - t < buffer)
end

input.latch = function(keyboard, latch, key)
  latch[key] = keyboard[]
end
