local handler = require("__core__.lualib.event_handler")
local search = require("scripts.search")

require("scripts.sources.items")
require("scripts.sources.shortcuts")
require("scripts.sources.technology")

handler.add_libraries({
  require("scripts.migrations"),

  require("__flib__.gui"),
  require("__flib__.dictionary"),

  require("scripts.global-data"),

  require("scripts.sources.logistic-request"),
  require("scripts.search"),
  require("scripts.gui"),
  require("scripts.gui.search"),
  require("scripts.player-data"),
})

remote.add_interface("factory-palette.filter", {
  filter = search.filter,
})
