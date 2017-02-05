-- debugger/form_editor.lua

local forms = {}
local path  = minetest.get_worldpath()

-- Load forms
local function load_formdata()
  local res = io.open(path.."/debugger_form_editor.txt", "r")
  if res then
    res = minetest.deserialize(res:read("*all"))
    if type(res) == "table" then
      forms = res
    end
  end
end

-- Load all forms
load_formdata()

-- Save forms
function save_formdata()
  io.open(path.."/debugger_form_editor.txt", "w"):write(minetest.serialize(forms))
end

-- Register on shutdown
minetest.register_on_shutdown(save_formdata)

-- Editor formspec
local function get_editor_formspec(name)
  local form_string = forms[name] or ""

  local output = form_string:split("\n")

  for i, line in ipairs(output) do
    output[i] = line
  end

  return [[
    size[20,12]
    textarea[0,0;10.38,13.5;input;Form String (Separate elements with newline);]]..minetest.formspec_escape(form_string)..[[]
    button[-0.26,11.62;4,1;refresh;Refresh and Save]
    box[9.95,0;10,11.69;#FFFFFF00]
    container[10,0]
    ]]..table.concat(output)..[[
    container_end[]
  ]]
end

-- Register chatcommand
minetest.register_chatcommand("form_editor", {
  param = "<edit/preview>",
  description = "Formspec Creator",
  privs = {debug=true},
  func = function(name, param)
    local form_string = forms[name] or ""

    if param == "preview" then
      -- Show formspec
      minetest.show_formspec(name, "debugger:form_preview", form_string)
    else
      -- Show formspec editor
      minetest.show_formspec(name, "debugger:form_editor", get_editor_formspec(name))
    end
  end,
})

-- Register tool
minetest.register_craftitem("debugger:form_editor", {
  description = "[DEBUG] Formspec Editor",
  inventory_image = "debugger_form_editor.png",
  stack_max = 1,
  groups = { not_in_creative_inventory = debugger.CREATIVE },

  -- [on_use] Show editor
  on_use = function(itemstack, player)
    local name = player:get_player_name()

    -- Show formspec editor
    minetest.show_formspec(name, "debugger:form_editor", get_editor_formspec(name))
  end,

  on_place = function(itemstack, player)
    local name        = player:get_player_name()
    local form_string = forms[name] or ""

    -- Show formspec
    minetest.show_formspec(name, "debugger:form_preview", form_string)
  end,
})

-- [event] On Receive Fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname == "debugger:form_editor" then
    local name = player:get_player_name()

    if fields.refresh then
      forms[name] = fields.input

      -- Update formspec editor
      minetest.show_formspec(name, "debugger:form_editor", get_editor_formspec(name))
    end
  end
end)
