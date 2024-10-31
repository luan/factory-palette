local handler = require("__core__.lualib.event_handler")
-- local dictionary = require("__flib__.dictionary")

-- local infinity_filter = require("scripts.infinity-filter")
-- local logistic_request = require("scripts.logistic-request")
-- local search = require("scripts.search")

-- local infinity_filter_gui = require("scripts.gui.infinity-filter")
-- local logistic_request_gui = require("scripts.gui.logistic-request")
-- local search_gui = require("scripts.gui.search")

handler.add_libraries({
    require("scripts.migrations"),
    
    require("__flib__.gui"),
    require("__flib__.dictionary"),

    require("scripts.global-data"),
    require("scripts.gui"),
    require("scripts.gui.search"),
    require("scripts.player-data"),
})

script.on_event("fpal-quick-trash-all", function(e)
    game.reload_script()
end)

--[[
-- Custom input
script.on_event({ "fpal-confirm", "fpal-shift-confirm", "fpal-control-confirm" }, function(e)
    local player = game.get_player(e.player_index)
    if not player then
        return
    end
    local player_table = storage.players[e.player_index]

    -- HACK: This makes it easy to check if we should close the search GUI or not
    player_table.confirmed_tick = game.ticks_played

    local is_shift = e.input_name == "fpal-shift-confirm"
    local is_control = e.input_name == "fpal-control-confirm"

    local opened = player.opened
    if opened and player.opened_gui_type == defines.gui_type.custom then
        if opened.name == "fpal_search_window" then
            search_gui.select_item(player, player_table, { shift = is_shift, control = is_control })
        elseif opened.name == "fpal_request_window" then
            if is_control then
                logistic_request_gui.clear_request(player, player_table)
            else
                logistic_request_gui.set_request(player, player_table, is_shift)
            end
        elseif opened.name == "fpal_infinity_filter_window" then
            if is_control then
                infinity_filter_gui.clear_filter(player, player_table)
            else
                infinity_filter_gui.set_filter(player, player_table, is_shift)
            end
        end
    end
end)

script.on_event("fpal-cycle-infinity-filter-mode", function(e)
    local player_table = storage.players[e.player_index]
    local gui_data = player_table.guis.infinity_filter
    if gui_data then
        local state = gui_data.state
        if state.visible then
            infinity_filter_gui.cycle_filter_mode(gui_data)
        end
    end
end)

-- TODO: split into the modules
script.on_event("fpal-quick-trash-all", function(e)
    local player = game.get_player(e.player_index)
    if not player then
        return
    end
    local player_table = storage.players[e.player_index]
    if player.controller_type == defines.controllers.character and player.force.character_logistic_requests then
        logistic_request.quick_trash_all(player, player_table)
    elseif player.controller_type == defines.controllers.editor then
        infinity_filter.quick_trash_all(player, player_table)
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
