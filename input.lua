input = {}

input.pressed = function(keyboard, latch, buffer, time, k)
  local t = keyboard[k] or -1e300
  local l = latch[k] or -1e300
  local b = buffer[k] or 0.1
  return (t > l) and (time - t < b)
end

input.latch = function(keyboard, latch, key)
  latch[key] = keyboard[key]
end

return input
