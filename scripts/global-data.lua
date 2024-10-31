local dictionary = require("__flib__.dictionary")

local global_data = {}

function global_data.on_init()
    storage.players = {}
    storage.update_search_results = {}
    global_data.on_configuration_changed()
end

function global_data.on_configuration_changed()
    dictionary.new("item")
    for name, prototype in pairs(prototypes.item) do
        dictionary.add("item", name, prototype.localised_name)
    end
end

return global_data
