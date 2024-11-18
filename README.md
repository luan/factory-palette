# Factory Palette

Factory Palette is your shortcut to everything in Factorio. Think of it as a command palette that lets you quickly search and access just about anything in the game - from items and recipes to entities, technologies, keybinds, commands, and more.

## Features

- **Quick Universal Search**: Instantly find items, recipes, entities, technologies, and more
- **Technology Management**:
  - View technology research status with color coding
  - Add/remove technologies from research queue
  - Quick access to technology details
- **Keyboard Navigation**: Full keyboard support for quick navigation
- **Logistic System Integration**: Manage logistic requests directly through the palette
- **Customizable Settings**:
  - Auto-close window after actions
  - Fuzzy search for more forgiving search queries
  - Toggle visibility of hidden items
  - Optional automatic item spawning in cheat/editor mode

## Controls

- `Ctrl/⌘ + K` (default): Open Factory Palette
- `↑/↓`: Navigate through results
- `Enter`: Confirm selection
- `Shift + Enter`: Alternative action
- `Ctrl + Enter`: Secondary alternative action

## Settings

- **Auto-close Window**: Automatically closes the palette after completing an action
- **Fuzzy Search**: Enables more lenient matching for search queries
- **Show Hidden Items**: Include normally hidden items in search results
- **Spawn Items When Cheating**: Automatically spawns items into cursor when in map editor/cheat mode

## Technology View

Technologies are color-coded for easy reference:

- 🟢 Green: Researched technologies
- ⚪ White: Available but not researched
- ⚫ Gray: Not yet available (prerequisites not met)

## Extending Factory Palette

Factory Palette uses a "sources" system that allows other mods to add new searchable content types. Each source provides search functionality, result formatting, and handling of user interactions.

### Available extensions

- [factory-palette-calculator](https://github.com/luan/factory-palette-calculator): [mod portal](https://mods.factorio.com/mod/factory-palette-calculator)

### Writing a Source

A source is a Lua module that provides searchable content to Factory Palette. Here's a step-by-step guide to creating one:

1. **Create a New Mod**
   Create a new mod following Factorio's mod structure with appropriate dependencies on factory-palette.

2. **Create the Source Module**
   Create a `control.lua` file that implements these key components:

   ```lua
   -- Search function that processes queries and returns results
  local function search(args)
    local player, player_table, query, fuzzy = args.player, args.player_table, args.query, args.fuzzy
     -- Process the query and generate results
     -- Return empty table if no matches
     if not matches_query(query) then
       return {}
     end

     -- Return array of results in this format:
     return {
       {
         name = "your_source_name",
         caption = { "[color=white]Result Caption[/color]" },
         translation = "Plain text version",
         result = "data for handlers",
         remote = {
           "factory-palette.source.your_source_name",
           "select",
           { player_index = player.index, result = "result_data" },
         },
         tooltip = tooltip(),
       },
     }
   end

   -- Action handler for when user selects a result
   local function select(data, modifiers)
     local player = game.players[data.player_index]
     if not player then
       return
     end

     -- Handle the selection (e.g., print result, modify game state)
     player.print({ "", { "your-mod.result-translation" }, data.result })
     return true
   end

   -- Register the source with Factory Palette
   remote.add_interface("factory-palette.source.your_source_name", {
     search = search,
     select = select,
   })
   ```

3. **Best Practices**
   - Validate and sanitize input queries
   - Return empty results array when no matches are found
   - Use clear, descriptive names for your source
   - Implement proper error handling
   - Follow Factorio's localization practices for tooltips and captions
   - Test with various input scenarios

For a complete example, check out the [factory-palette-calculator](https://github.com/luan/factory-palette-calculator) source code.

## Dependencies

- Requires [flib](https://mods.factorio.com/mod/flib)

## Contributing

Feel free to report issues or suggest features on the [mod portal](https://mods.factorio.com/mod/factory-palette).

## Acknowledgments

- Thanks to [raiguard](https://github.com/raiguard) for:
  - Creating [flib](https://mods.factorio.com/mod/flib), which this mod depends on
  - The [QuickItemSearch](https://mods.factorio.com/mod/QuickItemSearch) mod which served as inspiration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
