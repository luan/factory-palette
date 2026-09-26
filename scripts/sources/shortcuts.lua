local dictionary = require("__flib__.dictionary")

local constants = require("constants")

local supported = {
  ["flashlight-toggle"] = true,
  ["signal-flare"] = true,
  ["draw-grid"] = true,
  ["rail-block-visualization-toggle"] = true,
  ["player-trash-not-requested"] = true,
  ["big-zoom"] = true,
  ["minimap"] = true,
  ["night-vision-equipment"] = true,
  ["belt-immunity-equipment"] = true,
  ["active-defense-equipment"] = true,
  ["driver-is-gunner"] = true,
  ["vehicle-logistics-while-moving"] = true,
  ["vehicle-logistic-requests"] = true,
  ["vehicle-trash-not-requested"] = true,
  ["targeting-with-gunner"] = true,
  ["targeting-without-gunner"] = true,
  ["train-mode-toggle"] = true,
  ["artillery-jammer-tool"] = true,
  ["tree-killer"] = true,
}

local function tooltip()
  return {
    "",
    { "gui.fpal-click-tooltip" },
    " ",
    { "gui.fpal-confirm-tooltip" },
  }
end

local function search(args)
  if not remote.interfaces["Shortcuts-ick"] then
    return {}
  end
  local player, query, fuzzy = args.player, args.query, args.fuzzy
  local i = 0
  local translations = dictionary.get(player.index, "shortcut")
  local results = {}
  for name, translation in pairs(translations) do
    if supported[name] and remote.call("factory-palette.filter", "filter", translation, query, fuzzy) then
      local result = {
        name = name,
        caption = { "[shortcut=" .. name .. "]  " .. translation },
        translation = translation,
        remote = {
          "factory-palette.source.shortcuts",
          "select",
          { player_index = player.index, prototype_name = name },
        },
        tooltip = tooltip(),
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

  if not supported[data.prototype_name] or not remote.interfaces["Shortcuts-ick"] then
    return false
  end
  remote.call("Shortcuts-ick", "on_lua_shortcut", data)

  return true
end

if script.active_mods["Shortcuts-ick"] then
  remote.add_interface("factory-palette.source.shortcuts", {
    search = search,
    select = select,
  })
end
