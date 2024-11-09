---@type HandlerArgs
---@field player LuaPlayer?
---@field player_table PlayerTable?

---@class Handler
---@field _fn fun(args: table, e: EventData)
local Handler = {}
local _break = nil

function Handler.new()
  local self = {}
  self._chain = {}
  self._applied = {}
  return setmetatable(self, {
    __index = Handler,
    __call = function(self, e)
      local args = {}
      for _, fn in ipairs(self._chain) do
        self:_ensure_applied(fn.deps)
        args = fn.fn(args, e)
        if args == _break then
          return
        end
        self._applied[fn.name] = true
      end
    end,
  })
end

---@param name_or_fn string|function
---@param fn function?
---@param deps string[]?
function Handler:chain(name_or_fn, fn, deps)
  if type(name_or_fn) == "function" then
    fn = name_or_fn
    name_or_fn = "__anonymous__"
  end
  table.insert(self._chain, { name = name_or_fn, fn = fn, deps = deps })
  return self
end

function Handler.for_player()
  return function()
    local handler = Handler.new()
    return handler:with_player()
  end
end

function Handler.for_gui(gui_name)
  return function()
    local handler = Handler.new()
    handler.gui_name = gui_name
    return handler:with_player():with_gui_data()
  end
end

function Handler:_ensure_applied(keys)
  if not keys then
    return
  end
  for _, key in ipairs(keys) do
    if not self._applied[key] then
      error(string.format("Handler %s not applied", key))
    end
  end
end

function Handler:with_gui_data()
  self:chain("with_gui_data", function(args, e)
    local gui_data = args.player_table.guis[self.gui_name]
    args.gui_data = gui_data
    return args
  end, { "with_player" })
  return self
end

function Handler:with_player()
  self:chain("with_player", function(args, e)
    if not game then
      return _break
    end
    if not e.player_index then
      return _break
    end
    local player = game.get_player(e.player_index)
    if not player then
      return _break
    end
    local player_table = storage.players[e.player_index]
    if player_table then
      args.player = player
      args.player_table = player_table
      return args
    end
    return _break
  end)
  return self
end

function Handler:with_gui_check()
  self:chain("with_gui_check", function(args, e)
    if not args.player_table.flags.can_open_gui then
      return _break
    end

    if args.gui_data.state.visible and not args.gui_data.state.subwindow_open then
      return args
    end
    return _break
  end, { "with_player" })
  return self
end

function Handler:with_condition(field, value)
  self:chain("with_condition", function(args, e)
    if e[field] ~= value then
      return _break
    end
    return args
  end)
  return self
end

function Handler:with_param(field, value)
  self:chain("with_param", function(args, e)
    args[field] = value
    return args
  end)
  return self
end

local handlers = {
  fn = Handler.new,
  for_gui = Handler.for_gui,
  for_player = Handler.for_player,
}

return handlers
