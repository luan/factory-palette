local flib_gui = require("__flib__.gui")
local math = require("__flib__.math")

local constants = require("constants")
local events = require("events")
local h = require("handlers").for_gui("request")

local logistic_request = require("scripts.sources.logistic-request")

local logistic_request_gui = {}
local handlers = {}

-- Handler functions
function handlers.on_close(args, e)
  script.raise_event(events.reopen_after_subwindow, e)
  logistic_request_gui.close(args.player, args.player_table)
end

function handlers.recenter(args, e)
  if e.button == defines.mouse_button_type.middle then
    args.gui_data.elems.window.force_auto_center()
  end
end

function handlers.update_request(args, e)
  local gui_data = args.gui_data
  local elems = gui_data.elems
  local state = gui_data.state
  local item_data = state.item_data
  local request_data = state.request

  local bound = e.element.tags.bound

  local count
  if e.element.type == "textfield" then
    count = tonumber(e.element.text)
    if count then
      count = math.clamp(count, 0, math.max_uint)
    else
      count = bound == "min" and 0 or math.max_uint
    end
    elems[bound .. "_slider"].slider_value = math.round(count / item_data.stack_size) * item_data.stack_size
  else
    count = e.element.slider_value
    local text
    if bound == "max" and count == item_data.stack_size * 10 then
      count = math.max_uint
      text = constants.infinity_rep
    else
      text = tostring(count)
    end
    elems[bound .. "_textfield"].text = text
  end
  request_data[bound] = count
  request_data.max = request_data.max or math.max_uint

  -- sync border
  if bound == "min" and count > request_data.max then
    request_data.max = count
    elems.max_textfield.text = tostring(count)
    elems.max_slider.slider_value = math.round(count / item_data.stack_size) * item_data.stack_size
  elseif bound == "max" and count < request_data.min then
    request_data.min = count
    elems.min_textfield.text = tostring(count)
    elems.min_slider.slider_value = math.round(count / item_data.stack_size) * item_data.stack_size
  end

  -- switch textfield
  if e.element.type == "textfield" then
    if bound == "min" then
      elems.max_textfield.select_all()
      elems.max_textfield.focus()
    else
      elems.min_textfield.select_all()
      elems.min_textfield.focus()
    end
  end
end

function handlers.clear_request(args, e)
  logistic_request.clear(args.player, args.gui_data.state.item_data.name)
  -- invoke `on_gui_closed` so the search GUI will be refocused
  args.player.opened = nil
end

function handlers.set_request(args, e)
  if not e.element or not e.element.tags then
    return
  end
  -- HACK: Makes it easy for the search GUI to tell that this was confirmed
  args.player_table.confirmed_tick = game.ticks_played
  local temporary = e.element.tags.temporary
  logistic_request_gui.set_request(args.player, args.player_table, temporary, true)
  -- invoke `on_gui_closed` if the above function did not
  if not temporary then
    args.player.opened = nil
  end
end

function logistic_request_gui.build(player, player_table)
  local orphaned_window = player.gui.screen.fpal_request_window
  if orphaned_window and orphaned_window.valid then
    orphaned_window.destroy()
  end
  local orphaned_frame = player.gui.screen.fpal_request_focus_frame
  if orphaned_frame and orphaned_frame.valid then
    orphaned_frame.destroy()
  end
  logistic_request_gui.destroy(player_table)
  local resolution = player.display_resolution
  local scale = player.display_scale
  local fpal_request_focus_frame_size = { resolution.width / scale, resolution.height / scale }

  local elems = flib_gui.add(player.gui.screen, {
    {
      type = "frame",
      style = "invisible_frame",
      name = "fpal_request_focus_frame",
      style_mods = { size = fpal_request_focus_frame_size },
      visible = false,
      elem_mods = { auto_center = true },
      handler = {
        [defines.events.on_gui_click] = handlers.on_close,
      },
    },
    {
      type = "frame",
      name = "fpal_request_window",
      direction = "vertical",
      visible = false,
      elem_mods = { auto_center = true },
      handler = {
        [defines.events.on_gui_closed] = handlers.on_close,
      },
      {
        type = "flow",
        style = "flib_titlebar_flow",
        drag_target = "fpal_request_window",
        handler = {
          [defines.events.on_gui_click] = handlers.recenter,
        },
        {
          type = "label",
          style = "frame_title",
          name = "item_label",
          caption = { "gui.fpal-edit-logistic-request" },
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
        {
          type = "frame",
          style = "subheader_frame",
          {
            type = "label",
            style = "subheader_caption_label",
          },
          {
            type = "empty-widget",
            style = "flib_horizontal_pusher",
          },
        },
        {
          type = "flow",
          style_mods = { vertical_align = "center", horizontal_spacing = 8, padding = 12 },
          {
            type = "textfield",
            style = "slider_value_textfield",
            numeric = true,
            clear_and_focus_on_right_click = true,
            text = "0",
            tags = { bound = "min" },
            name = "min_textfield",
            handler = {
              [defines.events.on_gui_confirmed] = handlers.update_request,
            },
          },
          {
            type = "flow",
            direction = "vertical",
            {
              type = "slider",
              style = "notched_slider",
              style_mods = { horizontally_stretchable = true },
              minimum_value = 0,
              maximum_value = 500,
              value_step = 50,
              value = 0,
              discrete_slider = true,
              discrete_values = true,
              tags = { bound = "max" },
              name = "max_slider",
              handler = {
                [defines.events.on_gui_value_changed] = handlers.update_request,
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
              tags = { bound = "min" },
              name = "min_slider",
              handler = {
                [defines.events.on_gui_value_changed] = handlers.update_request,
              },
            },
          },
          {
            type = "textfield",
            style = "slider_value_textfield",
            numeric = true,
            clear_and_focus_on_right_click = true,
            text = constants.infinity_rep,
            tags = { bound = "max" },
            name = "max_textfield",
            handler = {
              [defines.events.on_gui_confirmed] = handlers.update_request,
            },
          },
          {
            type = "sprite-button",
            style = "item_and_count_select_confirm",
            sprite = "utility/check_mark",
            tooltip = { "", { "gui.fpal-set-request" }, { "gui.fpal-confirm" } },
            tags = { temporary = false },
            handler = {
              [defines.events.on_gui_click] = handlers.set_request,
            },
          },
          {
            type = "sprite-button",
            style = "flib_tool_button_light_green",
            style_mods = { top_margin = 1 },
            sprite = "fpal_temporary_request",
            tooltip = { "", { "gui.fpal-set-temporary-request" }, { "gui.fpal-shift-confirm" } },
            tags = { temporary = true },
            handler = {
              [defines.events.on_gui_click] = handlers.set_request,
            },
          },
          {
            type = "sprite-button",
            style = "tool_button_red",
            style_mods = { top_margin = 1 },
            sprite = "utility/trash",
            tooltip = { "", { "gui.fpal-clear-request" }, { "gui.fpal-control-confirm" } },
            handler = {
              [defines.events.on_gui_click] = handlers.clear_request,
            },
          },
        },
      },
    },
  })

  player_table.guis.request = {
    elems = elems,
    state = {
      item_data = nil,
      visible = false,
    },
  }
end

-- Rest of the functions remain the same, just remove handle_action since we're using handlers now
function logistic_request_gui.destroy(player_table)
  local gui_data = player_table.guis.request
  if not gui_data then
    return
  end

  local window = gui_data.elems.fpal_request_window
  if window and window.valid then
    window.destroy()
  end
  local focus_frame = gui_data.elems.fpal_request_focus_frame
  if focus_frame and focus_frame.valid then
    focus_frame.destroy()
  end
  player_table.guis.request = nil
end

function logistic_request_gui.open(player, player_table, item_data)
  local gui_data = player_table.guis.request
  local elems = gui_data.elems
  local state = gui_data.state

  -- update state
  local stack_size = prototypes.item[item_data.name].stack_size
  item_data.stack_size = stack_size
  state.item_data = item_data
  local request_data = item_data.request or { min = 0, max = math.max_uint }
  state.request = request_data
  state.visible = true

  -- update item label
  elems.item_label.caption = "[item=" .. item_data.name .. "]  " .. item_data.translation

  -- update logistic setter
  for _, type in ipairs({ "min", "max" }) do
    local count = request_data[type] or 0
    local textfield = elems[type .. "_textfield"]
    textfield.enabled = true
    if count >= math.max_uint then
      textfield.text = constants.infinity_rep
    else
      textfield.text = tostring(count)
    end
    local slider = elems[type .. "_slider"]
    slider.enabled = true
    slider.set_slider_value_step(1)
    slider.set_slider_minimum_maximum(0, stack_size * 10)
    slider.set_slider_value_step(stack_size)
    slider.slider_value = math.round(count / stack_size) * stack_size
  end
  elems.min_textfield.select_all()
  elems.min_textfield.focus()

  -- update window
  elems.fpal_request_focus_frame.visible = true
  elems.fpal_request_focus_frame.bring_to_front()
  elems.fpal_request_window.visible = true
  elems.fpal_request_window.bring_to_front()

  -- set opened
  player.opened = elems.fpal_request_window
end

function logistic_request_gui.close(player, player_table)
  local gui_data = player_table.guis.request
  gui_data.state.visible = false
  gui_data.elems.fpal_request_focus_frame.visible = false
  gui_data.elems.fpal_request_window.visible = false
  if not player.opened then
    player.opened = player_table.guis.search.elems.window
  end
end

function logistic_request_gui.update_focus_frame_size(player, player_table)
  local gui_data = player_table.guis.request
  if gui_data then
    local resolution = player.display_resolution
    local scale = player.display_scale
    local size = { resolution.width / scale, resolution.height / scale }
    gui_data.elems.fpal_request_focus_frame.style.size = size
  end
end

function logistic_request_gui.set_request(player, player_table, is_temporary, skip_sound)
  if not skip_sound then
    player.play_sound({ path = "utility/confirm" })
  end

  local gui_data = player_table.guis.request
  local elems = gui_data.elems
  local state = gui_data.state

  -- set the request
  logistic_request.set(player, player_table, state.item_data.name, state.request, is_temporary)

  -- close this window
  if is_temporary then
    player.opened = nil
  end
end

-- Add handlers to flib_gui with a prefix
flib_gui.add_handlers(handlers, function(e, handler)
  local player = game.get_player(e.player_index)
  local player_table = storage.players[e.player_index]
  if player and player_table then
    h():chain(handler)(e)
  end
end, "logistic_request")

return logistic_request_gui
