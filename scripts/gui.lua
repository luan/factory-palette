local flib_gui = require("__flib__.gui")
local dictionary = require("__flib__.dictionary")

local h = require("handlers").for_player()

local player_data = require("scripts.player-data")

local search_gui = require("scripts.gui.search")
local logistic_request_gui = require("scripts.gui.logistic-request")

local gui = {}

function gui.init(args)
  local player = args.player
  local player_table = args.player_table
  -- show message if needed
  if player_table.flags.show_message_after_translation then
    player.print({ "message.fpal-can-open-gui" })
  end
  -- update flags
  player_table.flags.can_open_gui = true
  player_table.flags.show_message_after_translation = false
  -- create GUIs
  logistic_request_gui.build(player, player_table)
  search_gui.build(player, player_table)
  -- enable shortcut
  player.set_shortcut_available("fpal-search", true)
end

gui.events = {
  [dictionary.on_player_dictionaries_ready] = h():chain(gui.init),
}

return gui
