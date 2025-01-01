local flib_gui = require("__flib__.gui")
local math = require("__flib__.math")

local events = require("events")
local constants = require("constants")
local h = require("handlers").for_gui("search")

local cursor = require("scripts.cursor")
local search = require("scripts.search")

---@class SearchGuiState
---@field last_search_update number
---@field query string
---@field raw_query string
---@field selected_index number
---@field subwindow_open boolean
---@field visible boolean
---@field results? table[]
---@field selected_item_tick? number
local gui = {}
local handlers = {}

local tbl = {
  columns = 4,
}

function tbl.count(t)
  return #t.children / tbl.columns
end

function tbl.get_row(t, index)
  if #t.children < index * tbl.columns then
    return nil
  end
  local row = {}
  for i = 1, tbl.columns do
    table.insert(row, t.children[i + (index - 1) * tbl.columns])
  end
  return row
end

function tbl.set_row(t, index, row)
  for i = 1, tbl.columns do
    t.children[i] = row[i + (index - 1) * tbl.columns]
  end
end

function tbl.delete_row(t, index)
  for i = tbl.columns, 1, -1 do
    t.children[i + (index - 1) * tbl.columns].destroy()
  end
end

-- Handler functions
function handlers.on_close(args)
  gui.close(args.player, args.player_table)
end

function handlers.toggle_sidebar(args, e)
  local gui_data = args.gui_data
  gui_data.elems.sidebar.visible = not gui_data.elems.sidebar.visible
end

function handlers.on_tick()
  if next(storage.update_search_results) then
    gui.update_for_active_players()
  end
end

function handlers.select_entry(args, e)
  if e.shift then
    args.shift = true
  end
  if e.control then
    args.control = true
  end
  local player, player_table = args.player, args.player_table
  local index = nil
  if e.element and e.element.tags and e.element.tags.index then
    index = e.element.tags.index
  end
  player_table.confirmed_tick = game.ticks_played
  gui.select_entry(player, player_table, args, index)
end

function handlers.recenter(args, e)
  local player_table = args.player_table
  if e.button == defines.mouse_button_type.middle then
    player_table.guis.search.elems.fpal_window.force_auto_center()
  end
end

function handlers.relocate_dimmer(args)
  local gui_data = args.gui_data
  gui_data.elems.fpal_window_dimmer.location = gui_data.elems.fpal_window.location
end

function handlers.update_selected_index(args)
  local offset = args.offset
  local elems = args.gui_data.elems
  local state = args.gui_data.state
  local results_table = elems.results_table
  local selected_index = state.selected_index
  local row = tbl.get_row(results_table, selected_index)
  row[1].style.font_color = constants.colors.normal
  local new_selected_index = math.clamp(selected_index + offset, 1, tbl.count(results_table))
  state.selected_index = new_selected_index
  row = tbl.get_row(results_table, new_selected_index)
  row[1].style.font_color = constants.colors.hovered
  elems.results_scroll_pane.scroll_to_element(row[1], "top-third")
end

function handlers.enter_result_selection(args)
  local player, player_table = args.player, args.player_table
  local gui_data = player_table.guis.search
  local elems = gui_data.elems
  local state = gui_data.state
  if tbl.count(elems.results_table) == 0 then
    elems.search_textfield.focus()
    return
  end

  elems.results_scroll_pane.focus()
  if state.selected_index > tbl.count(elems.results_table) then
    state.selected_index = 1
  end
  tbl.get_row(elems.results_table, state.selected_index)[1].style.font_color = constants.colors.hovered
end

function handlers.update_search_query(args, e)
  local query = e.text

  -- Sanitize input
  for pattern, replacement in pairs(constants.input_sanitizers) do
    query = string.gsub(query, pattern, replacement)
  end

  args.gui_data.state.query = query
  args.gui_data.state.raw_query = e.text
  gui.perform_search(args.player, args.player_table, args.gui_data, true)
end

function handlers.toggle_search_gui(args)
  local player, player_table = args.player, args.player_table
  if not player_table.flags.can_open_gui then
    player_table.flags.show_message_after_translation = true
    player.print({ "message.fpal-cannot-open-gui" })
    return
  end
  gui.toggle(player, player_table, false)
end

function handlers.reopen_after_subwindow(args)
  local player, player_table = args.player, args.player_table
  local gui_data = args.gui_data
  if not gui_data then
    return
  end
  local elems = gui_data.elems
  local state = gui_data.state

  elems.search_textfield.enabled = true
  elems.fpal_window_dimmer.visible = false
  state.subwindow_open = false

  gui.perform_search(player, player_table, gui_data)

  if player_table.settings.auto_close and player_table.confirmed_tick == game.ticks_played then
    gui.close(player, player_table)
  else
    player.opened = gui_data.elems.fpal_window
  end

  storage.update_search_results[player.index] = true
end

-- Update source visibility when checkbox is clicked
function handlers.toggle_source(args, e)
  local player_table = args.player_table
  local source_name = e.element.tags.source_name
  player_table.enabled_sources[source_name] = e.element.state
  gui.perform_search(args.player, args.player_table, args.gui_data)
end

function handlers.toggle_fuzzy_search(args, e)
  local gui_data = args.gui_data
  gui_data.state.fuzzy_search = e.element.state
  gui.perform_search(args.player, args.player_table, gui_data)
end

---@param results_table LuaGuiElement
function gui.clear_results(results_table)
  results_table.clear()
end

---@param player LuaPlayer
---@param player_table table
---@param results table[]
function gui.update_results_table(player, player_table, results)
  local gui_data = player_table.guis.search
  local elems = gui_data.elems
  local results_table = elems.results_table
  local children = results_table.children

  local i = 0
  for _, row in ipairs(results) do
    i = i + 1

    local result = tbl.get_row(results_table, i)
    -- build row if nonexistent
    if not result then
      flib_gui.add(results_table, {
        {
          type = "label",
          style = "fpal_clickable_item_label",
          tags = { index = i },
          handler = {
            [defines.events.on_gui_click] = handlers.select_entry,
          },
        },
        { type = "label" },
        { type = "label" },
        { type = "label" },
      })
      -- update our copy of the table
      children = results_table.children
      result = tbl.get_row(results_table, i)
    end

    -- clear existing caption
    for j = 1, #result do
      result[j].caption = ""
    end

    local hidden_abbrev = row.hidden and "[font=default-semibold](H)[/font]  " or ""
    for j = 1, #row.caption do
      result[j].caption = hidden_abbrev .. row.caption[j]
      result[j].tooltip = row.tooltip
    end

    result[4].caption =
      { "", "[font=default-small-bold]", { "factory-palette.source." .. row.source .. ".name" }, "[/font]" }
    result[4].style.font_color = constants.colors.muted
  end
  -- destroy extraneous rows
  for j = tbl.count(results_table), i + 1, -1 do
    tbl.delete_row(results_table, j)
  end
end

---@param player LuaPlayer
---@param connected_to_network boolean
---@param logistic_requests_available boolean
---@return boolean
function gui.should_show_warning(player, connected_to_network, logistic_requests_available)
  return logistic_requests_available
    and player.controller_type == defines.controllers.character
    and not connected_to_network
end

---@param player LuaPlayer
---@param logistic_requests_available boolean
---@return boolean
function gui.should_adjust_margin(player, logistic_requests_available)
  return player.controller_type == defines.controllers.god
    or (player.controller_type == defines.controllers.character and not logistic_requests_available)
end

function gui.build(player, player_table)
  -- Clean up orphaned elements
  local orphaned_dimmer = player.gui.screen.fpal_window_dimmer
  if orphaned_dimmer and orphaned_dimmer.valid then
    orphaned_dimmer.destroy()
  end
  local orphaned_window = player.gui.screen.fpal_window
  if orphaned_window and orphaned_window.valid then
    orphaned_window.destroy()
  end
  gui.destroy(player_table)

  local elems = flib_gui.add(player.gui.screen, {
    -- Dimmer frame
    {
      name = "fpal_window_dimmer",
      type = "frame",
      style = "fpal_window_dimmer",
      style_mods = { size = { 578, 390 } },
      visible = false,
    },
    -- Main window
    {
      name = "fpal_window",
      type = "frame",
      style = "invisible_frame",
      direction = "horizontal",
      visible = false,
      elem_mods = { auto_center = true },
      handler = {
        [defines.events.on_gui_closed] = handlers.on_close,
        [defines.events.on_gui_location_changed] = handlers.relocate_dimmer,
      },
      {
        type = "frame",
        direction = "vertical",
        -- Titlebar
        {
          type = "flow",
          {
            name = "titlebar_flow",
            type = "flow",
            style = "fpal_titlebar_flow",
            drag_target = "fpal_window",
            handler = handlers.recenter,
            -- Search field
            {
              name = "search_textfield",
              type = "textfield",
              style = "fpal_disablable_textfield",
              style_mods = { width = 420 },
              clear_and_focus_on_right_click = true,
              lose_focus_on_confirm = true,
              handler = {
                [defines.events.on_gui_confirmed] = handlers.enter_result_selection,
                [defines.events.on_gui_text_changed] = handlers.update_search_query,
              },
            },
            {
              type = "sprite-button",
              style = "fpal_close_button",
              sprite = "utility/close",
              hovered_sprite = "utility/close",
              clicked_sprite = "utility/close",
              handler = handlers.on_close,
            },
            {
              name = "sidebar_button",
              type = "sprite-button",
              style = "fpal_close_button",
              sprite = "utility/mod_category",
              auto_toggle = true,
              handler = handlers.toggle_sidebar,
            },
          },
        },
        {
          type = "line",
          style = "fpal_titlebar_separator_line",
          ignored_by_interaction = true,
        },
        -- Main content frame
        {
          type = "flow",
          style_mods = { top_padding = -2, vertically_stretchable = true },
          direction = "vertical",
          drag_target = "fpal_window",
          -- Source filter label
          {
            name = "source_filter",
            type = "frame",
            style = "filter_frame",
            style_mods = {
              top_padding = -5,
              right_padding = 4,
              left_margin = -12,
              right_margin = -12,
              bottom_margin = 0,
              top_margin = -4,
              height = 20,
              horizontally_stretchable = true,
            },
            visible = false,
            {
              type = "label",
              caption = {
                "",
                "[font=default-small-semibold]",
                { "gui.fpal-filtered-sources" },
                "[/font]",
              },
            },
            {
              name = "source_filter_label",
              type = "label",
            },
          },
          -- Warning header
          {
            name = "warning_subheader",
            type = "frame",
            style = "negative_subheader_frame",
            style_mods = { left_padding = 12, height = 28, horizontally_stretchable = true },
            visible = false,
            {
              type = "label",
              style = "bold_label",
              caption = {
                "",
                "[img=utility/warning]  ",
                { "gui.fpal-not-connected-to-logistic-network" },
              },
            },
          },
          -- Results scroll pane
          {
            name = "results_scroll_pane",
            type = "scroll-pane",
            style = "fpal_list_box_scroll_pane",
            style_mods = { vertically_stretchable = true, bottom_padding = 2, maximal_height = 28 * 10 },
            visible = true,
            {
              name = "results_table",
              type = "table",
              style_mods = { top_margin = 4 },
              style = "fpal_list_box_table",
              column_count = tbl.columns,
            },
          },
        },
      },
      -- Source selection
      {
        name = "sidebar",
        type = "frame",
        visible = false,
        direction = "vertical",
        style_mods = { width = 160, padding = 4 },
        {
          type = "label",
          caption = { "", "[font=default-bold]", { "gui.fpal-configure" }, "[/font]" },
          style_mods = { bottom_margin = 4 },
        },
        {
          type = "checkbox",
          name = "fuzzy_search",
          caption = { "gui.fpal-fuzzy-search" },
          tooltip = { "gui.fpal-fuzzy-search-description" },
          state = false,
          handler = { [defines.events.on_gui_checked_state_changed] = handlers.toggle_fuzzy_search },
        },
        {
          type = "line",
          style_mods = { margin = 4 },
        },
        {
          type = "label",
          caption = { "", "[font=default-bold]", { "gui.fpal-sources" }, "[/font]" },
          style_mods = { bottom_margin = 4 },
        },
        {
          name = "sources_flow",
          type = "flow",
          direction = "vertical",
          style_mods = { vertical_spacing = 2 },
        },
      },
    },
  })

  player_table.guis.search = {
    elems = elems,
    state = {
      last_search_update = game.ticks_played,
      query = "",
      raw_query = "",
      selected_index = 1,
      subwindow_open = false,
      visible = false,
      fuzzy_search = false,
    },
  }
  -- Populate source checkboxes
  gui.populate_sources(player, player_table, player_table.guis.search)
end

-- Populate sources checkboxes
function gui.populate_sources(player, player_table, gui_data)
  local sources_flow = gui_data.elems.sources_flow
  sources_flow.clear()

  -- Get all available sources
  local sources = search.all_sources(player.index)

  -- Initialize enabled_sources if empty
  if not next(player_table.enabled_sources) then
    for name, _ in pairs(sources) do
      player_table.enabled_sources[name] = true
    end
  end

  -- Create checkbox for each source
  for name, _ in pairs(sources) do
    flib_gui.add(sources_flow, {
      {
        type = "checkbox",
        state = player_table.enabled_sources[name],
        caption = { "factory-palette.source." .. name .. ".name" },
        tags = { source_name = name },
        handler = { [defines.events.on_gui_checked_state_changed] = handlers.toggle_source },
      },
    })
  end
end

function gui.destroy(player_table)
  local gui_data = player_table.guis.search
  if not gui_data then
    return
  end
  if not gui_data.elems.fpal_window or not gui_data.elems.fpal_window.valid then
    return
  end
  gui_data.elems.fpal_window.destroy()
  player_table.guis.search = nil
end

function gui.open(player, player_table)
  gui.destroy(player_table)
  gui.build(player, player_table)
  local gui_data = player_table.guis.search
  gui_data.elems.fpal_window.visible = true
  gui_data.state.visible = true
  player.set_shortcut_toggled("fpal-search", true)
  player.opened = gui_data.elems.fpal_window

  gui_data.elems.search_textfield.focus()
  gui_data.elems.search_textfield.select_all()

  -- update the table right away
  gui.perform_search(player, player_table, gui_data)

  storage.update_search_results[player.index] = true
end

function gui.close(player, player_table, force_close)
  local gui_data = player_table.guis.search
  local elems = gui_data.elems
  local state = gui_data.state

  if not force_close and state.selected_item_tick == game.ticks_played then
    player.opened = elems.fpal_window
  elseif force_close or not state.subwindow_open then
    elems.fpal_window.visible = false
    state.visible = false
    player.set_shortcut_toggled("fpal-search", false)
    if player.opened == elems.fpal_window then
      player.opened = nil
    end
  end
  storage.update_search_results[player.index] = nil
end

function gui.toggle(player, player_table, force_open)
  local gui_data = player_table.guis.search
  if not gui_data then
    return
  end
  if gui_data.state.visible then
    gui.close(player, player_table)
  elseif force_open or player.opened_gui_type and player.opened_gui_type == defines.gui_type.none then
    gui.open(player, player_table)
  end
end

---@param player LuaPlayer
---@param player_table table
---@param updated_query? boolean
function gui.perform_search(player, player_table, gui_data, updated_query)
  local elems = gui_data.elems
  local state = gui_data.state

  state.last_search_update = game.ticks_played
  local query = string.lower(state.query)
  local results_table = elems.results_table

  local results_count = tbl.count(results_table)
  if updated_query and results_count > 0 then
    local row = tbl.get_row(results_table, state.selected_index)
    row[1].style.font_color = constants.colors.normal
    elems.results_scroll_pane.scroll_to_top()
    state.selected_index = 1
  end

  -- Early return if query is too short
  if #state.raw_query <= 1 then
    gui.clear_results(results_table)
    state.results = {}
    elems.results_scroll_pane.style.height = 0
    elems.source_filter.visible = false
    return
  end
  local results, filtered_sources = search.search(player, player_table, query, state.fuzzy_search)

  -- Update source filter label
  if filtered_sources then
    local source_names = {}
    for name in pairs(filtered_sources) do
      table.insert(source_names, { "factory-palette.source." .. name .. ".name" })
    end
    local function format_source_name(name)
      return { "", "[font=default-small-semibold][color=128, 126, 160]", name, "[/color][/font]" }
    end
    elems.source_filter_label.caption = format_source_name(source_names[1])
    for i = 2, #source_names do
      table.insert(elems.source_filter_label.caption, ", ")
      table.insert(elems.source_filter_label.caption, format_source_name(source_names[i]))
    end
    elems.source_filter.visible = true
  else
    elems.source_filter.visible = false
  end

  gui.update_results_table(player, player_table, results)

  local visible_rows = math.min(#results, constants.max_visible_rows)
  elems.results_scroll_pane.style.height = constants.row_height * visible_rows + 6
  elems.fpal_window_dimmer.style.height = constants.row_height * visible_rows + 6 + 64

  state.results = results
end

function gui.select_entry(player, player_table, modifiers, index)
  local gui_data = player_table.guis.search
  local elems = gui_data.elems
  local state = gui_data.state

  local i = index or state.selected_index
  local results = state.results
  if not results then
    return
  end

  local result = state.results[i]
  if not result then
    return
  end

  if type(result.remote) == "table" then
    if remote.call(result.remote[1], result.remote[2], result.remote[3], modifiers) then
      player.play_sound({ path = "utility/confirm" })
    else
      player.play_sound({ path = "utility/cannot_build" })
    end
  end
end

function gui.update_for_active_players()
  local tick = game.ticks_played
  for player_index in pairs(storage.update_search_results) do
    local player = game.get_player(player_index)
    local player_table = storage.players[player_index]
    local gui_data = player_table.guis.search
    if gui_data then
      local state = gui_data.state
      if tick - state.last_search_update > 120 then
        gui.perform_search(player, player_table, gui_data)
      end
    end
  end
end

gui.events = {
  ["fpal-nav-up"] = h():with_param("offset", -1):with_gui_check():chain(handlers.update_selected_index),
  ["fpal-nav-down"] = h():with_param("offset", 1):with_gui_check():chain(handlers.update_selected_index),
  ["fpal-search"] = h():chain(handlers.toggle_search_gui),
  ["fpal-control-confirm"] = h():with_param("control", true):with_gui_check():chain(handlers.select_entry),
  ["fpal-shift-confirm"] = h():with_param("shift", true):with_gui_check():chain(handlers.select_entry),
  ["fpal-control-shift-confirm"] = h()
    :with_param("control", true)
    :with_param("shift", true)
    :with_gui_check()
    :chain(handlers.select_entry),
  ["fpal-confirm"] = h():with_param("confirm", true):with_gui_check():chain(handlers.select_entry),
  [events.reopen_after_subwindow] = h():chain(handlers.reopen_after_subwindow),
  [defines.events.on_lua_shortcut] = h()
    :with_condition("prototype_name", "fpal-search")
    :chain(handlers.toggle_search_gui),
  [defines.events.on_tick] = h():chain(handlers.on_tick),
}

flib_gui.add_handlers(handlers, function(e, handler)
  h():chain(handler)(e)
end, "search")

return gui
