local search = {}

-- Helper function to check if a string starts with a prefix
local function starts_with(str, prefix)
  return string.sub(str, 1, #prefix) == prefix
end

function search.all_sources()
  local sources = {}
  for interface in pairs(remote.interfaces) do
    if starts_with(interface, "factory-palette.source.") then
      local name = string.gsub(interface, "factory%-palette.source%.", "")
      sources[name] = interface
    end
  end
  return sources
end

-- Helper function to get matching sources based on prefix
local function get_matching_sources(prefix)
  local matches = {}
  local sources = search.all_sources()
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

function search.search(player, player_table, query, fuzzy)
  local all_results = {}

  -- Check if query ends with just a space
  local prefix = string.match(query, "^(%S+)%s+$")
  if prefix then
    -- Show matching sources but no results yet
    local matching_sources = get_matching_sources(prefix)
    if next(matching_sources) then
      return {}, matching_sources
    end
  end

  -- Check if query starts with a source prefix
  local first_word, remaining = string.match(query, "^(%S+)%s+(.+)$")
  local sources_to_search = search.all_sources()
  local filtered_sources = nil

  if first_word and remaining then
    local matching_sources = get_matching_sources(first_word)
    if next(matching_sources) then
      sources_to_search = matching_sources
      filtered_sources = matching_sources
      query = remaining
    end
  end

  -- Filter out disabled sources
  local enabled_sources = {}
  for name, interface in pairs(sources_to_search) do
    if player_table.enabled_sources[name] then
      enabled_sources[name] = interface
    end
  end
  sources_to_search = enabled_sources

  for source_name, source_interface in pairs(sources_to_search) do
    local source_results = remote.call(
      source_interface,
      "search",
      { player = player, player_table = player_table, query = query, fuzzy = fuzzy }
    )
    for _, result in ipairs(source_results) do
      result.source = source_name
      all_results[#all_results + 1] = result
    end
  end
  return all_results, filtered_sources
end

return search
