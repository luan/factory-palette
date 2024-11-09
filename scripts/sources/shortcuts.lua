local dictionary = require("__flib__.dictionary")

local constants = require("constants")

local search = require("scripts.search")

local function tooltip(result)
  return {
    "",
    { "gui.fpal-click-tooltip" },
    " ",
    { "gui.fpal-confirm-tooltip" },
  }
end

local function run(player, player_table, query, combined_contents)
  local i = 0
  local translations = dictionary.get(player.index, "shortcut")
  local results = {}
  for name, translation in pairs(translations) do
    if string.find(string.lower(translation), query) then
      local result = {
        name = name,
        caption = { "[shortcut=" .. name .. "]  " .. translation },
        translation = translation,
        remote = { "Shortcuts-ick", "on_lua_shortcut", { player_index = player.index, prototype_name = name } },
        tooltip = tooltip(result),
      }

      i = i + 1
      results[i] = result
    end
    if i > constants.results_limit then
      break
    end
  end

  return results
end

return {
  on_init = function()
    search.add_source("shortcuts", run)
  end,
  on_load = function()
    search.add_source("shortcuts", run)
  end,
}
