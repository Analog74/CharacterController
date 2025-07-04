# CharacterControl

This project is a Roblox character control system, designed to provide advanced movement, ragdoll, camera, and utility modules for Roblox games.

## Project Structure

- `src/ReplicatedStorage/CustomMovement/` — Custom movement logic and utilities
- `src/ReplicatedStorage/Modules/` — Shared modules (camera, fast cast, lightning, mouse, part cache, zone, etc.)
- `src/ServerScriptService/` — Server-side scripts for look-at, particles, physics, and ragdoll systems
- `src/StarterPlayer/StarterCharacterScripts/` — Client-side character scripts
- `src/Workspace/` — In-game assets and scripts

## Getting Started

1. Place the contents of this repository into your Roblox project directory.
2. Use `index.luau` as the main entry point for initialization or requiring modules.
3. Customize or extend modules as needed for your game.

## Example Usage

In `index.luau`, you can require modules like this:

```lua
return {
    require(script.ReplicatedStorage.CustomMovement.HumanoidControl),
    -- Add other modules as needed
}
```

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes.

## License

Specify your license here.
