local flib_gui = require("__flib__.gui")
local dictionary = require("__flib__.dictionary")
local search_gui = require("scripts.gui.search")
local request_gui = require("scripts.gui.logistic-request")
local recipe_gui = require("scripts.gui.recipe-request")
local requests = require("scripts.sources.logistic-request")

remote.add_interface("factory-palette.source.regression", {
  search = function(args)
    local results = {}
    for i = 1, tonumber(args.query) or 0 do
      results[i] = { caption = { "Result " .. i } }
    end
    return results
  end,
})

local function dispatch(player, element, event, text)
  assert(flib_gui.dispatch({ player_index = player.index, element = element, name = event, text = text }))
end

local function run()
  local player = assert(game.get_player(1), "save must contain a player")
  player.force.character_logistic_requests = true
  if not player.character then
    player.set_controller({ type = defines.controllers.god })
    assert(player.create_character(), "save must support creating a character")
  end
  player.get_main_inventory().clear()
  player.cursor_stack.clear()
  for _, section in
    pairs(player.character.get_logistic_point(defines.logistic_member_index.character_requester).sections)
  do
    section.filters = {}
  end
  local player_table = storage.players[player.index]
  assert(player_table.flags.can_open_gui and player.is_shortcut_available("fpal-search"))
  search_gui.build(player, player_table)
  local prepared_window = player_table.guis.search.elems.fpal_window
  local prepared_textfield = player_table.guis.search.elems.search_textfield
  search_gui.open(player, player_table)
  assert(prepared_window.valid and player.opened == prepared_window, "opening must reuse the prepared window")
  assert(player_table.guis.search.elems.search_textfield == prepared_textfield, "opening must reuse the textfield")
  -- Input is available during translation, and readiness must preserve it.
  prepared_textfield.text = "iron"
  dispatch(player, prepared_textfield, defines.events.on_gui_text_changed, "iron")
  script.raise_event(dictionary.on_player_dictionaries_ready, { player_index = player.index })
  assert(player.opened == prepared_window and prepared_textfield.valid)
  assert(prepared_textfield.text == "iron" and player_table.guis.search.state.query == "iron")

  for name in pairs(player_table.enabled_sources) do
    player_table.enabled_sources[name] = name == "regression"
  end
  local gui = player_table.guis.search
  for _, count in ipairs({ 0, 1, 20, 1, 0 }) do
    local text = string.format("%02d", count)
    gui.elems.search_textfield.text = text
    dispatch(player, gui.elems.search_textfield, defines.events.on_gui_text_changed, text)
    assert(#gui.state.results == count)
    assert(#gui.elems.results_table.children == count * 4)
    assert(gui.state.selected_index == 1)
    assert(gui.elems.results_scroll_pane.style.minimal_height == math.min(count, 10) * 28 + 6)
  end

  -- Reopening must start a fresh search without rebuilding the focused textfield.
  gui.elems.search_textfield.text = "20"
  dispatch(player, gui.elems.search_textfield, defines.events.on_gui_text_changed, "20")
  gui.state.selected_index = 20
  search_gui.close(player, player_table, true)
  search_gui.open(player, player_table)
  assert(prepared_window.valid and player.opened == prepared_window)
  assert(gui.elems.search_textfield == prepared_textfield and prepared_textfield.text == "")
  assert(gui.state.query == "" and gui.state.raw_query == "" and gui.state.selected_index == 1)
  assert(#gui.state.results == 0 and #gui.elems.results_table.children == 0)
  assert(player.is_shortcut_toggled("fpal-search"))
  assert(player_table.enabled_sources.regression and not player_table.enabled_sources.items)

  -- Restore a missing window before opening (for example, after another mod removes it).
  search_gui.close(player, player_table, true)
  prepared_window.destroy()
  search_gui.open(player, player_table)
  assert(player.opened.valid and player.opened == player_table.guis.search.elems.fpal_window)
  assert(player_table.guis.search.elems.search_textfield.valid)

  for _, case in ipairs({
    { "Iron Plate", "iron", false, true },
    { "Iron Plate", "iPl", false, false },
    { "Iron Plate", "iPl", true, true },
    { "Iron Plate", "zz", true, false },
    { "Iron Plate", ".", false, false },
  }) do
    assert(not not remote.call("factory-palette.filter", "filter", case[1], case[2], case[3]) == case[4])
  end

  request_gui.build(player, player_table)
  request_gui.open(player, player_table, { name = "iron-plate", translation = "Iron plate" })
  local elems = player_table.guis.request.elems
  elems.min_textfield.text = "100"
  elems.max_textfield.text = "20"
  request_gui.set_request(player, player_table, false, true)
  local section = requests.get_section(player, "Factory Palette: Default")
  assert(section.filters[1].min == 100 and section.filters[1].max == 100)

  local ingredients, amount = recipe_gui.prepare(prototypes.recipe["copper-cable"], "copper-cable")
  recipe_gui.open(player, player_table, { name = "copper-cable", translation = "Copper cable" }, ingredients, amount)
  local count = player_table.guis.recipe_request.elems.count
  count.text = "1.5"
  dispatch(player, count, defines.events.on_gui_confirmed)
  assert(player_table.guis.recipe_request, "fractional counts must leave the dialog open")
  count.text = "3"
  dispatch(player, count, defines.events.on_gui_confirmed)
  local temporary = requests.get_section(player, "Factory Palette: Temporary")
  assert(temporary.filters[1].value.name == "copper-plate" and temporary.filters[1].min == 2)

  -- A normal maximum must retain fulfilled temporary surplus until it is used.
  requests.set(player, player_table, "copper-plate", { min = 0, max = 1 }, false)
  player.insert({ name = "copper-plate", count = 2 })
  requests.update_temporaries({ player = player, player_table = player_table })
  assert(temporary.filters[1].min == 0 and not temporary.filters[1].max, "surplus must have no maximum")
  player.remove_item({ name = "copper-plate", count = 1 })
  requests.update_temporaries({ player = player, player_table = player_table })
  assert(not temporary.filters[1], "surplus request must clear after returning below the normal maximum")
  log("FACTORY PALETTE REGRESSION PASS")
end

return {
  events = {
    [defines.events.on_tick] = function()
      if not storage.regression_done then
        storage.regression_done = true
        run()
      end
    end,
  },
}
