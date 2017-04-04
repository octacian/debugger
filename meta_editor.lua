-- debugger/meta_editor.lua

local meta_contexts = {}

-- [table] Formspecs
local forms = {
  meta_main = {
    get = function(name, pos)
      local meta = minetest.get_meta(pos):to_table().fields

      local keys = ""
      local values = ""
      for key, value in pairs(meta) do
        keys  = keys..key..","
        values = values..value..","
      end

      -- Remove final ","s
      keys   = keys:sub(1, -2)
      values = values:sub(1, -2)

      meta_contexts[name] = {
        pos    = pos,
        keys   = keys,
        values = values,
      }

      return [[
        size[10,10]
        tableoptions[highlight=#00000000]
        table[-0.28,-0.29;4.7,10.05;keys;]]..keys..[[;1]
        button[-0.29,9.67;4.92,1;add;+ Add Key]
        tableoptions[highlight=#467832]
        table[4.4,-0.29;5.7,10.7;values;]]..values..[[;1]
      ]]
    end,
    handle = function(name, fields)
      if fields.values then
        local s = fields.values:split(":")
        if s[1] == "DCL" and tonumber(s[3]) ~= 0 then
          debugger.show_meta(name, "meta_change", true, tonumber(s[2]))
        end
      end
      if fields.add then
        debugger.show_meta(name, "meta_add", true)
      end
    end,
  },
  meta_change = {
    get = function(name, id)
      local meta = meta_contexts[name]
      if not meta then return end

      local key   = meta.keys:split(",")[id]
      local value = meta.values:split(",")[id]

      meta_contexts[name].key = key

      return [[
        size[10,5]
        label[0,0;Editing: ]]..key..[[]
        label[0,0.5;Old Value: ]]..value..[[]
        button[8,0;2,1;delete;Delete]
        field[0.3,1.3;10,1;value;;]]..value..[[]
        button[0,2;2,1;back;< Back]
        button[2,2;2,1;save;Save]
      ]]
    end,
    handle = function(name, fields)
      local meta = meta_contexts[name]
      if not meta then return end
      local pos  = meta.pos

      if fields.back then
        debugger.show_meta(name, "meta_main", true, pos)
      end
      if fields.save then
        minetest.get_meta(pos):set_string(meta.key, fields.value)
        debugger.show_meta(name, "meta_main", true, pos)
      end
      if fields.delete then
        minetest.get_meta(pos):set_string(meta.key, nil)
        debugger.show_meta(name, "meta_main", true, pos)
      end
    end,
  },
  meta_add = {
    get = function(name)
      return [[
        size[10,5]
        label[0,0;Add new meta value]
        field[0.3,1.3;10,1;key;Key;]
        field[0.3,2.4;10,1;value;Value;]
        button[0,3;2,1;cancel;< Cancel]
        button[2,3;2,1;add;Add]
      ]]
    end,
    handle = function(name, fields)
      local meta = meta_contexts[name]
      if not meta then return end
      local pos  = meta.pos

      if fields.cancel then
        debugger.show_meta(name, "meta_main", true, pos)
      end
      if fields.add and fields.key and fields.value then
        meta = minetest.get_meta(pos)
        if meta:get_string(fields.key) == "" then
          meta:set_string(fields.key, fields.value)
          debugger.show_meta(name, "meta_main", true, pos)
        else
          minetest.chat_send_player(name, minetest.colorize("red", "Meta Editor Error: ")
            .." key \""..fields.key.."\" already exists")
        end
      end
    end,
  },
}

-- [function] Show/Hide Formspecs
function debugger.show_meta(pname, fname, show, ...)
  if forms[fname] then
    if not minetest.get_player_by_name(pname) then
      return
    end

    if show ~= false then
      minetest.show_formspec(pname, "debugger:"..fname, forms[fname].get(pname, ...))
    else
      minetest.close_formspec(pname, "debugger:"..fname)
    end
  end
end

-- [event] on receive fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
  local formname = formname:split(":")

  if formname[1] == "debugger" and forms[formname[2]] then
    local handle = forms[formname[2]].handle
    if handle then
      handle(player:get_player_name(), fields)
    end
  end
end)

-- [register] Editor tool
minetest.register_craftitem("debugger:meta_editor", {
  description = "[DEBUG] Node Meta Editor",
  inventory_image = "debugger_meta_editor.png",
  stack_max = 1,
  groups = { not_in_creative_inventory = debugger.CREATIVE },

  -- [on_use] Show editor
  on_use = function(itemstack, player, pointed_thing)
    local pos  = pointed_thing.under
    local name = player:get_player_name()

    debugger.show_meta(name, "meta_main", true, pos)
  end,
})
