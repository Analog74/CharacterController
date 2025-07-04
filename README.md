# CharacterControl

This project is a Roblox character control system, designed to provide advanced movement, ragdoll, camera, and utility modules for Roblox games.

## Project Structure

- `src/ReplicatedStorage/CustomMovement/` — Custom movement logic and utilities
- `src/ReplicatedStorage/Modules/` — Shared modules (camera, fast cast, lightning, mouse, part cache, zone, etc.)
- `src/ServerScriptService/` — Server-side scripts for look-at, particles, physics, and ragdoll systems
- `src/StarterPlayer/StarterCharacterScripts/` — Client-side character scripts
- `src/Workspace/` — In-game assets and scripts

## Real-Time File Manifest

This project includes a script (`file_manifest.py`) that scans the `src/` directory and generates a `fileIndex.luau` manifest listing all `.luau` files. This helps keep track of all modules and scripts in real time.

### How to Use the Manifest

1. Run the script whenever you add, remove, or rename `.luau` files:

   ```sh
   python3 file_manifest.py
   ```

2. The script will generate or update `fileIndex.luau` in the project root, listing all `.luau` files under `src/`.

3. You can require or reference this manifest in your code as needed.

#### Optional: Automated Updates

For automated real-time updates, consider using a file watcher (e.g., `watchmedo` from `watchdog` in Python) to run the script on file changes:

```sh
pip install watchdog
watchmedo shell-command --patterns="*.luau" --recursive --command='python3 file_manifest.py' src/
```

---

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
