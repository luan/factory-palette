local dictionary = require("__flib__.dictionary")

local constants = require("constants")
local cursor = require("scripts.cursor")
local inventory = require("scripts.sources.inventory")
local logistic_request_gui = require("scripts.gui.logistic-request")

local function tooltip(result)
  return {
    "",
    { "gui.fpal-click-tooltip" },
    " ",
    { "gui.fpal-set-in-cursor" },
    "\n",
    { "gui.fpal-shift-click-tooltip" },
    " ",
    { "gui.fpal-set-logistic-request" },
    "\n",
    { "gui.fpal-control-click-tooltip" },
    " ",
    { "factory-palette.source.items.craft" },
    "\n",
    { "gui.fpal-control-shift-click-tooltip" },
    " ",
    { "factory-palette.source.items.craft-many" },
  }
end

local function search(args)
  local player, player_table, query, fuzzy = args.player, args.player_table, args.query, args.fuzzy
  local settings = player_table.settings
  local translations = dictionary.get(player.index, "item")

  local item_prototypes = prototypes.item
  local character = player.character

  -- settings
  local show_hidden = settings.show_hidden

  local connected_to_network = false
  local logistic_requests_available = false
  local results = {}

  local combined_contents = inventory.get_combined_contents(player, player.get_main_inventory())
  local contents = {
    inbound = {},
    inventory = combined_contents,
    logistic = {},
    outbound = {},
  }

  local controller_type = player.controller_type
  local requests_by_name = {}

  -- get logistic network and related contents
  if character and character.valid then
    logistic_requests_available = player.force.character_logistic_requests
    if logistic_requests_available then
      local logistic_point = character.get_logistic_point(defines.logistic_member_index.character_requester)
      if logistic_point then
        for _, section in ipairs(logistic_point.sections) do
          for _, filter in ipairs(section.filters) do
            if filter.value and filter.value.name then
              requests_by_name[filter.value.name] = filter
            end
          end
        end
      end
    end

    for _, data in ipairs(constants.logistic_point_data) do
      local point = character.get_logistic_point(data.logistic_point)
      if point and point.valid then
        contents[data.deliveries_table] = point[data.source_table]
        if data.point_name == "requester" then
          local logistic_network = point.logistic_network
          if logistic_network.valid then
            connected_to_network = true
            contents.logistic = logistic_network.get_contents()
          end
        end
      end
    end
  end

  -- perform search
  local i = 0
  for name, translation in pairs(translations) do
    if remote.call("factory-palette.filter", "filter", translation, query, fuzzy) then
      local hidden = false -- item_prototypes[name].has_flag("hidden")
      if show_hidden or not hidden then
        local inventory_count = contents.inventory[name] or 0
        local logistic_count = contents.logistic[name] or 0

        local result = {
          name = name,
          hidden = hidden,
          inventory = inventory_count,
          connected_to_network = connected_to_network,
          logistic_requests_available = logistic_requests_available,
          logistic = logistic_count,
          translation = translation,
          tooltip = tooltip(result),
        }
        result.remote = {
          "factory-palette.source.items",
          "select",
          { player_index = player.index, query = query, result = result },
        }

        if controller_type == defines.controllers.character then
          -- add logistic request, if one exists
          local request = requests_by_name[name]
          if request then
            result.request = { min = request.min, max = request.max or math.max_uint }
          end
          -- determine logistic request color
          local color
          if contents.inbound[name] then
            color = "inbound"
          elseif contents.outbound[name] then
            color = "outbound"
          elseif request and (inventory_count or 0) < request.min then
            color = "unsatisfied"
          else
            color = "normal"
          end
          result.request_color = color
        end

        local inventory_caption = inventory_count
        if player.controller_type == defines.controllers.character and connected_to_network then
          inventory_caption = (
            inventory_count
            .. " / [color="
            .. constants.colors.logistic_str
            .. "]"
            .. logistic_count
            .. "[/color]"
          )
        else
          inventory_caption = inventory_count
        end

        local request_label = ""
        if logistic_requests_available then
          local request = requests_by_name[name]
          if request then
            local max = request.max or math.max_uint
            if max == math.max_uint then
              max = constants.infinity_rep
            end
            request_label = request.min .. " / " .. max
            if request.is_temporary then
              request_label = "(T) " .. request_label
            end
            if request_label.style then
              request_label.style.font_color = constants.colors[result.request_color or "normal"]
            end
          else
            request_label = "--"
          end
        else
          request_label = ""
        end

        result.caption = { "[item=" .. name .. "]  " .. translation, inventory_caption, request_label }

        i = i + 1
        results[i] = result
      end
    end
    if i > constants.results_limit then
      break
    end
  end

  return results
end

---@param player LuaPlayer
---@param result Result
local function craft(player, result, count)
  local player_table = storage.players[player.index]
  if not player_table then
    return
  end

  local recipe = player.force.recipes[result.name]
  if not recipe then
    return
  end

  if recipe.prototype.hidden_from_player_crafting then
    return
  end

  local crafting_count = player.begin_crafting({ count = count, recipe = recipe })
  return crafting_count == count
end

---@param player LuaPlayer
---@param result Result
local function set_logistic_request(player, result)
  local player_table = storage.players[player.index]
  if not player_table then
    return
  end

  local gui_data = player_table.guis.search
  local elems = gui_data.elems
  local state = gui_data.state
  local player_controller = player.controller_type
  if player_controller == defines.controllers.editor or player_controller == defines.controllers.character then
    state.subwindow_open = true
    elems.search_textfield.enabled = false
    elems.fpal_window_dimmer.visible = true
    elems.fpal_window_dimmer.bring_to_front()

    if player_controller == defines.controllers.character then
      logistic_request_gui.open(player, player_table, result)
    end
    return true
  end

  return false
end

---@param player LuaPlayer
---@param result Result
local function set_in_cursor(player, result)
  local player_table = storage.players[player.index]
  if not player_table then
    return
  end

  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == result.name then
    player.create_local_flying_text({ text = { "message.fpal-already-holding-item" }, create_at_cursor = true })
    return false
  else
    cursor.set_stack(player, player.cursor_stack, player_table, result.name)
    return true
  end
end

local function select(data, modifiers)
  local player = game.players[data.player_index]
  if not player then
    return
  end

  local result = data.result
  if not result then
    return
  end

  if modifiers.control and modifiers.shift then
    return craft(player, result, 10)
  elseif modifiers.control then
    return craft(player, result, 5)
  elseif modifiers.shift then
    return set_logistic_request(player, result)
  end

  return set_in_cursor(player, result)
end

remote.add_interface("factory-palette.source.items", {
  search = search,
  select = select,
})
