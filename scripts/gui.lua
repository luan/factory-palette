local dictionary = require("__flib__.dictionary")

local h = require("handlers").for_player()

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
  -- Translation completion must preserve an open palette and its typed query.
  local gui_data = player_table.guis.search
  if gui_data and gui_data.elems.fpal_window.valid then
    if gui_data.state.visible and not gui_data.state.subwindow_open then
      search_gui.perform_search(player, player_table, gui_data)
    end
  else
    logistic_request_gui.build(player, player_table)
    search_gui.build(player, player_table)
  end
  -- enable shortcut
  player.set_shortcut_available("fpal-search", true)
end

gui.events = {
  [dictionary.on_player_dictionaries_ready] = h():chain(gui.init),
}

return gui
