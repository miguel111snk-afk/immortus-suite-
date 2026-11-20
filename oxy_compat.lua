-- Utilidades para macros. El llamador proporciona las APIs del contexto OxyBot.
local Compat = {}
local unpackValues = table.unpack or unpack

local function pack(...)
  return { n = select("#", ...), ... }
end

function Compat.capabilities(context, names)
  local available = {}
  for _, name in ipairs(names) do
    available[name] = type(context[name]) == "function"
  end
  return available
end

function Compat.call(fn, ...)
  if type(fn) ~= "function" then
    return false, "API no disponible"
  end
  return pcall(fn, ...)
end

-- El reloj inyectado debe devolver milisegundos monotónicos.
function Compat.throttle(milliseconds, clock, action)
  assert(type(milliseconds) == "number" and milliseconds >= 0)
  assert(type(clock) == "function" and type(action) == "function")
  local lastRun
  return function(...)
    local now = clock()
    if lastRun and now >= lastRun and now - lastRun < milliseconds then
      return false, "intervalo pendiente"
    end
    lastRun = now
    return Compat.call(action, ...)
  end
end

-- Conserva la misma tabla de callbacks al conectar y desconectar.
function Compat.bind(connectFn, disconnectFn, emitter, callbacks)
  if type(connectFn) ~= "function" or type(disconnectFn) ~= "function" then
    return nil, "connect y disconnect son necesarios"
  end
  if emitter == nil or type(callbacks) ~= "table" then
    return nil, "emisor o callbacks inválidos"
  end
  local ok, result = Compat.call(connectFn, emitter, callbacks)
  if not ok or result == false then
    return nil, result
  end
  local active = true
  return function()
    if not active then
      return true
    end
    local outcome = pack(Compat.call(disconnectFn, emitter, callbacks))
    if outcome[1] and outcome[2] ~= false then
      active = false
      return unpackValues(outcome, 1, outcome.n)
    end
    return false, outcome[2]
  end
end

return Compat
