local flib_table = require("__flib__.table")
local dictionary = require("__flib__.dictionary")

local constants = require("constants")

local search = {
  _sources = {},
}

-- Helper function to check if a string starts with a prefix
local function starts_with(str, prefix)
  return string.sub(str, 1, #prefix) == prefix
end

local function all_sources(player_index)
  if search._sources[player_index] then
    return search._sources[player_index]
  end
  local sources = {}
  for interface in pairs(remote.interfaces) do
    if starts_with(interface, "factory-palette.source.") then
      local name = string.gsub(interface, "factory%-palette.source%.", "")
      sources[name] = interface
    end
  end
  search._sources[player_index] = sources
  return sources
end

-- Helper function to get matching sources based on prefix
local function get_matching_sources(prefix, player_index)
  local matches = {}
  local sources = all_sources(player_index)
  for name, interface in pairs(sources) do
    if starts_with(string.lower(name), string.lower(prefix)) then
      -- Only include if we actually have this source
      if remote.interfaces[interface] then
        matches[name] = interface
      end
    end
  end
  return matches
end

function search.search(player, player_table, query)
  local all_results = {}

  -- Check if query ends with just a space
  local prefix = string.match(query, "^(%S+)%s+$")
  if prefix then
    -- Show matching sources but no results yet
    local matching_sources = get_matching_sources(prefix, player.index)
    if next(matching_sources) then
      return {}, matching_sources
    end
  end

  -- Check if query starts with a source prefix
  local first_word, remaining = string.match(query, "^(%S+)%s+(.+)$")
  local sources_to_search = all_sources(player.index)
  local filtered_sources = nil

  if first_word and remaining then
    local matching_sources = get_matching_sources(first_word, player.index)
    if next(matching_sources) then
      sources_to_search = matching_sources
      filtered_sources = matching_sources
      query = remaining
    end
  end

  for source_name, source_interface in pairs(sources_to_search) do
    local source_results = remote.call(source_interface, "search", player, player_table, query)
    for _, result in pairs(source_results) do
      result.source = source_name
    end
    all_results = flib_table.array_merge({ all_results, source_results })
  end
  return all_results, filtered_sources
end

return search
