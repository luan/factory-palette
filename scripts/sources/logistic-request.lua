local math = require("__flib__.math")
local table = require("__flib__/table")

local inventory = require("scripts.sources.inventory")

local constants = require("constants")
local h = require("handlers").for_player()

local logistic_request = {}

local Sections = {
  Default = "Factory Palette: Default",
  Temporary = "Factory Palette: Temporary",
}

---@param player LuaPlayer
---@param player_table FpalPlayerTable
---@param name string
---@param counts {min: number, max: number}
---@param is_temporary boolean
function logistic_request.set(player, player_table, name, counts, is_temporary)
  local section = logistic_request.get_section(player, is_temporary and Sections.Temporary or Sections.Default)
  if not section then
    return
  end

  -- search for first empty slot
  local index = section.filters_count + 1
  for i, filter in ipairs(section.filters) do
    local value = filter.value
    if value.type == "item" and value.name == name then
      index = i
      break
    end
  end

  section.set_slot(index, {
    value = name,
    min = counts.min,
    max = counts.max,
  })
end

---@param player LuaPlayer
---@param player_table FpalPlayerTable
---@param name string
function logistic_request.clear(player, name)
  local section = logistic_request.get_section(player, Sections.Default)
  if not section then
    return
  end
  section.clear_slot(request_data.index)
end

---@param player LuaPlayer
---@param group keyof Sections
---@return LuaLogisticSection?
function logistic_request.get_section(player, group)
  local character = player.character
  local logistic_point = character and character.get_logistic_point(defines.logistic_member_index.character_requester)
  if not logistic_point then
    return nil
  end
  for _, section in ipairs(logistic_point.sections) do
    if section.group == group then
      return section
    end
  end

  return logistic_point.add_section(group)
end

---@param args {player: LuaPlayer, player_table: FpalPlayerTable}
function logistic_request.update_temporaries(args)
  local player = args.player
  local player_table = args.player_table
  local temporary_section = logistic_request.get_section(player, Sections.Temporary)
  if not temporary_section then
    return
  end

  local combined_contents = inventory.get_combined_contents(player, player.get_main_inventory())
  for index, filter in ipairs(temporary_section.filters) do
    if filter.value then
      local name = filter.value.name
      local has_count = combined_contents[name] or 0
      -- if the request has been satisfied
      if filter.min and has_count >= filter.min and (not filter.max or has_count <= filter.max) then
        -- clear the temporary request data first to avoid setting the slot twice
        temporary_section.clear_slot(index)
      end
    end
  end
end

---@param player LuaPlayer
---@param player_table FpalPlayerTable
function logistic_request.quick_trash_all(player, player_table)
  local logistic_point = player.charter
    and player.character.get_logistic_point(defines.logistic_member_index.character_requester)
  if not logistic_point then
    return
  end

  logistic_point.trash_not_requested = not logistic_point.trash_not_requested
end

logistic_request.events = {
  [defines.events.on_player_ammo_inventory_changed] = h():chain(logistic_request.update_temporaries),
  [defines.events.on_player_armor_inventory_changed] = h():chain(logistic_request.update_temporaries),
  [defines.events.on_player_gun_inventory_changed] = h():chain(logistic_request.update_temporaries),
  [defines.events.on_player_main_inventory_changed] = h():chain(logistic_request.update_temporaries),
  ["fpal-quick-trash-all"] = h():chain(logistic_request.quick_trash_all),
}

return logistic_request
