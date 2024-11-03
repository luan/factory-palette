local flib_table = require("__flib__.table")

local constants = require("constants")

local search = {
  sources = {},
}

function search.run(player, player_table, query, combined_contents)
  local all_results = {}
  for _, source in pairs(search.sources) do
    local source_results = source(player, player_table, query, combined_contents)
    all_results = flib_table.array_merge({ all_results, source_results })
  end
  return all_results
end

function search.add_source(name, source)
  search.sources[name] = source
end

return search
