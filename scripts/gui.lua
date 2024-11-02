local flib_gui = require("__flib__.gui")
local dictionary = require("__flib__.dictionary")

local search_gui = require("scripts.gui.search")
local infinity_filter_gui = require("scripts.gui.infinity-filter")
local logistic_request_gui = require("scripts.gui.logistic-request")

local gui = {}

function gui.init(player, player_table)
  -- show message if needed
  if player_table.flags.show_message_after_translation then
    player.print({ "message.fpal-can-open-gui" })
  end
  -- update flags
  player_table.flags.can_open_gui = true
  player_table.flags.show_message_after_translation = false
  -- create GUIs
  infinity_filter_gui.build(player, player_table)
  logistic_request_gui.build(player, player_table)
  search_gui.build(player, player_table)
  -- enable shortcut
  player.set_shortcut_available("fpal-search", true)
end

gui.events = {
  [dictionary.on_player_dictionaries_ready] = function(e)
    local player = game.get_player(e.player_index)
    local player_table = storage.players[e.player_index]
    if not player_table then
      player.print("no player table found, skipping gui init")
      return
    end
    gui.init(player, player_table)
  end
}

return gui
