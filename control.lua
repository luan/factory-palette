local handler = require("__core__.lualib.event_handler")
-- local dictionary = require("__flib__.dictionary")

-- local logistic_request = require("scripts.logistic-request")
-- local search = require("scripts.search")

-- local logistic_request_gui = require("scripts.gui.logistic-request")
-- local search_gui = require("scripts.gui.search")

handler.add_libraries({
  require("scripts.migrations"),

  require("__flib__.gui"),
  require("__flib__.dictionary"),

  require("scripts.logistic-request"),

  require("scripts.global-data"),
  require("scripts.gui"),
  require("scripts.gui.search"),
  require("scripts.player-data"),

  require("scripts.sources.items"),
  require("scripts.sources.shortcuts"),
})

script.on_event("fpal-quick-trash-all", function(e)
  game.reload_script()
end)

--[[
-- Custom input
-- TODO: split into the modules
script.on_event("fpal-quick-trash-all", function(e)
    local player = game.get_player(e.player_index)
    if not player then
        return
    end
    local player_table = storage.players[e.player_index]
    if player.controller_type == defines.controllers.character and player.force.character_logistic_requests then
        logistic_request.quick_trash_all(player, player_table)
    end
end)

-- Entity

script.on_event(defines.events.on_entity_logistic_slot_changed, function(e)
    local entity = e.entity
    if entity and entity.valid and entity.type == "character" then
        local player = entity.player -- event does not provide player_index every time
        -- sometimes the player won't exist because it's in a cutscene
        if player then
            local player_table = storage.players[player.index]
            if player_table then
                logistic_request.update(player, player_table, e.section, e.slot_index)
            end
        end
    end
end)

-- Settings

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
    if string.sub(e.setting, 1, 4) == "fpal-" and e.setting_type == "runtime-per-user" then
        local player = game.get_player(e.player_index)
        if not player then
            return
        end
        local player_table = storage.players[e.player_index]
        player_data.update_settings(player, player_table)
    end
end)

-- Tick

script.on_event(defines.events.on_tick, function()
    dictionary.on_tick()

    if next(storage.update_search_results) then
        search_gui.update_for_active_players()
    end
end)
--]]
