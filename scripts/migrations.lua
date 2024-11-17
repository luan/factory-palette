local flib_migration = require("__flib__.migration")

local by_version = {
  ["0.2.1"] = function()
  ---@type table<number, FpalPlayerTable>
  local players = storage.players
  for _, player_table in ipairs(players) do
    player_table.logistic_requests.temporary = {}
  end
  end,
}

--- @param e ConfigurationChangedData
local function on_configuration_changed(e)
  flib_migration.on_config_changed(e, by_version)
end

local migrations = {}

migrations.on_configuration_changed = on_configuration_changed

return migrations
