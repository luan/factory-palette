local inventory = {}

function inventory.get_combined_contents(player, main_inventory)
  -- main inventory contents
  local combined_contents = {}
  if main_inventory then
    for _, item in ipairs(main_inventory.get_contents()) do
      combined_contents[item.name] = (combined_contents[item.name] or 0) + item.count
    end
  end
  -- cursor stack
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read then
    combined_contents[cursor_stack.name] = (combined_contents[cursor_stack.name] or 0) + cursor_stack.count
  end
  -- other
  for _, inventory_def in ipairs({
    -- for some reason, the character_ammo and character_guns inventories work in the editor as well
    defines.inventory.character_ammo,
    defines.inventory.character_guns,
    -- defines.inventory.character_trash
  }) do
    local inventory = player.get_inventory(inventory_def)
    if inventory and inventory.valid then
      for _, item in ipairs(inventory.get_contents() or {}) do
        combined_contents[item.name] = (combined_contents[item.name] or 0) + item.count
      end
    end
  end

  return combined_contents, true
end

return inventory
