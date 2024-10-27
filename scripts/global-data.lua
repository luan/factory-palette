local dictionary = require("__flib__.dictionary")

local global_data = {}

function global_data.init()
    storage.players = {}
    storage.update_search_results = {}
end

function global_data.build_dictionary()
    dictionary.new("item")
    for name, prototype in pairs(prototypes.item) do
        dictionary.add("item", name, prototype.localised_name)
    end
end

return global_data
