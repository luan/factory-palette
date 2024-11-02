local flib_gui = require("__flib__.gui")
local math = require("__flib__.math")

local constants = require("constants")
local infinity_filter = require("scripts.infinity-filter")

local infinity_filter_gui = {}
local handlers = {}

-- Handler functions
function handlers.on_close(player, player_table)
  infinity_filter_gui.close(player, player_table)
end

function handlers.recenter(player, player_table, e)
  if e.button == defines.mouse_button_type.middle then
    player_table.guis.infinity_filter.elems.window.force_auto_center()
  end
end

function handlers.change_filter_mode(player, player_table, e)
  local state = player_table.guis.infinity_filter.state
  local new_mode = constants.infinity_filter_modes_by_index[e.element.selected_index]
  state.infinity_filter.mode = new_mode
end

function handlers.update_filter(player, player_table, e, msg)
  local gui_data = player_table.guis.infinity_filter
  local elems = gui_data.elems
  local state = gui_data.state
  local item_data = state.item_data
  local filter_data = state.infinity_filter

  if msg.elem == "slider" then
    local count = e.element.slider_value
    filter_data.count = count
    elems.filter_setter.textfield.text = tostring(count)
  else
    local count = math.clamp(tonumber(e.element.text) or 0, 0, math.max_uint)
    filter_data.count = count
    elems.filter_setter.slider.slider_value = math.round(count, item_data.stack_size)
  end
end

function handlers.clear_filter(player, player_table)
  local state = player_table.guis.infinity_filter.state
  infinity_filter.clear(player, player_table, state.infinity_filter.name)
  -- invoke `on_gui_closed` so the search GUI will be refocused
  player.opened = nil
end
function handlers.set_filter(player, player_table, e, msg)
  -- HACK: Makes it easy for the search GUI to tell that this was confirmed
  player_table.confirmed_tick = game.ticks_played
  local state = player_table.guis.infinity_filter.state
  infinity_filter.set(player, player_table, state.infinity_filter, msg.temporary)
  -- invoke `on_gui_closed` so the search GUI will be refocused
  player.opened = nil
end

function infinity_filter_gui.build(player, player_table)
  -- Clean up orphaned elements
  local orphaned_window = player.gui.screen.fpal_infinity_filter_window
  if orphaned_window and orphaned_window.valid then
    orphaned_window.destroy()
  end
  infinity_filter_gui.destroy(player_table)

  local resolution = player.display_resolution
  local scale = player.display_scale
  local focus_frame_size = { resolution.width / scale, resolution.height / scale }

  local elems = flib_gui.add(player.gui.screen, {
    {
      type = "frame",
      style = "invisible_frame",
      style_mods = { size = focus_frame_size },
      visible = false,
      elem_mods = { auto_center = true },
      handler = {
        [defines.events.on_gui_click] = handlers.on_close,
      },
    },
    {
      type = "frame",
      name = "fpal_infinity_filter_window",
      direction = "vertical",
      visible = false,
      elem_mods = { auto_center = true },
      handler = {
        [defines.events.on_gui_closed] = handlers.on_close,
      },
      {
        type = "flow",
        style = "flib_titlebar_flow",
        drag_target = "fpal_infinity_filter_window",
        handler = {
          [defines.events.on_gui_click] = handlers.recenter,
        },
        {
          type = "label",
          style = "frame_title",
          caption = { "gui.fpal-edit-infinity-filter" },
          ignored_by_interaction = true,
        },
        {
          type = "empty-widget",
          style = "flib_titlebar_drag_handle",
          ignored_by_interaction = true,
        },
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "utility/close",
          hovered_sprite = "utility/close",
          clicked_sprite = "utility/close",
          handler = {
            [defines.events.on_gui_click] = handlers.on_close,
          },
        },
      },
      {
        type = "frame",
        style = "inside_shallow_frame",
        direction = "vertical",
        children = {
          {
            type = "frame",
            style = "subheader_frame",
            children = {
              { type = "label", style = "subheader_caption_label" },
              { type = "empty-widget", style = "flib_horizontal_pusher" },
            },
          },
          {
            type = "flow",
            style_mods = { vertical_align = "center", horizontal_spacing = 8, padding = 12 },
            children = {
              {
                type = "drop-down",
                style_mods = { width = 60 },
                items = { "≥", "≤", "=" },
                selected_index = 3,
                handler = {
                  [defines.events.on_gui_selection_state_changed] = handlers.change_filter_mode,
                },
              },
              {
                type = "slider",
                style = "notched_slider",
                style_mods = { horizontally_stretchable = true },
                minimum_value = 0,
                maximum_value = 500,
                value_step = 50,
                value = 500,
                discrete_slider = true,
                discrete_values = true,
                handler = {
                  [defines.events.on_gui_value_changed] = handlers.update_filter,
                },
              },
              {
                type = "textfield",
                style = "slider_value_textfield",
                numeric = true,
                handler = {
                  [defines.events.on_gui_text_changed] = handlers.update_filter,
                },
              },
              {
                type = "sprite-button",
                style = "item_and_count_select_confirm",
                sprite = "utility/check_mark",
                tooltip = { "", { "gui.fpal-set-infinity-filter" }, { "gui.fpal-confirm" } },
                handler = {
                  [defines.events.on_gui_click] = handlers.set_filter,
                },
              },
              {
                type = "sprite-button",
                style = "flib_tool_button_light_green",
                style_mods = { top_margin = 1 },
                sprite = "fpal_temporary_request",
                tooltip = { "", { "gui.fpal-set-temporary-infinity-filter" }, { "gui.fpal-shift-confirm" } },
                handler = {
                  [defines.events.on_gui_click] = handlers.set_filter,
                },
              },
              {
                type = "sprite-button",
                style = "tool_button_red",
                style_mods = { top_margin = 1 },
                sprite = "utility/trash",
                tooltip = { "", { "gui.fpal-clear-infinity-filter" }, { "gui.fpal-control-confirm" } },
                handler = {
                  [defines.events.on_gui_click] = handlers.clear_filter,
                },
              },
            },
          },
        },
      },
    },
  })

  player_table.guis.infinity_filter = {
    elems = elems,
    state = {
      item_data = nil,
      visible = false,
    },
  }
end

function infinity_filter_gui.destroy(player_table)
  local gui_data = player_table.guis.infinity_filter
  if gui_data then
    local window = gui_data.elems.window
    if window and window.valid then
      window.destroy()
    end
    player_table.guis.infinity_filter = nil
  end
end

function infinity_filter_gui.open(player, player_table, item_data)
  local gui_data = player_table.guis.infinity_filter
  local elems = gui_data.elems
  local state = gui_data.state

  -- update state
  local stack_size = prototypes.item[item_data.name].stack_size
  item_data.stack_size = stack_size
  state.item_data = item_data
  local infinity_filter_data = item_data.infinity_filter or { mode = "at-least", count = stack_size }
  infinity_filter_data.name = item_data.name
  state.infinity_filter = infinity_filter_data
  state.visible = true

  -- update item label
  elems.item_label.caption = "[item=" .. item_data.name .. "]  " .. item_data.translation

  -- update filter setter
  local filter_setter = elems.filter_setter
  filter_setter.dropdown.selected_index = constants.infinity_filter_mode_to_index[infinity_filter_data.mode]
  filter_setter.slider.set_slider_value_step(1)
  filter_setter.slider.set_slider_minimum_maximum(0, stack_size * 10)
  filter_setter.slider.set_slider_value_step(stack_size)
  filter_setter.slider.slider_value = math.round(infinity_filter_data.count, stack_size)
  filter_setter.textfield.text = tostring(infinity_filter_data.count)
  filter_setter.textfield.select_all()
  filter_setter.textfield.focus()

  -- update window
  elems.focus_frame.visible = true
  elems.focus_frame.bring_to_front()
  elems.window.visible = true
  elems.window.bring_to_front()

  -- set opened
  player.opened = elems.window
end

function infinity_filter_gui.close(player, player_table)
  local gui_data = player_table.guis.infinity_filter
  gui_data.state.visible = false
  gui_data.elems.focus_frame.visible = false
  gui_data.elems.window.visible = false
  if not player.opened then
    player.opened = player_table.guis.search.elems.window
  end
end

function infinity_filter_gui.set_filter(player, player_table, is_temporary)
  player.play_sound({ path = "utility/confirm" })
  infinity_filter.set(player, player_table, player_table.guis.infinity_filter.state.infinity_filter, is_temporary)
  if is_temporary then
    player.opened = nil
  end
end

function infinity_filter_gui.clear_filter(player, player_table)
  player.play_sound({ path = "utility/confirm" })
  infinity_filter.clear(player, player_table, player_table.guis.infinity_filter.state.infinity_filter.name)
  player.opened = nil
end

function infinity_filter_gui.cycle_filter_mode(gui_data)
  local elems = gui_data.elems
  local state = gui_data.state

  state.infinity_filter.mode = (
    next(constants.infinity_filter_modes, state.infinity_filter.mode) or next(constants.infinity_filter_modes)
  )

  elems.filter_setter.dropdown.selected_index = constants.infinity_filter_mode_to_index[state.infinity_filter.mode]
end

function infinity_filter_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = storage.players[e.player_index]
  local gui_data = player_table.guis.infinity_filter
  local elems = gui_data.elems
  local state = gui_data.state

  local item_data = state.item_data
  local filter_data = state.infinity_filter

  if msg.action == "close" then
    infinity_filter_gui.close(player, player_table)
  elseif msg.action == "change_filter_mode" then
    local new_mode = constants.infinity_filter_modes_by_index[e.element.selected_index]
    state.infinity_filter.mode = new_mode
  elseif msg.action == "update_filter" then
    if msg.elem == "slider" then
      local count = e.element.slider_value
      filter_data.count = count
      elems.filter_setter.textfield.text = tostring(count)
    else
      local count = math.clamp(tonumber(e.element.text) or 0, 0, math.max_uint)
      filter_data.count = count
      elems.filter_setter.slider.slider_value = math.round(count, item_data.stack_size)
    end
  elseif msg.action == "clear_filter" then
    infinity_filter.clear(player, player_table, filter_data.name)
    -- invoke `on_gui_closed` so the search GUI will be refocused
    player.opened = nil
  elseif msg.action == "set_filter" then
    -- HACK: Makes it easy for the search GUI to tell that this was confirmed
    player_table.confirmed_tick = game.ticks_played
    infinity_filter.set(player, player_table, filter_data, msg.temporary)
    -- invoke `on_gui_closed` so the search GUI will be refocused
    player.opened = nil
  end
end

-- Add handlers to flib_gui with a prefix
flib_gui.add_handlers(handlers, function(e, handler)
  local player = game.get_player(e.player_index)
  local player_table = storage.players[e.player_index]
  if player and player_table then
    handler(player, player_table, e)
  end
end, "infinity_filter")
return infinity_filter_gui
