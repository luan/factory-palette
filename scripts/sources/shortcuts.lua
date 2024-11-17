local dictionary = require("__flib__.dictionary")

local constants = require("constants")

local function tooltip(result)
  return {
    "",
    { "gui.fpal-click-tooltip" },
    " ",
    { "gui.fpal-confirm-tooltip" },
  }
end

local function search(player, player_table, query)
  local i = 0
  local translations = dictionary.get(player.index, "shortcut")
  local results = {}
  for name, translation in pairs(translations) do
    if string.find(string.lower(translation), query) then
      local result = {
        name = name,
        caption = { "[shortcut=" .. name .. "]  " .. translation },
        translation = translation,
        remote = {
          "factory-palette.source.shortcuts",
          "select",
          { player_index = player.index, prototype_name = name },
        },
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

local function select(data, modifiers)
  local player = game.players[data.player_index]
  if not player then
    return
  end

  local result = data.result
  if not result then
    return
  end

  remote.call("Shortcuts", "on_lua_shortcut", data)

  return true
end

remote.add_interface("factory-palette.source.shortcuts", {
  search = search,
  select = select,
})

