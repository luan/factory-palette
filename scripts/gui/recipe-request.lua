local flib_gui = require("__flib__.gui")
local flib_math = require("__flib__.math")

local events = require("events")
local h = require("handlers").for_gui("recipe_request")
local logistic_request = require("scripts.sources.logistic-request")

local recipe_request = {}
local handlers = {}

-- This action uses the recipe named for the item; other recipes need a picker.
function recipe_request.prepare(recipe, item_name)
  if not recipe then
    return nil, nil, "message.fpal-recipe-unavailable"
  end

  local output_amount = 0
  for _, product in ipairs(recipe.products) do
    if product.type == "item" and product.name == item_name then
      if not product.amount or (product.probability or 1) ~= 1 then
        return nil, nil, "message.fpal-recipe-unavailable"
      end
      output_amount = output_amount + product.amount
    end
  end
  if output_amount == 0 then
    return nil, nil, "message.fpal-recipe-unavailable"
  end

  local ingredients = {}
  for _, ingredient in ipairs(recipe.ingredients) do
    if ingredient.type ~= "item" then
      return nil, nil, "message.fpal-recipe-has-fluids"
    end
    ingredients[ingredient.name] = (ingredients[ingredient.name] or 0) + ingredient.amount
  end
  if not next(ingredients) then
    return nil, nil, "message.fpal-recipe-unavailable"
  end
  return ingredients, output_amount
end

function recipe_request.destroy(player_table)
  local gui_data = player_table.guis.recipe_request
  if not gui_data then
    return
  end
  player_table.guis.recipe_request = nil
  if gui_data.elems.fpal_recipe_request_window.valid then
    gui_data.elems.fpal_recipe_request_window.destroy()
  end
end

function recipe_request.close(player, player_table)
  local gui_data = player_table.guis.recipe_request
  if not gui_data or not gui_data.state.visible then
    return
  end
  gui_data.state.visible = false
  recipe_request.destroy(player_table)
  script.raise_event(events.reopen_after_subwindow, { player_index = player.index })
end

function handlers.close(args)
  recipe_request.close(args.player, args.player_table)
end

function recipe_request.confirm(player, player_table)
  local gui_data = player_table.guis.recipe_request
  if player.controller_type ~= defines.controllers.character or not player.force.character_logistic_requests then
    player.print({ "message.fpal-character-logistics-unavailable" })
    recipe_request.close(player, player_table)
    return
  end
  local count = tonumber(gui_data.elems.count.text)
  if not count or count < 1 or count > flib_math.max_uint or count ~= math.floor(count) then
    player.print({ "message.fpal-invalid-recipe-count" })
    return
  end

  local state = gui_data.state
  local crafts = math.ceil(count / state.output_amount)
  local requests = {}
  for name, amount in pairs(state.ingredients) do
    local needed = math.ceil(crafts * amount)
    if needed > flib_math.max_uint then
      player.print({ "message.fpal-invalid-recipe-count" })
      return
    end
    requests[name] = needed
  end

  for name, needed in pairs(requests) do
    logistic_request.set(player, player_table, name, { min = needed, max = flib_math.max_uint }, true)
  end
  player_table.confirmed_tick = game.ticks_played
  recipe_request.close(player, player_table)
end

function handlers.confirm(args)
  recipe_request.confirm(args.player, args.player_table)
end

function recipe_request.open(player, player_table, result, ingredients, output_amount)
  recipe_request.destroy(player_table)
  local orphaned_window = player.gui.screen.fpal_recipe_request_window
  if orphaned_window and orphaned_window.valid then
    orphaned_window.destroy()
  end
  local elems = flib_gui.add(player.gui.screen, {
    type = "frame",
    name = "fpal_recipe_request_window",
    direction = "vertical",
    elem_mods = { auto_center = true },
    handler = { [defines.events.on_gui_closed] = handlers.close },
    {
      type = "flow",
      style = "flib_titlebar_flow",
      drag_target = "fpal_recipe_request_window",
      {
        type = "label",
        style = "frame_title",
        caption = { "gui.fpal-recipe-request-title" },
        ignored_by_interaction = true,
      },
      { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
      {
        type = "sprite-button",
        style = "frame_action_button",
        sprite = "utility/close",
        handler = { [defines.events.on_gui_click] = handlers.close },
      },
    },
    {
      type = "flow",
      direction = "horizontal",
      style_mods = { vertical_align = "center", horizontal_spacing = 8, padding = 12 },
      {
        type = "label",
        caption = {
          "",
          "[item=" .. result.name .. "] ",
          result.translation,
          ": ",
          { "gui.fpal-recipe-request-count" },
        },
      },
      {
        type = "textfield",
        name = "count",
        text = "1",
        numeric = true,
        handler = { [defines.events.on_gui_confirmed] = handlers.confirm },
      },
      {
        type = "button",
        style = "confirm_button",
        caption = { "gui.fpal-recipe-request-confirm" },
        handler = { [defines.events.on_gui_click] = handlers.confirm },
      },
    },
  })
  player_table.guis.recipe_request = {
    elems = elems,
    state = { visible = true, ingredients = ingredients, output_amount = output_amount },
  }
  player.opened = elems.fpal_recipe_request_window
  elems.count.select_all()
  elems.count.focus()
end

flib_gui.add_handlers(handlers, function(e, handler)
  h():chain(handler)(e)
end, "recipe_request")

return recipe_request
