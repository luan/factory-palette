local handler = require("__core__.lualib.event_handler")

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
