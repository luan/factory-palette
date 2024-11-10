local dictionary = require("__flib__.dictionary")

local constants = require("constants")

local search = require("scripts.search")

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
  }
end

local function get_combined_inventory_contents(player, main_inventory)
  -- main inventory contents
  local combined_contents = {}
  for _, item in ipairs(main_inventory.get_contents()) do
    combined_contents[item.name] = (combined_contents[item.name] or 0) + item.count
  end
  -- cursor stack
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read then
    combined_contents[cursor_stack.name] = (combined_contents[cursor_stack.name] or 0) + cursor_stack.count
  end
  -- other
  for _, inventory_def in ipairs({
    -- for some reason, the character_ammo and character_guns inventories work in the editor as well
    defines.inventory.character_ammo,
    defines.inventory.character_guns,
    -- defines.inventory.character_trash
  }) do
    local inventory = player.get_inventory(inventory_def)
    if inventory and inventory.valid then
      for _, item in ipairs(inventory.get_contents() or {}) do
        combined_contents[item.name] = (combined_contents[item.name] or 0) + item.count
      end
    end
  end

  return combined_contents, true
end

local function run(player, player_table, query)
  -- don't bother if they don't have a main inventory
  local main_inventory = player.get_main_inventory()
  if not main_inventory or not main_inventory.valid then
    return {}
  end

  local requests = player_table.logistic_requests
  local requests_by_name = requests.by_name
  local settings = player_table.settings
  local translations = dictionary.get(player.index, "item")

  local item_prototypes = prototypes.item
  local character = player.character

  -- settings
  local show_hidden = settings.show_hidden

  local connected_to_network = false
  local logistic_requests_available = false
  local results = {}

  local combined_contents = get_combined_inventory_contents(player, main_inventory)
  local contents = {
    inbound = {},
    inventory = combined_contents,
    logistic = {},
    outbound = {},
  }

  local controller_type = player.controller_type

  -- get logistic network and related contents
  if character and character.valid then
    logistic_requests_available = player.force.character_logistic_requests
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
    if string.find(string.lower(translation), query) then
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
            request_label.style.font_color = constants.colors[result.request_color or "normal"]
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

search.add_source("items", run)
