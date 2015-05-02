local functional = {}


-- reverse(...) : take some tuple and return a tuple of elements in reverse order
--
-- e.g. "reverse(1,2,3)" returns 3,2,1
local function reverse(...)

   --reverse args by building a function to do it, similar to the unpack() example
   local function reverse_h(acc, v, ...)
      if 0 == select('#', ...) then
	 return v, acc()
      else
         return reverse_h(function () return v, acc() end, ...)
      end
   end

   -- initial acc is the end of the list
   return reverse_h(function () return end, ...)
end

functional.curry = function(func, num_args)

   -- currying 2-argument functions seems to be the most popular application
   num_args = num_args or 2

   -- no sense currying for 1 arg or less
   if num_args <= 1 then return func end

   -- helper takes an argtrace function, and number of arguments remaining to be applied
   local function curry_h(argtrace, n)
      if 0 == n then
	 -- kick off argtrace, reverse argument list, and call the original function
         return func(reverse(argtrace()))
      else
         -- "push" argument (by building a wrapper function) and decrement n
          local oneunwrap = function (onearg)
                   return curry_h(function () return onearg, argtrace() end, n - 1)
                end

          local argunwrapper = function(...)
            local arg = {...}
            if #arg == 0 then
              return oneunwrap()
            end
            local f = oneunwrap
            for _, v in ipairs(arg) do
              f = f(v)
            end
            return f
          end

          return argunwrapper
      end
   end

   -- push the terminal case of argtrace into the function first
   return curry_h(function () return end, num_args)
end

functional.compose = function(...)
  -- Put functions in reverse order, which is the order of execution
  local arg = {reverse(...)}
  local f = function(...)
    -- Pack initial arguments
    local farg = {...}
    -- loop through functions, iteratively unpacking args and packing return values
    for _, partf in pairs(arg) do
      farg = {partf(unpack(farg))}
    end
    -- return last partial return value
    return unpack(farg)
  end
  return f
end

functional.constant = function(...)
  local arg = {...}
  local f = function()
    return unpack(arg)
  end
  return f
end

-- Intended to build a chain of operations that can be aborted by returning nil or nothing
-- Not truly monadic as the intended use will involve sideeffects galore
-- Kind of like the maybe monad
functional.monadicbind = function(...)
  local funcs = {...}
  local f = function(...)
    local farg = {...}
    for _, partf in pairs(funcs) do
      farg = {partf(unpack(farg))}
      if #farg == 0 then return end
    end
  end
  return f
end

functional.filter = function(f, t)
  local ft = {}
  local filter = function(k, v)
    if f(k, v) then table.insert(ft, v) end
  end
  table.foreach(t, filter)
  return ft
end

functional.length = function(t)
  local l = 0
  table.foreach(t, function() l = l + 1 end)
  return l
end

-- head and tail searches should be improved when I have the LUA api available
functional.head = function(t)
  local h = nil
  for _, v in pairs(t) do
    h = v
    break
  end
  return h
end

functional.tail = function(t)
  local t = nil
  table.foreach(t, function(_, v) t = v end)
  return t
end

functional.fmap = function(m, t)
  local o = {}
  table.foreach(t,
    function(k, v)
      o[k] = m(v)
    end
  )
  return o
end

return functional
