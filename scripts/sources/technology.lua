local dictionary = require("__flib__.dictionary")

local constants = require("constants")

local function tooltip(result)
  return {
    "",
    { "gui.fpal-click-tooltip" },
    " ",
    { "factory-palette.source.technology.open" },
    (result.available and not result.researched) and "\n" or "",
    (result.available and not result.researched) and { "gui.fpal-shift-click-tooltip" } or "",
    " ",
    (result.available and not result.researched)
        and (result.current and { "factory-palette.source.technology.remove" } or {
          "factory-palette.source.technology.add",
        })
      or "",
  }
end

---@param player LuaPlayer
---@param prototype LuaTechnologyPrototype
---@return LuaTechnology
local function get_technology(player, technology)
  return player.force.technologies[technology.name]
end

---@param player LuaPlayer
---@param prototype LuaTechnologyPrototype
local function add_research(player, prototype)
  local tech = get_technology(player, prototype)
  if tech then
    player.force.add_research(tech)
  end
end

---@param player LuaPlayer
---@param prototype LuaTechnologyPrototype
---@return boolean
local function is_available(player, prototype)
  local tech = get_technology(player, prototype)
  if not tech then
    return false
  end
  local prerequisites = tech.prerequisites
  if not prerequisites then
    return true
  end
  for _, prerequisite in pairs(prerequisites) do
    if not prerequisite.researched then
      return false
    end
  end
  return true
end

---@param player LuaPlayer
---@param prototype LuaTechnologyPrototype
---@return boolean
local function is_current(player, prototype)
  local tech = get_technology(player, prototype)
  if not tech then
    return false
  end
  return player.force.current_research and player.force.current_research.prototype == tech.prototype
end

local function search(args)
  local player, player_table, query, fuzzy = args.player, args.player_table, args.query, args.fuzzy
  local i = 0
  local translations = dictionary.get(player.index, "technology")
  local results = {}
  for name, translation in pairs(translations) do
    if remote.call("factory-palette.filter", "filter", translation, query, fuzzy) then
      local technology = get_technology(player, prototypes.technology[name])
      if technology then
        local current = is_current(player, technology)
        local available = is_available(player, technology)
        local color = technology.researched and "[color=green]" or available and "[color=white]" or "[color=60, 60, 60]"
        local current_caption = current and " [img=utility/played_green] " or ""
        local result = {
          name = name,
          current = current,
          available = available,
          researched = technology.researched,
          caption = { color .. "[technology=" .. name .. "]  " .. translation .. current_caption .. "[/color]" },
          translation = translation,
          remote = {
            "factory-palette.source.technology",
            "select",
            { player_index = player.index, technology = technology },
          },
        }

        result.tooltip = tooltip(result)

        i = i + 1
        results[i] = result
      end
    end
    if i > constants.results_limit then
      break
    end
  end

  -- Sort results by availability
  table.sort(results, function(a, b)
    -- Put available technologies first
    if a.available ~= b.available then
      return a.available
    end
    -- Then sort by name
    return a.translation < b.translation
  end)

  return results
end

local function select(data, modifiers)
  local player = game.players[data.player_index]
  if not player then
    return
  end
  local technology = data.technology
  if not technology then
    return
  end

  if modifiers.shift then
    add_research(player, technology)
    return true
  end

  if modifiers.control then
    return false
  end

  player.open_technology_gui(technology)

  return true
end

remote.add_interface("factory-palette.source.technology", {
  search = search,
  select = select,
})
