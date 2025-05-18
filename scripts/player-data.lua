---@class FpalPlayerTable
---@field flags table<string, boolean>
---@field guis table<string, any>
---@field logistic_requests FpalLogisticRequests -- TODO: move this to items source
---@field settings table<string, any>
---@field enabled_sources table<string, boolean>

---@class FpalLogisticRequests
---@field by_index table<number, FpalLogisticRequest>
---@field by_name table<string, FpalLogisticRequest>
---@field temporary table<string, FpalLogisticRequest>

---@class FpalLogisticRequest
---@field name string
---@field min number
---@field max number
---@field age number

local dictionary = require("__flib__.dictionary")
local constants = require("constants")

local logistic_request_gui = require("scripts.gui.logistic-request")
local search_gui = require("scripts.gui.search")

local player_data = {}

function player_data.on_init()
  storage.players = {}
  for i in pairs(game.players) do
    player_data.init(i)
  end
end

function player_data.on_runtime_mod_setting_changed(e)
  if string.sub(e.setting, 1, 4) == "fpal-" and e.setting_type == "runtime-per-user" then
    local player = game.get_player(e.player_index)
    if not player then
      return
    end
    local player_table = storage.players[e.player_index]
    player_data.update_settings(player, player_table)
  end
end

function player_data.on_configuration_changed()
  for i in pairs(game.players) do
    player_data.refresh(game.get_player(i), storage.players[i])
  end
end

--- @param player_index number
function player_data.init(player_index)
  storage.players[player_index] = {
    flags = {
      can_open_gui = false,
      show_message_after_translation = false,
    },
    guis = {},
    logistic_requests = { by_index = {}, by_name = {}, temporary = {} },
    settings = {},
    enabled_sources = {},
  }
  player_data.refresh(game.get_player(player_index), storage.players[player_index])
end

function player_data.refresh(player, player_table)
  -- destroy GUIs
  if player_table.guis.request then
    logistic_request_gui.destroy(player_table)
  end
  if player_table.guis.search then
    search_gui.destroy(player_table)
  end

  -- update settings
  player_data.update_settings(player, player_table)

  -- Rebuild GUIs and re-enable shortcuts if dictionaries are ready
  local translations = dictionary.get(player.index, "item")
  if translations then
    logistic_request_gui.build(player, player_table)
    search_gui.build(player, player_table)
    player.set_shortcut_available("fpal-search", true)
    player_table.flags.can_open_gui = true
  else
    -- If dictionaries aren't ready, mark for enabling after translation
    player_table.flags.show_message_after_translation = true
    player_table.flags.can_open_gui = false
    player.set_shortcut_available("fpal-search", false)
  end
end

function player_data.update_settings(player, player_table)
  if not player or not player_table then
    return
  end

  local player_settings = player.mod_settings
  local settings = {}

  for internal, prototype in pairs(constants.settings) do
    settings[internal] = player_settings[prototype].value
  end

  player_table.settings = settings
end

local function update_focus_frame_size(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local player_table = storage.players[e.player_index]
  logistic_request_gui.update_focus_frame_size(player, player_table)
end

local on_player_inventory_changed = function(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local player_table = storage.players[e.player_index]

  local main_inventory = player.get_main_inventory()
  if main_inventory and main_inventory.valid then
    local gui_data = player_table.guis.search
    if gui_data then
      local state = gui_data.state
      if state.visible and not state.subwindow_open then
        search_gui.perform_search(player, player_table, gui_data, false)
      end
    end
  end
end

local function on_runtime_mod_setting_changed(e)
  if string.sub(e.setting, 1, 4) ~= "fpal-" or not e.player_index then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  player_data.update_settings(player, storage.players[e.player_index])
end

function init_player(e)
  player_data.init(e.player_index)
end

function remove_player(e)
  storage.players[e.player_index] = nil
end

player_data.events = {
  [defines.events.on_player_created] = init_player,
  [defines.events.on_player_removed] = remove_player,
  [defines.events.on_player_joined_game] = init_player,
  [defines.events.on_player_display_resolution_changed] = update_focus_frame_size,
  [defines.events.on_player_display_scale_changed] = update_focus_frame_size,
  [defines.events.on_player_ammo_inventory_changed] = on_player_inventory_changed,
  [defines.events.on_player_armor_inventory_changed] = on_player_inventory_changed,
  [defines.events.on_player_gun_inventory_changed] = on_player_inventory_changed,
  [defines.events.on_player_main_inventory_changed] = on_player_inventory_changed,
  [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
}

-- @export
return player_data
