# Real-Time File Manifest

This project includes a script (`file_manifest.py`) that scans the `src/` directory and generates a `fileIndex.luau` manifest listing all `.luau` files. This helps keep track of all modules and scripts in real time.

## How to Use

1. Run the script whenever you add, remove, or rename `.luau` files:

   ```sh
   python3 file_manifest.py
   ```

2. The script will generate or update `fileIndex.luau` in the project root, listing all `.luau` files under `src/`.

3. You can require or reference this manifest in your code as needed.

---

For automated real-time updates, consider using a file watcher (e.g., `watchmedo` from `watchdog` in Python) to run the script on file changes.

Example (optional):

```sh
pip install watchdog
watchmedo shell-command --patterns="*.luau" --recursive --command='python3 file_manifest.py' src/
```

This will update the manifest automatically whenever `.luau` files change.
