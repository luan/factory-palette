local by_version = {
  ["0.2.1"] = function()
    ---@type table<number, FpalPlayerTable>
    local players = storage.players
    for _, player_table in ipairs(players) do
      player_table.logistic_requests.temporary = {}
    end
  end,
  ["0.4.3"] = function()
    -- Refresh all players to fix GUI and shortcut state
    for _, player in pairs(game.players) do
      local player_table = storage.players[player.index]
      if player_table then
        -- Reset GUI flags
        player_table.flags.can_open_gui = false
        player_table.flags.show_message_after_translation = true
        -- Clear existing GUIs
        player_table.guis = {}
        -- Force shortcut reset
        player.set_shortcut_toggled("fpal-search", false)
        player.set_shortcut_available("fpal-search", false)
      end
    end
  end,
  ["0.5.0"] = function()
    -- Initialize enabled_sources for all players
    for _, player in pairs(game.players) do
      local player_table = storage.players[player.index]
      if player_table then
        player_table.enabled_sources = player_table.enabled_sources or {}
      end
    end
  end,
}

--- @param e ConfigurationChangedData
local function on_configuration_changed(e)
  local change = e.mod_changes[script.mod_name]
  local old_version = change and change.old_version
  if not old_version then
    return
  end

  for version, migrate in pairs(by_version) do
    if helpers.compare_versions(old_version, version) < 0 then
      migrate()
    end
  end
end

local migrations = {}

migrations.on_configuration_changed = on_configuration_changed

return migrations
