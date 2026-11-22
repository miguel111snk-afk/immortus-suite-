-- Execute from the normal macro environment with an explicit build label.
local Probe = {}
local names = {
  "macro", "schedule", "onTalk", "onTextMessage", "onManaChange",
  "onSpellCooldown", "onGroupSpellCooldown", "canCast", "getSpellData",
  "getSpellCoolDown", "connect", "disconnect", "getSpectators"
}

function Probe.snapshot(build, context)
  assert(type(build) == "string" and not build:find("[\r\n\t]"))
  assert(type(context) == "table")
  local rows = {}
  for index, name in ipairs(names) do
    rows[index] = { build = build, symbol = name, observed = type(context[name]) }
  end
  return rows
end

function Probe.print(build, context, emit)
  emit("build\tsymbol\ttype")
  for _, row in ipairs(Probe.snapshot(build, context)) do
    emit(table.concat({row.build, row.symbol, row.observed}, "\t"))
  end
end

return Probe
