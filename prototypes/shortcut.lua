local data_util = require("__flib__.data-util")

local shortcut_file = "__factory-palette__/graphics/shortcut.png"

data:extend({
    {
        type = "shortcut",
        name = "fpal-search",
        icon = shortcut_file,
        icon_size = 32,
        small_icon = shortcut_file,
        small_icon_size = 24,
        toggleable = true,
        action = "lua",
        associated_control_input = "fpal-search",
    },
})
