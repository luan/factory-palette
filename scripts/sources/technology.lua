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
  local translations = dictionary.get(player.index, "technology")
  local results = {}
  for name, translation in pairs(translations) do
    if string.find(string.lower(translation), query) then
      local result = {
        name = name,
        caption = { "[technology=" .. name .. "]  " .. translation },
        translation = translation,
        tooltip = tooltip(result),
        remote = {
          "factory-palette.technology",
          "open_technology",
          { player_index = player.index, technology_name = name },
        },
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

remote.add_interface("factory-palette.technology", {
  open_technology = function(data)
    if data.technology_name then
      local player = game.players[data.player_index]
      if player then
        player.open_technology_gui(data.technology_name)
      end
    end
  end,
})

return search.add_source("technology", run)
