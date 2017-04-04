-- debugger/init.lua

debugger = {}

debugger.modpath = minetest.get_modpath("debugger")
local modpath = debugger.modpath

-- Logger
function debugger.log(content, log_type)
  assert(content, "debugger.log: content nil")
  if log_type == nil then log_type = "action" end
  minetest.log(log_type, "[debugger] "..content)
end

-- Load Settings
local Settings = Settings(modpath.."/config.txt"):to_table()

if Settings then
  debugger.CREATIVE = Settings.not_in_creative or 1
else
  debugger.CREATIVE = 1
end

-- Load formspec editor
if Settings.formspec_editor ~= false then
  dofile(modpath.."/form_editor.lua")
end

-- Load meta/inv editor
if Settings.meta_editor ~= false then
  dofile(modpath.."/meta_editor.lua")
end
