local spawn_item_tooltip = {
  "",
  { "mod-setting-description.fpal-spawn-items-when-cheating" },
  mods["space-exploration"] and { "", "\n\n", { "mod-setting-description.fpal-spawn-items-when-cheating-se-addendum" } }
    or "",
}

data:extend({
  {
    type = "bool-setting",
    name = "fpal-show-hidden",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "ad",
  },
  {
    type = "bool-setting",
    name = "fpal-fuzzy-search",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "ae",
  },
  {
    type = "bool-setting",
    name = "fpal-spawn-items-when-cheating",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "af",
    localised_description = spawn_item_tooltip,
  },
  {
    type = "bool-setting",
    name = "fpal-auto-close-window",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "ag",
  },
})
