local flib_math = require("__flib__.math")
local inventory = require("scripts.sources.inventory")

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
  local section = logistic_request.get_section(player, is_temporary and Sections.Temporary or Sections.Default, true)
  if not section then
    return
  end

  -- search for first empty slot
  local index = section.filters_count + 1
  for i, filter in ipairs(section.filters) do
    local value = filter.value
    if value and value.type == "item" and value.name == name then
      index = i
      break
    end
  end

  section.set_slot(index, {
    value = name,
    min = counts.min,
    max = counts.max,
  })
  if is_temporary then
    logistic_request.update_temporaries({ player = player, player_table = player_table })
  end
end

---@param player LuaPlayer
---@param player_table FpalPlayerTable
---@param name string
function logistic_request.clear(player, name)
  local section = logistic_request.get_section(player, Sections.Default)
  if not section then
    return
  end
  for i, filter in ipairs(section.filters) do
    if filter.value and filter.value.name == name then
      section.clear_slot(i)
      break
    end
  end
end

---@param player LuaPlayer
---@param group keyof Sections
---@return LuaLogisticSection?
function logistic_request.get_section(player, group, create)
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

  if create then
    return logistic_point.add_section(group)
  end
end

local function other_request_max(logistic_point, name)
  local max
  for _, section in ipairs(logistic_point.sections) do
    if section.active and section.group ~= Sections.Temporary then
      for _, filter in ipairs(section.filters) do
        if
          filter.value
          and filter.value.type == "item"
          and filter.value.name == name
          and filter.value.quality == "normal"
          and filter.value.comparator == "="
        then
          if filter.max then
            max = math.min((max or 0) + math.floor(filter.max * section.multiplier), flib_math.max_uint)
          else
            return flib_math.max_uint
          end
        end
      end
    end
  end
  return max
end

---@param args {player: LuaPlayer, player_table: FpalPlayerTable}
function logistic_request.update_temporaries(args)
  local player = args.player
  local player_table = args.player_table
  local temporary_section = logistic_request.get_section(player, Sections.Temporary)
  if not temporary_section then
    return
  end
  local logistic_point = player.character.get_logistic_point(defines.logistic_member_index.character_requester)

  local combined_contents = inventory.get_combined_contents(player, player.get_main_inventory(), "normal")
  for index, filter in ipairs(temporary_section.filters) do
    if filter.value then
      local name = filter.value.name
      local has_count = combined_contents[name] or 0
      local normal_max = other_request_max(logistic_point, name)
      if not normal_max and logistic_point.trash_not_requested then
        normal_max = 0
      end
      if filter.min and has_count >= filter.min and (not filter.max or has_count <= filter.max) then
        if normal_max and has_count > normal_max then
          if filter.min ~= 0 then
            -- Keep excess items without requesting replacements until they are used.
            temporary_section.set_slot(index, { value = name, min = 0, max = flib_math.max_uint })
          end
        else
          temporary_section.clear_slot(index)
        end
      end
    end
  end
end

---@param player LuaPlayer
---@param player_table FpalPlayerTable
function logistic_request.quick_trash_all(player, player_table)
  local logistic_point = player.character
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
