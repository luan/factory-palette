local handler = require("__core__.lualib.event_handler")
local fzy = require("fzy")

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
  filter = function(haystack, needle, fuzzy)
    if fuzzy then
      return fzy.has_match(needle, haystack, false)
    else
      return string.find(string.lower(haystack), string.lower(needle), 1, true)
    end
  end,
})
