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

- `Alt + P` (default): Open Factory Palette
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

### Writing a Source

A source is a Lua module that registers itself using `search.add_source()`. Here's how to create one:

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
