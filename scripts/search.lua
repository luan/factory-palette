local flib_table = require("__flib__.table")
local dictionary = require("__flib__.dictionary")

local constants = require("constants")

local search = {
  sources = {},
}

-- Helper function to check if a string starts with a prefix
local function starts_with(str, prefix)
  return string.sub(str, 1, #prefix) == prefix
end

-- Helper function to get matching sources based on prefix
local function get_matching_sources(prefix, player_index)
  local matches = {}
  local translations = dictionary.get(player_index, "source")
  for name, translation in pairs(translations) do
    if starts_with(string.lower(translation), string.lower(prefix)) then
      if search.sources[name] then -- Only include if we actually have this source
        matches[name] = search.sources[name]
      end
    end
  end
  return matches
end

function search.run(player, player_table, query, combined_contents)
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
  local sources_to_search = search.sources
  local filtered_sources = nil

  if first_word and remaining then
    local matching_sources = get_matching_sources(first_word, player.index)
    if next(matching_sources) then
      sources_to_search = matching_sources
      filtered_sources = matching_sources
      query = remaining
    end
  end

  for source_name, source in pairs(sources_to_search) do
    local source_results = source(player, player_table, query, combined_contents)
    for _, result in pairs(source_results) do
      result.source = source_name
    end
    all_results = flib_table.array_merge({ all_results, source_results })
  end
  return all_results, filtered_sources
end

function search.add_source(name, source)
  local function add_source()
    search.sources[name] = source
  end
  return {
    on_init = add_source,
    on_configuration_changed = add_source,
    on_load = add_source,
  }
end

function search.on_init()
  search.on_configuration_changed()
end

function search.on_configuration_changed()
  for _, source in pairs(search.sources) do
    dictionary.add("source", name, { "fpal.sources." .. name })
  end
end

return search
